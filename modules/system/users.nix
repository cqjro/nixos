{ ... }:
{
	flake.modules.nixos.users = { pkgs, ... }: {
		# Define a user account.
		users.users.cairo = {
			isNormalUser = true;
			shell = pkgs.zsh;
			extraGroups = [ "seat" "wheel" "networkmanager" "video" "audio" "dialout" "plugdev" ];
			packages = with pkgs; [ tree ];
		};

		# Options needed to enabling xremap
		hardware.uinput.enable = true;
		users.groups.uinput.members = [ "cairo" ];
		users.groups.input.members = [ "cairo" ];
	};
}