{ ... }:
{
	# `theme-shots` packaged into the system profile and run as
	# /run/current-system/sw/bin/theme-shots: an absolute path an agent cannot edit
	# (root-owned symlink into the store), which the managed policy excludes from the
	# sandbox and allow-lists (modules/home-manager/ai-tools/claude-code.nix). It renders
	# the generated Zen userContent.css in a throwaway headless profile of the INSTALLED
	# Zen (the package home-manager installs, so the same build and policies), so a
	# thread can see which per-site rules are broken. Logged out only. Design and
	# limits: docs/agents/theme-shots.md; trust assumptions: docs/agents/security.md.
	flake.modules.nixos."theme-shots" = { config, pkgs, ... }:
	let
		urls = pkgs.writeText "theme-shots-urls.txt" (builtins.readFile ../scripts/theme-shots-urls.txt);
		# the exact Zen the user runs (binary `zen-twilight`): finalPackage is what
		# home-manager installs, with the policies and extraPrefs baked in; `package` is
		# the bare wrapper and would render differently (tracking protection, ...)
		zen = config.home-manager.users.cairo.programs.zen-browser.finalPackage;

		theme-shots = pkgs.writeShellApplication {
			name = "theme-shots";
			# the whole PATH: the script rebuilds the environment of every child
			inheritPath = false;
			runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.gzip pkgs.jq pkgs.getent pkgs.curl zen pkgs.git config.nix.package ];
			text = builtins.replaceStrings [ "@urls@" ] [ "${urls}" ] (builtins.readFile ../scripts/theme-shots.sh);
		};
	in {
		environment.systemPackages = [ theme-shots ];
	};
}
