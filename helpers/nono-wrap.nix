# Shadow the real binary with a nono launcher so every entry point (shell,
# desktop entry, scripts) is sandboxed. Profiles live in ~/.config/nono/profiles
{ pkgs, nono }:
{
  pkg,
  name,
  profile,
  nonoArgs ? [ ],
  tmpDir ? "/tmp/claude-$(id -u)",
}:
pkgs.symlinkJoin {
  name = "${name}-nono";
  paths = [
    (pkgs.writeShellScriptBin name ''
      if [ -n "$NONO_CAP_FILE" ]; then exec ${pkg}/bin/${name} "$@"; fi
      export TMPDIR="''${TMPDIR:-${tmpDir}}"
      mkdir -p "$TMPDIR"
      # agent-browser's default socket dir (/run/user) is read-only in the sandbox,
      # and Chromium's own sandbox cannot start under Landlock
      export AGENT_BROWSER_SOCKET_DIR="''${AGENT_BROWSER_SOCKET_DIR:-$TMPDIR/agent-browser}"
      export AGENT_BROWSER_ARGS="''${AGENT_BROWSER_ARGS:---no-sandbox}"
      exec ${nono}/bin/nono run --silent --profile ${profile} ${pkgs.lib.escapeShellArgs nonoArgs} -- ${pkg}/bin/${name} "$@"
    '')
    pkg
  ];
}
