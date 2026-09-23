{ lib, ... }:
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
      (final: prev: {
        # Not in nixpkgs yet
        codiff = final.callPackage ../pkgs/codiff/package.nix { };
        dankcalendar = final.callPackage ../pkgs/dankcalendar/package.nix { };
        open-pencil = final.callPackage ../pkgs/open-pencil/package.nix { };
        strata = final.callPackage ../pkgs/strata/package.nix { };
        # Curtail shells out to `scour` for SVG, but the nixpkgs wrapper only puts
        # the JPEG/PNG/WebP tools on PATH, so SVG fails with "An unknown error has
        # occurred" (shell exit 127 swallowed by Compressor.run's catch-all)
        curtail = prev.curtail.overrideAttrs (old: {
          preFixup = (old.preFixup or "") + ''
            makeWrapperArgs+=("--prefix" "PATH" ":" "${lib.makeBinPath [ prev.scour ]}")
          '';
        });
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
