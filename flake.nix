{
	description = "main system flake";

	inputs = {
		# dendritic scaffolding
		flake-parts.url = "github:hercules-ci/flake-parts";
		import-tree.url = "github:vic/import-tree";

		# default nixos
		nixpkgs.url = "nixpkgs/nixos-unstable";
		nixos-hardware.url = "github:nixos/nixos-hardware";

		# REDRUM T2 kernel pin: cac0c1ef is the last nixpkgs rev whose kernel is
		# still 6.18.46; linux >= 6.18.47 breaks the apple-t2 t2linux patchset
		# (nixos-hardware#2027). TODO-remove: drop this input AND the `nixpkgs.pkgs`
		# override in the REDRUM block of modules/hosts/host.nix once nixos-hardware
		# is fixed on current nixpkgs. See modules/hosts/REDRUM/T2-PIN.md.
		nixpkgs-redrum.url = "github:NixOS/nixpkgs/cac0c1ef61ab13dc82e5368e34de132a74336d79";

		# home-manager
		home-manager = {
			url = "github:nix-community/home-manager/";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		hyprland.url = "github:hyprwm/Hyprland";
		# archived: not referenced by any live module
		# hyprland-plugins = {
		# 	url = "github:hyprwm/hyprland-plugins";
		# 	inputs.hyprland.follows = "hyprland";
		# };

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

		# spotify theming
		spicetify-nix = {
			url = "github:Gerg-L/spicetify-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# steam theming (millennium)
		nixos-millennium = {
			url = "github:re1n0/nixos-millennium";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# not on nixpkgs yet
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.home-manager.follows = "home-manager";
		};

		firefox-addons = {
			url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		helium = {
			url = "github:schembriaiden/helium-browser-nix-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nixcord = {
			url = "github:kaylorben/nixcord";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# bridge linux to the iphone: notifications, messages, clipboard, files
		tether = {
			url = "github:zackb/tether";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# archived: flatpak module moved to modules/_archive/flatpak.nix
		# nix-flatpak = {
		# 	url = "github:gmodena/nix-flatpak";
		# };

		nixpkgs-openconnect-sso.url = "github:nixos/nixpkgs/46397778ef1f73414b03ed553a3368f0e7e33c2f";

		openconnect-sso = {
			url = "github:jcszymansk/openconnect-sso";
			inputs.nixpkgs.follows = "nixpkgs-openconnect-sso";
		};

		elephant.url = "github:abenz1267/elephant"; # required for walker

		walker = {
			url = "github:abenz1267/walker";
			inputs.elephant.follows = "elephant";
		};

		# archived: caelestia-shell module moved to modules/_archive/caelestia-shell.nix
		# caelestia-shell = {
		# 	url = "github:caelestia-dots/shell";
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };

		# archived: only referenced by a commented-out fragment in
		# modules/system/ios-sideloading.nix
		# iloader = {
		# 	url = "github:nab138/iloader";
		# 	inputs.nixpkgs.follows = "nixpkgs";
		# };

		noctalia = {
			url = "github:noctalia-dev/noctalia";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		noctalia-greeter = {
			url = "github:noctalia-dev/noctalia-greeter";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs@{ ... }:
		inputs.flake-parts.lib.mkFlake { inherit inputs; } {
			imports = [
				inputs.flake-parts.flakeModules.modules
				(inputs.import-tree ./modules)
			];
			systems = [ "x86_64-linux" ];
		};
}