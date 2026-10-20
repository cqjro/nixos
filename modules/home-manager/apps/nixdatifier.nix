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
	#
	# Widget-side settings the upstream module does not expose (font scale,
	# palette, max generations, flake path) live in ~/.config/nixdatifier —
	# `standalone.json` for the window, `config` for the CLI/window shared
	# copy. The window rewrites standalone.json on every change (even a window
	# resize), so seeding it once would never take effect on a host where the
	# app already ran, and symlinked it would revert every in-app change on
	# rebuild. The activation below instead *merges* a small declarative slice
	# of keys into the file each activation and restarts the tray app; every
	# other key stays app-owned.
	flake.modules.homeManager."nixdatifier" = { config, lib, pkgs, ... }: let
		c = config.lib.stylix.colors;
		# The declarative slice applied on every activation; colours are
		# derived from the stylix palette (never hardcoded — AGENTS.md
		# theming rule). Change values here, not in the config files.
		standaloneDefaults = pkgs.writeText "nixdatifier-standalone.json" (builtins.toJSON {
			flakePath = "${config.home.homeDirectory}/.nixos";
			maxGenerations = 20;
			fontScale = 1.3; # matches noctalia's DP-3 scale; tune in Configure → Design
			accentColor = "#${toString c.base0D}";
			timelineColor = "#${toString c.base04}";
			bgColor = "#ff${toString c.base00}"; # base00, opaque like the standalone default
		});
		seedStandalone = pkgs.writeShellScript "nixdatifier-seed-standalone" ''
			set -eu
			file="$1"
			if [[ -f "$file" ]] && ${pkgs.jq}/bin/jq -e . "$file" >/dev/null 2>&1; then
				${pkgs.jq}/bin/jq --slurpfile seed "${standaloneDefaults}" '. * $seed[0]' "$file" > "$file.tmp"
				mv "$file.tmp" "$file"
			else
				install -m 644 ${standaloneDefaults} "$file"
			fi
		'';
		basePackage = inputs.nixdatifier.packages.${pkgs.stdenv.hostPlatform.system}.${
			if config.programs.nixdatifier.ui then "nixdatifier" else "cli"
		};
		# TODO-remove: upstream workaround, registry rows 6 and 7 in AGENTS.md
		# and README. (6) diskusage hardcodes `timeout --kill-after=5s 120s`
		# around `nix-store --gc --print-dead`; that scan alone takes ~119.5s
		# on this store (326k paths, ~244k dead), so the measurement is killed
		# at random and the Tools storage card never fills in — raise the cap
		# to 300s. (7) The root panel Rectangle paints a 1px window outline in
		# wash(accentColor, .18), which with the dark palette accent reads as
		# a faint blue frame; recolour it to the panel background so it
		# blends in (visually identical to removing it with an opaque bg).
		# ui = false (the cli package) is left stock: its helpers are
		# wrapProgram-wrapped, so the timeout string is not patchable in
		# place, and nothing on REDRUM measures the store automatically.
		patchedPackage = basePackage.overrideAttrs (old: {
			postInstall = (old.postInstall or "") + ''
				substituteInPlace $out/share/nixdatifier/package/contents/tools/sh/diskusage \
					--replace-fail 'timeout --kill-after=5s 120s' 'timeout --kill-after=5s 300s'
				substituteInPlace $out/share/nixdatifier/package/contents/ui/FullView.qml \
					--replace-fail 'border.color: UI.Theme.wash(fullView.accentColor, .18)' \
					'border.color: fullView.showBg ? fullView.bgColor : "transparent"'
			'';
		});
	in {
		imports = [ inputs.nixdatifier.homeManagerModules.default ];

		programs.nixdatifier = {
			enable = true;
			package = if config.programs.nixdatifier.ui then patchedPackage else basePackage;

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

		# Apply the declarative slice of the app-owned config on every
		# activation (see header): merge the keys into standalone.json (or
		# create it), repoint the shared CLI/window copy at the system flake,
		# and restart the tray app so it reloads those values instead of
		# overwriting them from memory on its next save.
		home.activation.nixdatifierDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
			cfgDir="${config.home.homeDirectory}/.config/nixdatifier"
			run mkdir -p "$cfgDir"
			run ${seedStandalone} "$cfgDir/standalone.json"
			run ${config.programs.nixdatifier.package}/bin/nixdatifier config set flake "${config.home.homeDirectory}/.nixos"
			${lib.optionalString config.programs.nixdatifier.ui ''
				if systemctl --user is-active --quiet nixdatifier; then
					run systemctl --user daemon-reload
					run systemctl --user restart nixdatifier
				fi
			''}
		'';
	};
}
