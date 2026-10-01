{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      overlays.default =
        final: _:
        builtins.mapAttrs (name: _: final.callPackage ./pkgs/${name}/package.nix { }) (
          builtins.readDir ./pkgs
        );

      packages.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux.extend self.overlays.default;
        in
        builtins.mapAttrs (name: _: pkgs.${name}) (builtins.readDir ./pkgs);

      nixosConfigurations.Polygon-NX = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          ./configurations
        ];
      };
    };
}
