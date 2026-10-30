{ inputs, ... }:
{
	flake.modules.nixos."GOD-KILLER" = { pkgs, ... }: {
		# Home-Manager
		home-manager = {
			extraSpecialArgs = { inherit inputs; };
			users.cairo = { ... }: {
				imports = with inputs.self.modules.homeManager;
					[
						GOD-KILLER
						GOD-KILLER-monitors
						environment
						hyprland
						mpv
						sioyek
						zathura
						gtk
						xdg-desktop-entries
						walker
						noctalia-shell
						desktop-packages
						zsh
						ghostty
						git
						nvim
						ncspot
						starship
						yazi
						zoxide
						bat
						btop
						opencode
						nom
						terminal-packages
						discord
						inputs.self.modules.homeManager."mcp-servers"
						inputs.self.modules.homeManager."claude-code"
						inputs.self.modules.homeManager."github-cli"
						inputs.self.modules.homeManager."t3code"
					zen-browser
					nemo
					github-web-styling
					google-web-styling
					brave-web-styling
					youtube-web-styling
					reddit-web-styling
					instagram-web-styling
						nixpkgs-web-styling
						wikipedia-web-styling
						claude-web-styling
						calibre
					apps-packages
					xodus-nexus
					nixdatifier
					inputs.self.modules.homeManager."3d-printing"
					latex
					languages-packages
					xremap
					spicetify
					millennium
				];
			};
			useUserPackages = true;
			useGlobalPkgs = true;
			backupFileExtension = "backup";
		};

		services.seatd = {
			enable = true; # required for steam boot?
		};

		# millennium-themed steam client; set to false for an untouched client
		manifest.enableMillennium = true;
		# spicetify-patched spotify client; set to false for an untouched client
		manifest.enableSpicetify = true;

		# Boot Loader
		boot.loader.efi.canTouchEfiVariables = true;
		boot.loader.grub = {
			enable = true;
			devices = [ "nodev" ];
			efiSupport = true;
			useOSProber = true;
			gfxmodeEfi = "2560x1440";
			fontSize = 50;
		};

		# Use latest kernel
		boot.kernelPackages = pkgs.linuxPackages_latest;

		networking.hostName = "GOD-KILLER"; # Define your hostname.
		networking.nftables.enable = true;

		services.resolved.enable = true; # apparently this fixes slow steam downloads

		# Select Internationalisation properties
		i18n.defaultLocale = "en_CA.UTF-8";

		nix.settings.auto-optimise-store = true; # if this takes too long then switch to periodic
		# nix.optimise.automatic = true;
		# nix.optimise.dates = [ "03:45" ];

		# Automatic Garbage Collection
		# nix.gc = {
		# 	automatic = true;
		# 	dates = "weekly";
		# 	options = "--delete-older-than 30d";
		# };

		environment.sessionVariables = {
			GTK_CSD = "0";
		};

		services.udisks2.enable = true;
		services.gvfs.enable = true; # for automatic usb mounting

		services.udev.packages = with pkgs; [ mtkclient ];

		fonts.packages = with pkgs; [
			nerd-fonts.jetbrains-mono
			nerd-fonts.meslo-lg
			corefonts
			vista-fonts
			font-awesome
		];

		# List packages installed in system profile.
		environment.systemPackages = with pkgs; [
			wget # pulls data from web servers
			vim # default editor
			kitty # default terminal for hyprland
			wireplumber
		];

		system.stateVersion = "25.05"; # Did you read the comment?
	};
}
