{ lib, ... }:
{
  nixpkgs = {
    config = {
      allowAliases = false;
      allowBroken = true;
      allowUnfree = true;
      android_sdk.accept_license = true;
      cudaSupport = true;
      permittedInsecurePackages = [
        "beekeeper-studio-6.0.5"
        "keybase-gui-6.5.1"
      ];
    };
    overlays = [
      (final: prev: {
        # Not in nixpkgs yet
        dankcalendar = final.callPackage ../pkgs/dankcalendar/package.nix { };
        # Curtail shells out to `scour` for SVG, but the nixpkgs wrapper only puts
        # the JPEG/PNG/WebP tools on PATH, so SVG fails with "An unknown error has
        # occurred" (shell exit 127 swallowed by Compressor.run's catch-all)
        curtail = prev.curtail.overrideAttrs (old: {
          preFixup = (old.preFixup or "") + ''
            makeWrapperArgs+=("--prefix" "PATH" ":" "${lib.makeBinPath [ prev.scour ]}")
          '';
        });
        # Upstream bug (DMS 1.5.3, still on master): the bar honours showOnLastDisplay
        # but SettingsData's bar-geometry helpers do not, so on a single display the
        # bar renders while the connected frame gets no bar edge and draws no background
        # Drop once fix https://github.com/AvengeMedia/DankMaterialShell/issues/2998
        # Must run in postFixup: the package copies QML straight from $src
        dms-shell = prev.dms-shell.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            substituteInPlace $out/share/quickshell/dms/Common/SettingsData.qml \
              --replace-fail \
                'if (!prefs.includes("all") && !isScreenInPreferences(screen, prefs))' \
                'if (!prefs.includes("all") && !isScreenInPreferences(screen, prefs) && !(bc.showOnLastDisplay && Quickshell.screens.length === 1))'
          '';
        });
      })
    ];
  };
}
