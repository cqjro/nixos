{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
	url = "github:nix-community/home-manager/";
	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nixos-hardware, ... }@inputs:
	let
		system = "x86_64-linux";
		overlays = [];
	in
    {

      # replace yourHostname with your actual hostname!
      nixosConfigurations.REDRUM = nixpkgs.lib.nixosSystem {
        
	inherit system;
	specialArgs = {inherit inputs;};
	modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.apple-t2
	  inputs.home-manager.nixosModules.default
        ];
      };
    };
}
