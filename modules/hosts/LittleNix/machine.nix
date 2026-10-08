{ inputs, ... }:
{
	flake.modules.nixos."LittleNix" = { pkgs, ... }: {
		# T2 Mac Hardware Import
		hardware.firmware = [
			(pkgs.stdenvNoCC.mkDerivation (final: {
				name = "brcm-firmware";
				src = ./firmware/brcm;
				installPhase = ''
					mkdir -p $out/lib/firmware/brcm
					cp ${final.src}/* "$out/lib/firmware/brcm"
				'';
			}))
		];

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
						photocraft
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