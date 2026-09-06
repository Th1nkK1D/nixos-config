{ pkgs, ... }:
{
  services = {
    automatic-timezoned.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    caddy = {
      enable = true;
      virtualHosts = {
        "syncthing.localhost".extraConfig = ''
          reverse_proxy http://localhost:8384
        '';
        "wakapi.localhost".extraConfig = ''
          reverse_proxy http://localhost:3333
        '';
      };
    };
    displayManager = {
      autoLogin = {
        enable = true;
        user = "lkz";
      };
      defaultSession = "niri";
      dms-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/lkz";
      };
    };
    geoclue2.enable = true;
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true;
    keybase.enable = true;
    kbfs.enable = true;
    languagetool = {
      enable = true;
      allowOrigin = "*";
    };
    ollama.enable = true;
    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "lkz" ];
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pulseaudio.enable = false;
    printing.enable = true;
    tailscale = {
      enable = true;
      openFirewall = true;
    };
    udev.packages = [ pkgs.libmtp.out ];
    udisks2.enable = true;
    upower.enable = true;
    wakapi = {
      enable = true;
      environmentFiles = [
        "/home/lkz/.wakapi.env"
      ];
      settings = {
        app.leaderboard_enabled = false;
        mail.enabled = false;
        server.port = 3333;
      };
    };
    xserver.videoDrivers = [
      "amdgpu"
      "nvidia"
    ];
  };
}
