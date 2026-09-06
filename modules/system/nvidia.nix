{ ... }:
{
	flake.modules.nixos.nvidia = { config, ... }: {
		# Enable OpenGL
		hardware.graphics = {
			enable = true;
			enable32Bit = true;
		};

		# Load nvidia driver for Xorg and Wayland
		services.xserver.videoDrivers = [ "nvidia" ];

		hardware.nvidia = {
			# Modesetting is required.
			modesetting.enable = true;

			# Nvidia power management. Experimental, and can cause sleep/suspend to fail.
			powerManagement.enable = false;

			# Fine-grained power management. Turns off GPU when not in use.
			powerManagement.finegrained = false;

			# Use the NVidia open source kernel module.
			open = false;

			# Enable the Nvidia settings menu,
			# accessible via `nvidia-settings`.
			nvidiaSettings = true;

			# Optionally, you may need to select the appropriate driver version for your specific GPU.
			package = config.boot.kernelPackages.nvidiaPackages.stable;
		};
	};
}