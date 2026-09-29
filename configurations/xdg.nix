{ pkgs, ... }:
{
  xdg = {
    mime.defaultApplications."inode/directory" = "io.github.lgse.Strata.desktop";
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        strata
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = [
          "gnome"
          "gtk"
        ];
        niri."org.freedesktop.impl.portal.FileChooser" = [ "strata" ];
      };
    };
  };
}
