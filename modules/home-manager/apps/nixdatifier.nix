{ inputs, ... }:
{
	# Nixdatifier: system generations, package diffs, flake-update checks, dev
	# environments and store tools — a tray app on the desktop hosts plus the
	# `nixdatifier` CLI/TUI everywhere. Not in nixpkgs yet, so it comes from its
	# own flake; the upstream Home Manager module is imported below and
	# configured here. The tray icon registers as a StatusNotifierItem in
	# noctalia's bar tray widget (a click toggles the window), so no extra
	# panel/pill is needed. Hosts without a graphical session (REDRUM) set
	# `programs.nixdatifier.ui = false` for the CLI only.
	flake.modules.homeManager."nixdatifier" = { config, lib, ... }: {
		imports = [ inputs.nixdatifier.homeManagerModules.default ];

		programs.nixdatifier = {
			enable = true;

			# The upstream autostart option only writes an XDG autostart desktop
			# entry, which nothing processes under Hyprland — the user service
			# below replaces it.
			autostart = false;

			# Check flake inputs upstream every 6h and get a desktop
			# notification when updates are pending (timer from the upstream
			# module; the terminal view can toggle it too via `nixdatifier watch`).
			tui.updateCheck = {
				enable = true;
				interval = "6h";
			};

			# Quick-run commands from the flake directory; the one labelled
			# "rebuild" is what `nixdatifier rebuild` runs.
			tui.commands = [
				{ label = "rebuild"; cmd = "./rebuild.sh"; }
			];

			# Terminal-view theme derived from the stylix palette — colours are
			# never hardcoded in modules (AGENTS.md theming rule).
			tui.themes.stylix = let c = config.lib.stylix.colors; in {
				accent = "#${toString c.base0D}";
				label = "#${toString c.base0E}";
				text = "#${toString c.base05}";
				muted = "#${toString c.base04}";
				border = "#${toString c.base03}";
				select = "#${toString c.base02}";
				match = "#${toString c.base0A}";
				pointer = "#${toString c.base0C}";
				ok = "#${toString c.base0B}";
				bad = "#${toString c.base08}";
				warn = "#${toString c.base09}";
				bg = "#${toString c.base00}";
			};
			tui.theme = "stylix";
		};

		# Start the tray app with the graphical session (UWSM keeps
		# graphical-session.target active; noctalia runs the same way). Skipped
		# entirely when ui = false — there is no tray app to start.
		systemd.user.services.nixdatifier = lib.mkIf config.programs.nixdatifier.ui {
			Unit = {
				Description = "Nixdatifier tray app";
				PartOf = [ "graphical-session.target" ];
				After = [ "graphical-session.target" ];
			};
			Service = {
				ExecStart = "${config.programs.nixdatifier.package}/bin/nixdatifier --background";
				Restart = "on-failure";
			};
			Install.WantedBy = [ "graphical-session.target" ];
		};
	};
}
