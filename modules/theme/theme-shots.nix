{ ... }:
{
	# `theme-shots` (agents) and `zen-shots` (the human) packaged into the system
	# profile. theme-shots runs as /run/current-system/sw/bin/theme-shots: an absolute
	# path an agent cannot edit (root-owned symlink into the store), which the managed
	# policy excludes from the sandbox and allow-lists
	# (modules/home-manager/ai-tools/claude-code.nix). It renders the generated Zen
	# userContent.css in a throwaway headless Firefox so a thread can see which
	# per-site rules are broken. Both scripts read one fixed URL list. Design and
	# limits: docs/agents/theme-shots.md; trust assumptions: docs/agents/security.md.
	flake.modules.nixos."theme-shots" = { config, pkgs, ... }:
	let
		urls = pkgs.writeText "theme-shots-urls.txt" (builtins.readFile ../scripts/theme-shots-urls.txt);

		theme-shots = pkgs.writeShellApplication {
			name = "theme-shots";
			# the whole PATH: the script rebuilds the environment of every child
			inheritPath = false;
			runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.gzip pkgs.getent pkgs.curl pkgs.firefox pkgs.git config.nix.package ];
			text = builtins.replaceStrings [ "@urls@" ] [ "${urls}" ] (builtins.readFile ../scripts/theme-shots.sh);
		};

		# human-only: drives the real Zen through Hyprland; `zen-twilight` comes from
		# the user's PATH (the zen-browser home-manager module), hence inheritPath
		zen-shots = pkgs.writeShellApplication {
			name = "zen-shots";
			runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.grim pkgs.hyprland ];
			text = builtins.replaceStrings [ "@urls@" ] [ "${urls}" ] (builtins.readFile ../scripts/zen-shots.sh);
		};
	in {
		environment.systemPackages = [ theme-shots zen-shots ];
	};
}
