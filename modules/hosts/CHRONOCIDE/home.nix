{ ... }:
{
	flake.modules.homeManager.CHRONOCIDE = { lib, pkgs, ... }: {
		home.username = "cairo";
		home.homeDirectory = "/home/cairo";

		# Release this machine was first installed with; do not change.
		home.stateVersion = "26.05";

		home.file = {};

		# Let Home Manager install and manage itself.
		programs.home-manager.enable = true;

		# get rid of mismatch version error on rebuild
		stylix.enableReleaseChecks = false;

		home.packages = with pkgs; [
			obsidian # Super+O N (Electron, heavy: see docs/hosts/CHRONOCIDE.md)
			libnotify # notify-send, used by start.sh
			# added on request (2026-11-16); picked individually from apps-packages
			# so this host does not take the rest of that bag (remmina, chromium,
			# helium, image viewers, ...). Heavy ones are listed in
			# docs/hosts/CHRONOCIDE.md.
			vlc
			obs-studio
			firefox
			brave
			onlyoffice-desktopeditors
		];

		# niri is the only session here; the shared environment fragment defaults
		# this to Hyprland.
		home.sessionVariables.XDG_SESSION_DESKTOP = "niri";

		# xremap talks to niri here, not Hyprland.
		services.xremap = {
			withHypr = false;
			withNiri = true;
		};

		# Discord itself is not wanted on 4 GB; Vesktop (Super+O V) is. The
		# discord fragment installs both unless this is off.
		programs.nixcord.discord.enable = lib.mkForce false;

		# 1366x768 panel, scale 1; windows are full width by default, which is
		# the only comfortable size at this resolution. Shadows and blur are off
		# to spare the Intel HD 6000 and RAM; gaps are small for the same reason.
		niri = {
			outputs."eDP-1" = {
				mode = "1366x768";
				scale = 1.0;
				position = { x = 0; y = 0; };
			};
			columnWidth = 1.0;
			gaps = { inner = 4; outer = 6; };
			shadow = false;
			blur = false;
			focusRing = true; # a one-column-wide view needs a focus cue
			touchpad = {
				tap = true;
				naturalScroll = true;
			};
		};

		programs.noctalia.settings = {
			# Noctalia has a built-in polkit agent; niri starts none.
			shell.polkit_agent = true;
			# Less CPU/GPU work on the integrated GPU.
			shell.animation.enabled = false;
		};
	};
}
