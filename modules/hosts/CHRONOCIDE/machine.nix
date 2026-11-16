# CHRONOCIDE: MacBook Air early 2015, 11-inch (MacBookAir7,1). Intel i7
# (Broadwell), Intel HD 6000, 4 GB RAM, 1366x768, Broadcom BCM4360 Wi-Fi.
# Memory is the constraint; niri + Noctalia is its only desktop.
# Install order, checklist and the module include/exclude list:
# docs/hosts/CHRONOCIDE.md.
{ inputs, ... }:
{
	flake.modules.nixos."CHRONOCIDE" = { config, lib, pkgs, ... }: {
		# nixos-hardware: apple/macbook-air/7 sets services.mbpfan.enable
		# (fan control) and, as a default, hardware.facetimehd.enable (turned off
		# below). It sets no Wi-Fi, graphics or power options, so those are
		# written out here.
		imports = [ inputs.nixos-hardware.nixosModules.apple-macbook-air-7 ];

		# Home-Manager. The module list is the app/module selection; see
		# docs/hosts/CHRONOCIDE.md for why each one is in (or left out).
		home-manager = {
			extraSpecialArgs = { inherit inputs; };
			users.cairo = { ... }: {
				imports = with inputs.self.modules.homeManager;
					[
						CHRONOCIDE
						CHRONOCIDE-monitors
						environment
						# desktop: niri + Noctalia only (no hyprland, walker, hypr tools)
						niri
						noctalia-shell
						gtk
						xdg-desktop-entries
						keyring
						# terminal: every terminal fragment
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
						# keyboard: xremap and every app its commands launch
						xremap
						zen-browser # Super+O Z
						nemo # Super+O F
						discord # Super+O V (Vesktop; Discord itself is disabled in home.nix)
						t3code # Super+O T (heavy: see docs/hosts/CHRONOCIDE.md)
						proton-apps # Proton Mail (Super+O P), VPN, Pass
						zathura # PDFs, ~30 MB
					];
			};
			useUserPackages = true;
			useGlobalPkgs = true;
			backupFileExtension = "backup";
		};

		networking.hostName = "CHRONOCIDE";

		i18n.defaultLocale = "en_CA.UTF-8";

		# Boot: systemd-boot on the Apple EFI. If the boot entry does not persist
		# across reboots, switch to GRUB instead:
		#   boot.loader.systemd-boot.enable = false;
		#   boot.loader.grub = { enable = true; efiSupport = true; efiInstallAsRemovable = true; device = "nodev"; };
		#   boot.loader.efi.canTouchEfiVariables = false;
		boot.loader.systemd-boot.enable = true;
		boot.loader.systemd-boot.configurationLimit = 8; # the ESP is small
		boot.loader.efi.canTouchEfiVariables = true;

		# Kernel and Wi-Fi. The Broadcom `wl` driver (broadcom_sta) is fragile on
		# new kernels, so pin the 6.18 LTS series: never linuxPackages_latest.
		# (6.12 also works; it reaches end of life in December 2026.)
		boot.kernelPackages = pkgs.linuxPackages_6_18;
		boot.kernelModules = [ "wl" ];
		boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
		boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmfmac" "brcmsmac" ];
		# broadcom-sta is unfree (already allowed by the nixpkgs fragment) and
		# marked insecure (CVE-2019-9501/9502). Allowing it by name instead of the
		# exact "broadcom-sta-<version>-<kernel>" string keeps this working across
		# kernel and driver bumps without a build error each time. It also avoids
		# an infinite recursion (config.boot.kernelPackages is derived from pkgs,
		# which is derived from nixpkgs.config).
		nixpkgs.config.allowInsecurePredicate = pkg: lib.getName pkg == "broadcom-sta";

		# Webcam: facetimehd needs unfree blobs and may fail to build on a new
		# kernel. Off by default; set to true to try it.
		hardware.facetimehd.enable = false;

		# Memory: 4 GB, no disk swap. zram is the primary swap (do not add zswap).
		zramSwap = {
			enable = true;
			algorithm = "zstd";
			memoryPercent = 100;
		};
		boot.kernel.sysctl = {
			"vm.swappiness" = 180;
			"vm.page-cluster" = 0;
			"vm.watermark_boost_factor" = 0;
			"vm.watermark_scale_factor" = 125;
		};
		services.earlyoom.enable = true;
		boot.tmp.useTmpfs = false; # keep /tmp off RAM

		# Builds: one job at a time, two cores. Heavy builds (t3code, xremap, the
		# kernel module) should run on THEOCIDE with --build-host; see
		# docs/hosts/CHRONOCIDE.md. A build host can only push store paths to this
		# machine if the pushing user is trusted. cairo is already in wheel (full
		# sudo), so this adds no reach on a single-user laptop; drop it if you
		# only ever build locally.
		nix.settings = {
			max-jobs = 1;
			cores = 2;
			trusted-users = [ "root" "cairo" ];
		};

		# Graphics: Broadwell uses the i965 VA-API driver, not intel-media-driver.
		hardware.graphics = {
			enable = true;
			extraPackages = with pkgs; [ intel-vaapi-driver libvdpau-va-gl ];
		};
		environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

		# Power and thermals. power-profiles-daemon comes from the
		# power-profiles fragment (Noctalia's profile widget); do not enable TLP.
		hardware.cpu.intel.updateMicrocode = true;
		services.thermald.enable = true;
		services.upower.enable = true;
		services.fstrim.enable = true;

		# Keyboard, function keys and backlight.
		services.libinput.enable = true;
		# hid_apple fnmode: 2 = F1-F12 are plain function keys and fn gives the
		# media keys; 1 is the reverse.
		boot.extraModprobeConfig = ''
			options hid_apple fnmode=2
		'';
		services.udev.packages = [ pkgs.brightnessctl ]; # video-group backlight rules
		environment.systemPackages = with pkgs; [
			brightnessctl
			wget
			vim
			wl-clipboard
		];

		# Redistributable blobs, Bluetooth (bluetooth fragment) and audio.
		hardware.enableRedistributableFirmware = true;
		security.rtkit.enable = true;
		services.pipewire = {
			enable = true;
			alsa.enable = true;
			pulse.enable = true;
			wireplumber.enable = true;
		};

		# Lid: suspend (logind). Noctalia locks before sleep by default.
		services.logind.settings.Login = {
			HandleLidSwitch = "suspend";
			HandleLidSwitchExternalPower = "suspend";
		};
		# Some MacBooks wake from suspend at once because of the XHC1 USB
		# controller. Writing the name to /proc/acpi/wakeup toggles it, so only do
		# so while it is enabled. Remove this unit if USB wake is wanted.
		systemd.services.disable-xhc1-wakeup = {
			description = "Stop the XHC1 USB controller from waking the MacBook from suspend";
			wantedBy = [ "multi-user.target" ];
			serviceConfig = {
				Type = "oneshot";
				RemainAfterExit = true;
			};
			script = ''
				if grep -q '^XHC1.*enabled' /proc/acpi/wakeup; then
					echo XHC1 > /proc/acpi/wakeup
				fi
			'';
		};

		# niri is the only session: greetd + noctalia-greeter (a fragment in the
		# host list) starts it, and unlocks the keyring through PAM. The
		# greeter's own bundled compositor only runs until login.
		services.displayManager.noctalia-greeter.greeter-args = "--session niri";

		system.stateVersion = "26.05"; # Do not change after the first install.
	};
}
