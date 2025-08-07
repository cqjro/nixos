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
			inputs.home-manager.follows = "home-manager";
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

		nix-flatpak = {
			url = "github:gmodena/nix-flatpak";
		};
	};

	outputs = {nixpkgs, nixos-hardware,...}@inputs:
		let
			system = "x86_64-linux";
		in { 
			nixosConfigurations.LittleNix = nixpkgs.lib.nixosSystem {
				inherit system;
				specialArgs = {inherit inputs;};
				modules = [
					./hosts/LittleNix/configuration.nix
					nixos-hardware.nixosModules.apple-t2
					inputs.stylix.nixosModules.stylix
					inputs.home-manager.nixosModules.default
					inputs.nix-flatpak.nixosModules.nix-flatpak
				];
			};

			nixosConfigurations.GOD-KILLER = nixpkgs.lib.nixosSystem {
				inherit system;
				specialArgs = {inherit inputs;};
				modules = [
					./hosts/GOD-KILLER/configuration.nix
					inputs.stylix.nixosModules.stylix
					inputs.home-manager.nixosModules.default
				];
			};
		};
}  
