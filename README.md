# nixos-config

My NixOS configuration, plus a few packages that aren't in nixpkgs yet.

## Packages

| Package | Description |
| --- | --- |
| [codiff](https://github.com/nkzw-tech/codiff) | Minimal local diff viewer for reviewing and committing Git changes |
| [open-pencil](https://openpencil.dev) | Open-source design editor for .fig and .pen files with built-in AI |
| [strata](https://github.com/lgse/strata) | Fast, keyboard-first file manager for modern Linux desktops |

All packages are `x86_64-linux` only. There is no binary cache, so Nix builds them on your machine.

### Try one

```sh
nix run github:Th1nkK1D/nixos-config#strata
```

### Add to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    th1nkk1d = {
      url = "github:Th1nkK1D/nixos-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, th1nkk1d, ... }:
    {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        modules = [
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                th1nkk1d.packages.${pkgs.stdenv.hostPlatform.system}.strata
              ];
            }
          )
        ];
      };
    };
}
```

With `inputs.nixpkgs.follows`, the packages build against your nixpkgs instead of the one pinned here.

### Strata as the system file manager

The Strata package ships an XDG portal backend and an `org.freedesktop.FileManager1` D-Bus service. To use Strata for Open/Save dialogs, opening folders, and "Show in folder", use this as the inline module in the flake above (see also [`configurations/xdg.nix`](configurations/xdg.nix)):

```nix
{ pkgs, ... }:
let
  strata = th1nkk1d.packages.${pkgs.stdenv.hostPlatform.system}.strata;
in
{
  environment.systemPackages = [ strata ];
  xdg = {
    mime.defaultApplications."inode/directory" = "io.github.lgse.Strata.desktop";
    portal = {
      enable = true;
      extraPortals = [ strata ];
      # Use your desktop's name: xdg-desktop-portal reads <desktop>-portals.conf
      # (XDG_CURRENT_DESKTOP) instead of portals.conf when it exists
      config.niri."org.freedesktop.impl.portal.FileChooser" = [ "strata" ];
    };
  };
}
```

Ignore the "Complete setup" button in Strata's settings. It writes per-user copies of these files that point at one `/nix/store` path and break on the next update. The desktop integration checks there also show ✗ on NixOS even when everything works, because they only look in your home directory.
