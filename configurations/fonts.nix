{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "IBM Plex Sans Thai Looped"
          "IBM Plex Serif"
        ];
        sansSerif = [
          "IBM Plex Sans Thai Looped"
          "IBM Plex Sans"
        ];
        monospace = [ "IBM Plex Mono" ];
      };
    };
    fontDir.enable = true;
    packages = with pkgs; [
      cozette
      ibm-plex
      iosevka
      (ioskeley-mono.override { width = "SemiCondensed"; }).standard
      nerd-fonts."m+"
      noto-fonts
      sarabun-font
    ];
  };
}
