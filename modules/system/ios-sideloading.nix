{pkgs, inputs, ...}:
{
	services.usbmuxd.enable = true;

	environment.systemPackages = with pkgs; [
		usbmuxd
  	inputs.iloader.packages.${pkgs.stdenv.hostPlatform.system}.iloader
  	# or however you referenced it
	];
}
