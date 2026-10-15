# Rewrites a Tauri app's embedded frontend JS in place. Tauri stores each asset
# brotli-compressed, referenced from a static (path, bytes) table whose pointers
# live in .rela.dyn addends and whose lengths sit in the table itself.
# Usage: patch-assets.py BINARY PATTERN REPLACEMENT (Python regex, applied per asset)
import re
import struct
import sys

import brotli

binary, pattern, replacement = sys.argv[1], re.compile(sys.argv[2]), sys.argv[3]
data = bytearray(open(binary, "rb").read())

shoff, = struct.unpack_from("<Q", data, 0x28)
shentsize, shnum, shstrndx = struct.unpack_from("<HHH", data, 0x3A)
sections = [struct.unpack_from("<IIQQQQ", data, shoff + i * shentsize) for i in range(shnum)]
strtab = sections[shstrndx][4]
mapped = [s for s in sections if s[1] != 8 and s[3]]  # skip NOBITS and unmapped


def name(section):
    start = strtab + section[0]
    return data[start : data.index(0, start)].decode()


def to_offset(vaddr):
    return next(vaddr - s[3] + s[4] for s in mapped if s[3] <= vaddr < s[3] + s[5])


def to_vaddr(offset):
    return next(offset - s[4] + s[3] for s in mapped if s[4] <= offset < s[4] + s[5])


rela = next(s for s in sections if name(s) == ".rela.dyn")
target_of = {}  # pointer slot vaddr -> pointed-to vaddr
slot_of = {}  # pointed-to vaddr -> pointer slot vaddr
for at in range(rela[4], rela[4] + rela[5], 24):
    r_offset, _, r_addend = struct.unpack_from("<QQq", data, at)
    target_of[r_offset] = r_addend
    slot_of[r_addend] = r_offset

patched = 0
for key in re.finditer(rb"/assets/[\w.-]+\.js", data):
    key_slot = slot_of.get(to_vaddr(key.start()))
    if key_slot is None or struct.unpack_from("<Q", data, to_offset(key_slot) + 8)[0] != len(key[0]):
        continue
    value_slot = to_offset(key_slot + 16)
    blob_at = to_offset(target_of[key_slot + 16])
    blob_len, = struct.unpack_from("<Q", data, value_slot + 8)
    js = brotli.decompress(bytes(data[blob_at : blob_at + blob_len])).decode()
    new_js, count = pattern.subn(replacement, js)
    if not count:
        continue
    blob = brotli.compress(new_js.encode(), quality=11, lgwin=24)
    if len(blob) > blob_len:
        sys.exit(f"{key[0].decode()}: patched asset is {len(blob)} bytes, slot holds {blob_len}")
    data[blob_at : blob_at + len(blob)] = blob
    struct.pack_into("<Q", data, value_slot + 8, len(blob))
    print(f"patched {count}x in {key[0].decode()}")
    patched += count

if not patched:
    sys.exit("pattern not found in any embedded asset")
open(binary, "wb").write(data)
