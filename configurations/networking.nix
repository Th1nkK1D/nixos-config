{ ... }:
{
  networking = {
    hostName = "Polygon-NX";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
        4000
        5000
        5173
        8000
        8080
        9300 # Packet
        57621 # Spotify
      ];
      # Packet
      allowedUDPPorts = [
        5353
        5355
      ];
      # KDE Connect
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
