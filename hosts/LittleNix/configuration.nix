# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
	imports =
		[ # Include the results of the hardware scan.
			./hardware-configuration.nix
			../../modules/nixos/stylix.nix
			inputs.home-manager.nixosModules.default
		];

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
		extraSpecialArgs = {inherit inputs;};
		users = {
			"cairo" = import ./home.nix;
		};
		useUserPackages = true;
		useGlobalPkgs = true;
		backupFileExtension = "backup";
	};

	# Bluetooth Settings
	hardware.bluetooth = {
		enable = true;
		powerOnBoot = true;
	};

	# Use the systemd-boot EFI boot loader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	boot.extraModprobeConfig = "options hid-appletb-kbd mode=2"; # sets default state of touchbar

	networking.hostName = "LittleNix"; # Define your hostname.
	networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
	networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

	# Set your time zone.
	time.timeZone = "America/Toronto";

	# Nix Settings
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	nix.settings.auto-optimise-store = true; # if this takes too long then switch to periodic
	# nix.optimise.automatic = true;
	# nix.optimise.dates = ["03:45"];

	# Automatic Garbage Collection
	nix.gc = {
		automatic = true;
		dates = "weekly";
		options = "--delete-older-than 30d";
	};

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Select internationalisation properties.
	# i18n.defaultLocale = "en_US.UTF-8";
	# console = {
	#   font = "Lat2-Terminus16";
	#   keyMap = "us";
	#   useXkbConfig = true; # use xkb.options in tty.
	# };

	# Enabling Hyprland
	programs.hyprland = {
		enable = true;
		xwayland.enable = true;
		withUWSM = true;
		package = inputs.hyprland.packages."${pkgs.system}".hyprland;
	};

	# wayland support for chromium/electron apps
	environment.sessionVariables = {
		NIXOS_OZONE_WL = "1";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
		OZONE_PLATFORM_HINT = "wayland";
	};

	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound.
	# services.pulseaudio.enable = true;
	# OR
	services.pipewire = {
	  enable = true;
	  pulse.enable = true;
		audio.enable = true;
		wireplumber.enable = true;
	};

	services.dbus.enable = true;

	# Enable touchpad support (enabled default in most desktopManager).
	# services.libinput.enable = true;

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.cairo = {
		isNormalUser = true;
		shell = pkgs.zsh;
		extraGroups = [ "wheel" "networkmanager" "video" "audio" ]; # Enable ‘sudo’ for the user.
		packages = with pkgs; [
			tree
		];
	};

	# Options needed to enabling xremap
	hardware.uinput.enable = true;
	users.groups.uinput.members = ["cairo"];
	users.groups.input.members = ["cairo"];

	programs.zsh.enable = true;

	fonts.packages = with pkgs; [ 
		nerd-fonts.jetbrains-mono
		nerd-fonts.meslo-lg
	];

	nixpkgs.config.allowUnfree = true;
	nixpkgs.config.allowUnfreePredicate = _: true; # needed for home-manager

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		wget # pulls data from web servers

		# text editors
		vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

		# terminals
		kitty # default terminal for hyprland

		#t2 stuff
		tiny-dfr # for macbook touchbar

		wireplumber
	];



	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Enable the OpenSSH daemon.
	# services.openssh.enable = true;

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ ... ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.
	# networking.firewall.enable = false;

	# Copy the NixOS configuration file and link it from the resulting system
	# (/run/current-system/configuration.nix). This is useful in case you
	# accidentally delete configuration.nix.
	# system.copySystemConfiguration = true;

	# This option defines the first version of NixOS you have installed on this particular machine,
	# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
	#
	# Most users should NEVER change this value after the initial install, for any reason,
	# even if you've upgraded your system to a new NixOS release.
	#
	# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
	# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
	# to actually do that.
	#
	# This value being lower than the current NixOS release does NOT mean your system is
	# out of date, out of support, or vulnerable.
	#
	# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
	# and migrated your data accordingly.
	#
	# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
	system.stateVersion = "25.05"; # Did you read the comment?

}

