{ inputs, ... }:
{
	flake.modules.nixos."LittleNix" = { pkgs, ... }: {
		# T2 Mac Hardware Import: Apple Broadcom Wi-Fi/Bluetooth firmware, proprietary
		# and NOT in git. Pinned by hash; place the files per docs/firmware.md.
		imports = [ inputs.self.modules.nixos."t2-firmware" ];
		# UNVERIFIED: this is the hash of the copy that was committed in the 2025 git
		# history (now only in the private archive repo). If the files on the LittleNix
		# machine differ, the importer prints the real hash: `nix run .#t2-firmware-import -- LittleNix`.
		t2-firmware.hash = "sha256-bA/Thojm8PRCMrTwV40FhNZ++Y5pfRmPavgCNHkw+J4=";

		# Home-Manager
		home-manager = {
			extraSpecialArgs = { inherit inputs; };
			users.cairo = { ... }: {
				imports = with inputs.self.modules.homeManager;
					[
						LittleNix
						LittleNix-monitors
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
						discord-theme
						zen-browser
						nemo
						calibre
						apps-packages
						nixdatifier
						inputs.self.modules.homeManager."3d-printing"
						latex
						languages-packages
						xremap
						spicetify
					];
			};
			useUserPackages = true;
			useGlobalPkgs = true;
			backupFileExtension = "backup";
		};

		# Use the systemd-boot EFI boot loader.
		boot.loader.systemd-boot.enable = true;
		boot.loader.efi.canTouchEfiVariables = true;
		boot.extraModprobeConfig = "options hid-appletb-kbd mode=2"; # sets default state of touchbar

		networking.hostName = "LittleNix"; # Define your hostname.

		fonts.packages = with pkgs; [
			nerd-fonts.jetbrains-mono
			nerd-fonts.meslo-lg
			corefonts
			# vista-fonts
			font-awesome
		];

		# List packages installed in system profile.
		environment.systemPackages = with pkgs; [
			wget # pulls data from web servers
			vim # default editor
			kitty # default terminal for hyprland
			tiny-dfr # for macbook touchbar
			wireplumber
		];

		system.stateVersion = "25.05"; # Did you read the comment?
	};
}