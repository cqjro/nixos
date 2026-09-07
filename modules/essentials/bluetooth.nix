{ ... }:
{
	flake.modules.nixos.bluetooth = {
		# Bluetooth Settings
		hardware.bluetooth = {
			enable = true;
			powerOnBoot = true;
		};
	};
}