{ ... }:
{
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # Force Niri/Wayland to build the primary session on your Integrated AMD GPU
      # Path must match `ls /dev/dri/by-path/` exactly: 63:00.0 (hex), not 63:0.0
      WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:63:00.0-card";
    };
  };
}
