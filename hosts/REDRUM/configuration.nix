{pkgs, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
			../../modules/server/default.nix
      inputs.home-manager.nixosModules.default
    ];
	
	services.logind.settings.Login.HandleLidSwitch = "ignore";

  nix.settings.experimental-features = ["nix-command" "flakes"];  

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
      src = ./firmware/brcm;
      installPhase = ''
				mkdir -p $out/lib/firmware/brcm
				cp ${final.src}/* "$out/lib/firmware/brcm"
			'';
    }))
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
     "cairo" = import ./home.nix;  
    };
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
  };

  networking.hostName = "REDRUM"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

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

	nix.settings.trusted-users = [ "root" "cairo" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.cairo = {
    isNormalUser = true;
		openssh.authorizedKeys.keys = [
  	  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBR8F9bwCx8EUHCNpMAMpSnnErqkHYAeEVbk9KyHzzy1"
  	];
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
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
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     neovim
     git
     wifitui
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
  system.stateVersion = "26.11"; # Did you read the comment?

}

