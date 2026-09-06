{ ... }:
{
	flake.modules.nixos.ios-sideloading = { pkgs, inputs, ... }: {
		services.usbmuxd.enable = true;

		environment.systemPackages = with pkgs; [
			# inputs.iloader.packages.${pkgs.stdenv.hostPlatform.system}.iloader
			usbmuxd
		];
	};
}