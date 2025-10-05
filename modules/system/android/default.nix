{pkgs, ...}:
{
	imports = [
		./waydroid.nix
	];

	environment.systemPackages = with pkgs; [
		android-tools
	];
}
