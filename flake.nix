{
  description = "main system flake";

  inputs = {
    # default nixos
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # not on nixpkgs yet
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # hyprcursor theme
    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprland/hyprlang";
    };

    xremap-flake.url = "github:xremap/nix-flake";

    # colour configuration
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors"; # remove this when stylix is configured

		nixcord = {
			url = "github:kaylorben/nixcord";
			inputs.nixpkgs.follows = "nixpkgs";
		};
  };

  outputs = {nixpkgs, nixos-hardware, home-manager, stylix, ...}@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
    in { 
      nixosConfigurations.SystemConfig = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/LittleNix/configuration.nix
          nixos-hardware.nixosModules.apple-t2
	  inputs.stylix.nixosModules.stylix
	  inputs.home-manager.nixosModules.default
        ];
      };

      #  homeConfigurations.cairo = home-manager.lib.homeManagerConfiguration {
        #  inherit pkgs;
	#  extraSpecialArgs = {inherit inputs;};
        #  modules = [
	  #  ./hosts/LittleNix/home.nix # need to find a way to have this flexible between machines.
	  #  inputs.stylix.homeModules.stylix
	#  ];
      #  };
    };
}  
