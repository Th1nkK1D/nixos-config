{ config, ... }:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings = {
        General.Experimental = true;
        Policy.AutoEnable = true;
      };
    };
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
      # patchelf 0.19.2 corrupts binaries when --interpreter and --set-rpath run in
      # one invocation, so nvidia-smi segfaults. Re-patch them in two steps until
      # https://github.com/NixOS/nixpkgs/pull/576397 (fixes
      # https://github.com/NixOS/nixpkgs/issues/576412) lands.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          for orig in $bin/origBin/*; do
            name=$(basename "$orig")
            rpath=$(patchelf --print-rpath "$bin/bin/$name")
            interp=$(patchelf --print-interpreter "$bin/bin/$name")
            install -m755 "$orig" "$bin/bin/$name"
            patchelf --set-rpath "$rpath" "$bin/bin/$name"
            patchelf --set-interpreter "$interp" "$bin/bin/$name"
          done
        '';
      });
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        # NixOS bus IDs are DECIMAL. lspci prints hex.
        # nvidia at lspci 01:00.0 -> decimal PCI:1:0:0
        # amdgpu at lspci 63:00.0 -> hex 0x63 = decimal 99 -> PCI:99:0:0
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:99:0:0";
      };
    };
    nvidia-container-toolkit.enable = true;
  };

  zramSwap.enable = true;
}
