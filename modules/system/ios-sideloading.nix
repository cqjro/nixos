{ ... }:
{
	flake.modules.nixos.ios-sideloading = { pkgs, inputs, ... }: {
		services.usbmuxd.enable = true;

		environment.systemPackages = with pkgs; [
			# TODO-remove: iloader from the pinned flake input (registry row 19);
			# replace with `iloader` from nixpkgs once it ships the Apple sign-in fix.
			inputs.iloader.packages.${pkgs.stdenv.hostPlatform.system}.iloader
			usbmuxd
		];
	};
}