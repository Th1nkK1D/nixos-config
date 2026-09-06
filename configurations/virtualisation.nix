{ pkgs, ... }:
{
  virtualisation = {
    docker.enable = true;
    waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };
  };
}
