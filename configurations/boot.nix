{ ... }:
{
  boot = {
    blacklistedKernelModules = [ "nouveau" ];
    # Disable eDP PSR: panel freezes on lock/lid-close wake with 780M (Hawk Point)
    # https://slimbook.com/en/forum/questions-and-answers-from-the-slimbook-user-community-1/question/screen-artifacts-and-glitches-with-amd-radeon-780m-and-debian-kernels-9756
    # 0x10 PSR | 0x400 Panel Replay - both default-on for DCN 3.1.4 (780M).
    # 0x200 PSR-SU and 0x800 IPS are no-ops here: PSR-SU is hard-disabled
    # upstream since 6.18, IPS is DCN 3.5+ only.
    kernelParams = [ "amdgpu.dcdebugmask=0x410" ];
    initrd = {
      luks.devices."luks-6b985d7e-f11a-4a4f-a606-f28b6a565c2e".device =
        "/dev/disk/by-uuid/6b985d7e-f11a-4a4f-a606-f28b6a565c2e";
      systemd.enable = true;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
}
