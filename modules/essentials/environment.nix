{ ... }:
{
	# System-wide session variables (NixOS)
	flake.modules.nixos.environment = {
		environment.sessionVariables = {
			NIXOS_OZONE_WL = "1";
			ELECTRON_OZONE_PLATFORM_HINT = "wayland";
			OZONE_PLATFORM_HINT = "wayland";
			XCURSOR_SIZE = "27";
		};
	};

	# User-level session variables (home-manager)
	flake.modules.homeManager.environment = {
		home.sessionVariables = {
			EDITOR = "nvim";
			BROWSER = "zen";
			TERMINAL = "ghostty";
			NIXOS_OZONE_WL = "1";
			ELECTRON_OZONE_PLATFORM_HINT = "wayland";
			OZONE_PLATFORM_HINT = "wayland";
			XDG_SESSION_TYPE = "wayland";
			XDG_SESSION_DESKTOP = "Hyprland";
		};
	};
}