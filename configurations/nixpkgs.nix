{ inputs, ... }:
{
  nixpkgs = {
    config = {
      allowAliases = false;
      allowBroken = true;
      allowUnfree = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [
        "keybase-gui-6.5.1"
      ];
    };
    overlays = [
      # Packages in ../pkgs, not in nixpkgs yet
      inputs.self.overlays.default
      (final: prev: {
        strata = prev.strata.override { enableUnfree = true; };
        # The desktop entry hardcodes --gtk-single-instance=true, so arguments from
        # xdg-terminal-exec (e.g. Strata's "Open terminal here") were ignores.
        # symlinkJoin instead of overrideAttrs to avoid rebuilding ghostty.
        ghostty = prev.symlinkJoin {
          inherit (prev.ghostty) name meta passthru;
          paths = [ prev.ghostty ];
          postBuild = ''
            rm $out/share/applications/com.mitchellh.ghostty.desktop
            substitute ${prev.ghostty}/share/applications/com.mitchellh.ghostty.desktop \
              $out/share/applications/com.mitchellh.ghostty.desktop \
              --replace-fail " --gtk-single-instance=true" ""
          '';
        };
      })
    ];
  };
}
