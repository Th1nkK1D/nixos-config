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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
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
}
