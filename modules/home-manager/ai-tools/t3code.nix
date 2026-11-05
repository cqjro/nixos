{ ... }:
{
	flake.modules.homeManager."t3code" = { config, lib, pkgs, ... }:
	let
		c = config.lib.stylix.colors;
		hex = base: "#${base}";

		# T3 Code only has a theme *file* mechanism, not a Nix option: it watches
		# ~/.t3/userdata/themes/<id>.json and derives any role not listed here
		# from the canvas/accent seeds. Roles with no clear base16 equivalent
		# (hover shades, status surfaces) are intentionally left to that generator.
		theme = {
			name = "Stylix";
			appearance = "dark";
			canvas = hex c.base00;
			accent = hex c.base0D;
			colors = lib.mapAttrs (_: hex) {
				# surfaces
				canvas = c.base00;
				chrome = c.base00;
				toolbar = c.base00;
				toolbarControl = c.base01;
				toolbarControlHover = c.base03;
				surface = c.base01;
				surfaceRaised = c.base01;
				surfaceOverlay = c.base01;
				secondary = c.base01;
				muted = c.base01;
				accentSurface = c.base01;
				messageSurface = c.base01;
				codeBackground = c.base01;

				# sidebar
				sidebar = c.base00;
				sidebarControlSurface = c.base01;
				sidebarRowHover = c.base01;
				sidebarRowActive = c.base03;
				sidebarRowSelected = c.base03;

				# text
				text = c.base06;
				textMuted = c.base05;
				toolbarForeground = c.base06;
				toolbarControlForeground = c.base06;
				sidebarForeground = c.base06;
				sidebarMutedForeground = c.base05;
				secondaryForeground = c.base06;
				mutedForeground = c.base05;
				accentSurfaceForeground = c.base06;
				messageForeground = c.base06;
				codeForeground = c.base06;
				placeholder = c.base05;
				secondaryLabel = c.base05;
				iconMuted = c.base05;

				# borders / inputs / focus
				border = c.base03;
				toolbarBorder = c.base03;
				sidebarBorder = c.base03;
				input = c.base03;
				focus = c.base0D;

				# accent
				accent = c.base0D;
				accentForeground = c.base07;
				messageAction = c.base0D;
				messageActionForeground = c.base07;

				# status
				error = c.base08;
				errorForeground = c.base08;
				warning = c.base09;
				warningForeground = c.base0A;
				update = c.base0D;
				updateForeground = c.base0D;

				# terminal
				terminalBackground = c.base00;
				terminalForeground = c.base05;
				terminalCursor = c.base05;
				terminalSelection = c.base02;
				terminalScrollbar = c.base03;
				terminalScrollbarHover = c.base02;

				# find-in-page
				searchMatchBackground = c.base02;
				searchMatchForeground = c.base07;
				searchMatchActiveBackground = c.base0A;
				searchMatchActiveForeground = c.base00;
			};
		};

		# TODO-remove: nixpkgs' t3code builds the Electron app but not the native
		# Hyprland capture helper, so "Allow snapshots" fails with "The Hyprland
		# capture helper is missing from this build". Build it from the same
		# source and install it where the unpackaged app looks for its bundle
		# (<libexec/t3code>/native/hyprland-snap-shot/target/release/). The app
		# realpaths itself into t3code-unwrapped, so the file has to live there
		# (not only in the symlinkJoin wrapper), as a regular file: it lstat-rejects
		# links. Overriding the unwrapped package rebuilds the app locally.
		# See docs/agents/upstream-registry.md row 9.
		t3codeUnwrapped = pkgs.t3code.unwrapped;
		hyprlandCaptureHelper = pkgs.rustPlatform.buildRustPackage {
			pname = "t3code-hyprland-snap-shot";
			inherit (t3codeUnwrapped) version src;
			sourceRoot = "${t3codeUnwrapped.src.name}/native/hyprland-snap-shot";
			cargoHash = "sha256-oki1DAzUJ/8YIFhaJlw2wOukiQMcAaexdJqxDcFXFW4=";
			meta = {
				description = "Native Hyprland window capture helper for T3 Code";
				inherit (t3codeUnwrapped.meta) homepage license platforms;
				mainProgram = "t3-hyprland-snap-shot";
			};
		};
		t3codeWithCapture = pkgs.t3code.override {
			t3code-unwrapped = t3codeUnwrapped.overrideAttrs (old: {
				postInstall = (old.postInstall or "") + ''
					install -Dm755 ${hyprlandCaptureHelper}/bin/t3-hyprland-snap-shot \
						"$out"/libexec/t3code/native/hyprland-snap-shot/target/release/t3-hyprland-snap-shot
				'';
			});
		};
	in {
		programs.t3code = {
			enable = true;
			package = t3codeWithCapture;
			# merged into settings.json (the file stays writable by the app)
			userSettings.defaultTheme = "stylix";
		};

		# a real file, not home.file: the server opens theme files with
		# O_NOFOLLOW and silently ignores symlinks into the nix store
		home.activation.t3codeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
			install -Dm644 ${pkgs.writeText "t3code-stylix-theme.json" (builtins.toJSON theme)} "$HOME/.t3/userdata/themes/stylix.json"
		'';
	};
}
