{ inputs, ... }:
{
	flake.modules.nixos."REDRUM" = { pkgs, ... }: {
		services.logind.settings.Login.HandleLidSwitch = "ignore";

		# Use the systemd-boot EFI boot loader.
		boot.loader = {
			systemd-boot.enable = true;
			efi = {
				efiSysMountPoint = "/boot";
				canTouchEfiVariables = true;
			};
		};

		hardware.firmware = [
			(pkgs.stdenvNoCC.mkDerivation (final: {
				name = "brcm-firmware";
				src = builtins.path {
					path = /home/cairo/.nixos/modules/hosts/REDRUM/firmware/brcm;
					name = "brcm-firmware";
				};
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
						REDRUM
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
						nixdatifier
					];
					# CLI/TUI only — REDRUM has no graphical session for the tray app
					programs.nixdatifier.ui = false;
			};
			useUserPackages = true;
			useGlobalPkgs = true;
			backupFileExtension = "backup";
		};

		networking.hostName = "REDRUM"; # Define your hostname.

		# Configure network connections interactively with nmcli or nmtui.
		networking.networkmanager.enable = true;

		nix.settings.trusted-users = [ "root" "cairo" ];

		# Define a user account.
		users.users.cairo = {
			isNormalUser = true;
			openssh.authorizedKeys.keys = [
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBR8F9bwCx8EUHCNpMAMpSnnErqkHYAeEVbk9KyHzzy1"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHk7TbyTHgnWyVlF4rtLB883CKUJc5mF6dQoj5n/m1lk"
			];
			extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
			packages = with pkgs; [ tree ];
		};

		# Enable the OpenSSH daemon.
		services.openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "no";
				PasswordAuthentication = false;
			};
		};

		# List packages installed in system profile.
		environment.systemPackages = with pkgs; [
			vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
			wget
			neovim
			git
			wifitui
		];

		system.stateVersion = "26.11"; # Did you read the comment?
	};
}
