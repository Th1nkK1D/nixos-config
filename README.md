# nixos-config

My NixOS configuration, plus a few packages that aren't in nixpkgs yet.

## Packages

| Package | Description |
| --- | --- |
| [codiff](https://github.com/nkzw-tech/codiff) | Minimal local diff viewer for reviewing and committing Git changes |
| [open-pencil-cli](https://openpencil.dev/programmable/cli/inspecting) | Inspect, analyze, script, and export .fig and .pen files from the terminal |
| [open-pencil-desktop](https://openpencil.dev) | Open-source design editor for .fig and .pen files with built-in AI, with its MCP server on PATH |
| [open-pencil-mcp](https://github.com/open-pencil/open-pencil/tree/main/packages/mcp) | MCP server for OpenPencil desktop automation |
| [strata](https://github.com/lgse/strata) | Fast, keyboard-first file manager for modern Linux desktops |

All packages are `x86_64-linux` only. There is no binary cache, so Nix builds them on your machine.

Strata is unfree: its RAR extraction compiles in RARLAB's UnRAR code, whose license isn't free software ([lgse/strata#1327](https://github.com/lgse/strata/issues/1327)). You need to allow unfree packages to use it.

### Try one

```sh
nix run github:Th1nkK1D/nixos-config#codiff
NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:Th1nkK1D/nixos-config#strata
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
              nixpkgs = {
                overlays = [ th1nkk1d.overlays.default ];
                config.allowUnfree = true; # for strata
              };
              environment.systemPackages = [ pkgs.strata ];
            }
          )
        ];
      };
    };
}
```

The overlay builds the packages inside your nixpkgs, so your `nixpkgs.config` (including `allowUnfree`) applies. `packages.<system>.<name>` outputs also exist, but they use a default nixpkgs config, so Strata from there needs `NIXPKGS_ALLOW_UNFREE=1` and `--impure`.

### Strata as the system file manager

The Strata package ships an XDG portal backend and an `org.freedesktop.FileManager1` D-Bus service. To use Strata for Open/Save dialogs, opening folders, and "Show in folder", add this to the module in the flake above (see also [`configurations/xdg.nix`](configurations/xdg.nix)):

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.strata ];
  xdg = {
    mime.defaultApplications."inode/directory" = "io.github.lgse.Strata.desktop";
    portal = {
      enable = true;
      extraPortals = [ pkgs.strata ];
      # Use your desktop's name: xdg-desktop-portal reads <desktop>-portals.conf
      # (XDG_CURRENT_DESKTOP) instead of portals.conf when it exists
      config.niri."org.freedesktop.impl.portal.FileChooser" = [ "strata" ];
    };
  };
}
```

Ignore the "Complete setup" button in Strata's settings. It writes per-user copies of these files that point at one `/nix/store` path and break on the next update. The desktop integration checks there also show ✗ on NixOS even when everything works, because they only look in your home directory.
