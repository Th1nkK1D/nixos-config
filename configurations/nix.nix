{ inputs, ... }:
{
  nix = {
    channel.enable = false;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    # Make `nix-shell -p`, `nix run nixpkgs#...` and <nixpkgs> resolve to the flake's pinned nixpkgs
    registry.nixpkgs.flake = inputs.nixpkgs;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      download-attempts = 10;
      stalled-download-timeout = 120;
      connect-timeout = 15;
      substituters = [
        "https://cache.nixos-cuda.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };
}
