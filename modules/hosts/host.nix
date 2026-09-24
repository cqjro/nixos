{ inputs, ... }:
{
	flake.nixosConfigurations = let
		system = "x86_64-linux";
		overlays = [];
	in {
		GOD-KILLER = inputs.nixpkgs.lib.nixosSystem {
			inherit system;
			specialArgs = { inherit inputs; };
			modules = [
				inputs.self.modules.nixos.zsh
				inputs.self.modules.nixos.hyprland
				inputs.self.modules.nixos.nixpkgs
				inputs.self.modules.nixos.time
				inputs.self.modules.nixos.experimental-features
				inputs.self.modules.nixos.environment
				inputs.self.modules.nixos.users
				inputs.self.modules.nixos.printing
				inputs.self.modules.nixos.dbus
				inputs.self.modules.nixos.bluetooth
				inputs.self.modules.nixos.ssh
				inputs.self.modules.nixos.networking
				inputs.self.modules.nixos.vpn
				inputs.self.modules.nixos.stylix
				inputs.self.modules.nixos.nvidia
inputs.self.modules.nixos.games
			inputs.self.modules.nixos.manifest
			inputs.self.modules.nixos.openrgb
				inputs.self.modules.nixos.rss-sources
				# inputs.self.modules.nixos.android
				inputs.self.modules.nixos.audio
				inputs.self.modules.nixos.ios-sideloading
				inputs.self.modules.nixos.tether
				inputs.self.modules.nixos.minecraft
				inputs.self.modules.nixos.noctalia-greeter
				inputs.self.modules.nixos.doodads
				inputs.self.modules.nixos.tailscale
				inputs.self.modules.nixos."GOD-KILLER"
				inputs.self.modules.nixos."GOD-KILLER-hardware"
				inputs.self.modules.nixos."GOD-KILLER-monitors"
				inputs.home-manager.nixosModules.default
				inputs.stylix.nixosModules.stylix
				{ nixpkgs.overlays = overlays; }
			];
		};

		LittleNix = inputs.nixpkgs.lib.nixosSystem {
			inherit system;
			specialArgs = { inherit inputs; };
			modules = [
				inputs.self.modules.nixos.zsh
				inputs.self.modules.nixos.hyprland
				inputs.self.modules.nixos.nixpkgs
				inputs.self.modules.nixos.time
				inputs.self.modules.nixos.experimental-features
				inputs.self.modules.nixos.environment
				inputs.self.modules.nixos.users
				inputs.self.modules.nixos.printing
				inputs.self.modules.nixos.dbus
				inputs.self.modules.nixos.bluetooth
				inputs.self.modules.nixos.ssh
				inputs.self.modules.nixos.networking
				inputs.self.modules.nixos.vpn
				inputs.self.modules.nixos.stylix
				inputs.self.modules.nixos.power-profiles
				# inputs.self.modules.nixos.android
				inputs.self.modules.nixos.audio
				inputs.self.modules.nixos.ios-sideloading
				inputs.self.modules.nixos.tether
				inputs.self.modules.nixos.minecraft
				inputs.self.modules.nixos.manifest
				inputs.self.modules.nixos.rss-sources
				inputs.self.modules.nixos.noctalia-greeter
				inputs.self.modules.nixos."LittleNix"
				inputs.self.modules.nixos."LittleNix-hardware"
				inputs.self.modules.nixos."LittleNix-monitors"
				inputs.nixos-hardware.nixosModules.apple-t2
				inputs.home-manager.nixosModules.default
				inputs.stylix.nixosModules.stylix
				{ nixpkgs.overlays = overlays; }
			];
		};

		# REDRUM is built from pinned nixpkgs cac0c1ef (kernel 6.18.46) because
		# linux >= 6.18.47 breaks the apple-t2 t2linux patchset
		# (nixos-hardware#2027). TODO-remove: switch back to
		# `inputs.nixpkgs.lib.nixosSystem` once 2027 is fixed on current nixpkgs.
		# See modules/hosts/REDRUM/T2-PIN.md.
		REDRUM = inputs.nixpkgs-redrum.lib.nixosSystem {
			inherit system;
			specialArgs = { inherit inputs; };
			modules = [
				inputs.self.modules.nixos.zsh
				inputs.self.modules.nixos.nixpkgs
				inputs.self.modules.nixos.time
				inputs.self.modules.nixos.experimental-features
				inputs.self.modules.nixos."REDRUM"
				inputs.self.modules.nixos."REDRUM-hardware"
				inputs.self.modules.nixos.tailscale
				inputs.self.modules.nixos.actual-budget
				inputs.self.modules.nixos.linkwarden
				inputs.self.modules.nixos.paperless
				inputs.self.modules.nixos.beszel
				inputs.self.modules.nixos.glance
				inputs.self.modules.nixos.rss-sources
				inputs.self.modules.nixos.homepage
				inputs.self.modules.nixos.cloudflared
				inputs.self.modules.nixos.miniflux
				inputs.self.modules.nixos.reactflux
				inputs.self.modules.nixos.youtube
				inputs.self.modules.nixos.stylix
				inputs.stylix.nixosModules.stylix
				inputs.nixos-hardware.nixosModules.apple-t2
				inputs.home-manager.nixosModules.default
				{ nixpkgs.overlays = overlays; }
			];
		};
	};
}
