{ lib, ... }:
{
  nixpkgs = {
    config = {
      allowAliases = false;
      allowBroken = true;
      allowUnfree = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [
        "beekeeper-studio-6.0.5"
        "keybase-gui-6.5.1"
      ];
    };
    overlays = [
      (final: prev: {
        # Not in nixpkgs yet
        codiff = final.callPackage ../pkgs/codiff/package.nix { };
        dankcalendar = final.callPackage ../pkgs/dankcalendar/package.nix { };
        strata = final.callPackage ../pkgs/strata/package.nix { };
        # Curtail shells out to `scour` for SVG, but the nixpkgs wrapper only puts
        # the JPEG/PNG/WebP tools on PATH, so SVG fails with "An unknown error has
        # occurred" (shell exit 127 swallowed by Compressor.run's catch-all)
        curtail = prev.curtail.overrideAttrs (old: {
          preFixup = (old.preFixup or "") + ''
            makeWrapperArgs+=("--prefix" "PATH" ":" "${lib.makeBinPath [ prev.scour ]}")
          '';
        });
      })
    ];
  };
}
