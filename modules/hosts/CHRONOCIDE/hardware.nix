# PLACEHOLDER: replace this module's body with the real hardware scan.
#
# On the MacBook, after installing NixOS, run
#   nixos-generate-config --show-hardware-config
# and copy its output over the body below, as the other hosts do (see
# modules/hosts/REGICIDE/hardware.nix). Keep the fragment name and keep these
# parts of the generated output:
#   boot.initrd.availableKernelModules, boot.kernelModules, fileSystems.*,
#   swapDevices (leave it empty: zram is the swap, see machine.nix),
#   nixpkgs.hostPlatform, hardware.cpu.intel.updateMicrocode.
# Do not copy boot.extraModulePackages or networking.* lines that mention
# Wi-Fi: the Broadcom driver is set in machine.nix.
#
# The by-label devices below only exist so that the flake evaluates and builds
# before the real scan exists. They match the labels used in
# docs/hosts/CHRONOCIDE.md (`mkfs.ext4 -L nixos`, `mkfs.vfat -n BOOT`).
{ ... }:
{
	flake.modules.nixos."CHRONOCIDE-hardware" = { config, lib, modulesPath, ... }: {
		imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

		# The 2015 MacBook Air has a PCIe SSD on AHCI; nvme covers a replacement SSD.
		boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
		boot.initrd.kernelModules = [ ];
		boot.kernelModules = [ "kvm-intel" ];

		fileSystems."/" = {
			device = "/dev/disk/by-label/nixos";
			fsType = "ext4";
		};

		fileSystems."/boot" = {
			device = "/dev/disk/by-label/BOOT";
			fsType = "vfat";
			options = [ "fmask=0022" "dmask=0022" ];
		};

		swapDevices = [ ];

		networking.useDHCP = lib.mkDefault true;

		nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
		hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	};
}
