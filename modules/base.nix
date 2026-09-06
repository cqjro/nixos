{ ... }:
{
	flake.modules.nixos.base = { pkgs, inputs, ... }: {
		programs.zsh.enable = true;

		# Enabling Hyprland
		programs.hyprland = {
			enable = true;
			xwayland.enable = true;
			withUWSM = true;
			package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
		};
	};
}