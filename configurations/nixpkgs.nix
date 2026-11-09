{ inputs, ... }:
{
  nixpkgs = {
    config = {
      allowAliases = false;
      allowBroken = true;
      allowUnfree = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [
        "keybase-gui-6.6.3"
      ];
    };
    overlays = [
      # Packages in ../pkgs, not in nixpkgs yet
      inputs.self.overlays.default
      (
        final: prev:
        let
          withZstdPkgConfig =
            pkg:
            pkg.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
              buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];
            });
        in
        {
          # hyprpolkitagent aborts on fractional scale under niri (std::out_of_range),
          # so pkexec has no agent. Fixed in hyprtoolkit main (hyprwm/hyprtoolkit#136, merged 2026-10-12), not released yet.
          # Drop this once nixpkgs hyprtoolkit is newer than 0.6.0.
          hyprtoolkit = prev.hyprtoolkit.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (prev.fetchpatch2 {
                url = "https://github.com/hyprwm/hyprtoolkit/commit/2907e0d1f8a3a540737a0e738acc40d48ad7ba0d.patch";
                hash = "sha256-ZNd82uFDpPCd5NhLOG1L31Bmkl/Ji2GRaW7LavzXfTo=";
              })
            ];
          });
          # cargo-setup-hook now exports ZSTD_SYS_USE_PKG_CONFIG=1 (NixOS/nixpkgs#537108),
          # so crates using zstd-sys need pkg-config and zstd. Drop each once nixpkgs
          # fixes it; the pending figma-agent 0.4.4 bump (#584117) doesn't touch inputs.
          figma-agent = withZstdPkgConfig prev.figma-agent;
          ark = withZstdPkgConfig prev.ark;
          # Same hook (NixOS/nixpkgs#537108, #521991) sets LIBSQLITE3_SYS_USE_PKG_CONFIG=1,
          # so libsqlite3-sys links the system sqlite, which the nixpkgs package
          # doesn't provide
          tabularis = prev.tabularis.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.sqlite ];
          });
          strata = prev.strata.override { enableUnfree = true; };
          codiff = prev.codiff.override { withAutoHideMenuBar = true; };
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
        }
      )
    ];
  };
}
