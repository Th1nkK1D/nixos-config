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
        # hyprpolkitagent aborts on fractional scale under niri (std::out_of_range),
        # so pkexec has no agent. Fixed in hyprtoolkit main (PR #136), not released yet.
        # Drop this once nixpkgs hyprtoolkit is newer than 0.6.0.
        hyprtoolkit = prev.hyprtoolkit.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            (prev.fetchpatch2 {
              url = "https://github.com/hyprwm/hyprtoolkit/commit/2907e0d1f8a3a540737a0e738acc40d48ad7ba0d.patch";
              hash = "sha256-ZNd82uFDpPCd5NhLOG1L31Bmkl/Ji2GRaW7LavzXfTo=";
            })
          ];
        });
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
