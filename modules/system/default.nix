{pkgs, ...}:
{
	imports = [
		./ssh.nix
		./networking/default.nix
		./vpn.nix
		./stylix.nix
		./nvidia.nix
		./games.nix
		# ./flatpak.nix
		./openrgb.nix
		./power-profiles-daemon.nix
		./android/default.nix
		./ios-sideloading.nix
	];

	environment.systemPackages = with pkgs; [
		ddcutil
	];
}
