{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./environment.nix
    ./fonts.nix
    ./hardware.nix
    ./home-manager.nix
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./nixpkgs.nix
    ./programs.nix
    ./security.nix
    ./services.nix
    ./users.nix
    ./virtualisation.nix
    ./xdg.nix
  ];

  documentation.nixos.enable = false;

  system.stateVersion = "25.11";

  # KBFS workaround https://github.com/NixOS/nixpkgs/issues/278277
  systemd.user.services.kbfs.serviceConfig.PrivateTmp = lib.mkForce false;
}
