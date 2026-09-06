{ config, pkgs, ... }:
{
  programs = {
    dconf.enable = true;
    dsearch.enable = true;
    dms-shell = {
      enable = true;
      enableDynamicTheming = false;
      enableCalendarEvents = false;
      systemd.enable = true;
    };
    firejail = {
      enable = true;
      wrappedBinaries = {
        # Bypass Tailscale
        # https://github.com/tailscale/tailscale/issues/10396#issuecomment-3871203280
        vesktop = {
          executable = "${pkgs.vesktop}/bin/vesktop";
          extraArgs = [
            "--net=wlp2s0"
            "--noprofile"
          ];
        };
      };
    };
    gnome-disks.enable = true;
    kdeconnect.enable = true;
    nh = {
      enable = true;
      flake = "/home/lkz/Repositories/nixos-config";
    };
    niri.enable = true;
    nix-ld = {
      enable = true;
      # stdenv.cc.cc.lib + zlib: pip-installed torch/numpy wheels need a 64-bit
      # libstdc++.so.6 and libz.so.1. nvidia package: libcuda.so.1 for the cuda wheels.
      libraries = pkgs.steam-run.args.multiPkgs pkgs ++ [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        config.hardware.nvidia.package
      ];
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };
}
