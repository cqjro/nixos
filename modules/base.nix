{ ... }:
{
	flake.modules.nixos.base = { pkgs, inputs, ... }: {
		# Nix Settings
		nix.settings.experimental-features = [ "nix-command" "flakes" ];

		nixpkgs.config.allowUnfree = true;
		nixpkgs.config.allowUnfreePredicate = _: true; # needed for home-manager

		# Set your time zone.
		time.timeZone = "America/Toronto";

		programs.zsh.enable = true;

		# Define a user account.
		users.users.cairo = {
			isNormalUser = true;
			shell = pkgs.zsh;
			extraGroups = [ "wheel" "networkmanager" "video" "audio" ]; # Enable ‘sudo’ for the user.
			packages = with pkgs; [ tree ];
		};

		# Options needed to enabling xremap
		hardware.uinput.enable = true;
		users.groups.uinput.members = [ "cairo" ];
		users.groups.input.members = [ "cairo" ];

		# Enabling Hyprland
		programs.hyprland = {
			enable = true;
			xwayland.enable = true;
			withUWSM = true;
			package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
		};

		# wayland support for chromium/electron apps
		environment.sessionVariables = {
			NIXOS_OZONE_WL = "1";
			ELECTRON_OZONE_PLATFORM_HINT = "wayland";
			OZONE_PLATFORM_HINT = "wayland";
			XCURSOR_SIZE = "27";
		};

		# Enable CUPS to print documents.
		services.printing.enable = true;

		# Enable sound.
		services.pipewire = {
			enable = true;
			pulse.enable = true;
			audio.enable = true;
			wireplumber.enable = true;
		};

		services.dbus.enable = true;

		# Bluetooth Settings
		hardware.bluetooth = {
			enable = true;
			powerOnBoot = true;
		};
	};
}