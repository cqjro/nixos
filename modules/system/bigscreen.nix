# TV mode: KDE Plasma Bigscreen as a second session next to Hyprland, plus the
# couch apps it launches. Replaces the Waydroid Android TV attempt, which is
# blocked by the NVIDIA driver (docs/waydroid/SPIKE.md).
#
# The greeter lists every session in services.displayManager.sessionPackages,
# so "Plasma Bigscreen (Wayland)" appears there; Hyprland stays the default
# (greeter-args in essentials/noctalia-greeter.nix). Every app here is a plain
# desktop entry, so it also opens from the Hyprland launcher.
{ ... }:
{
	flake.modules.nixos.bigscreen = { pkgs, lib, ... }:
		let
			kde = pkgs.kdePackages;

			# TODO-remove: registry row 15. Aura, the Bigscreen web browser. Not
			# in nixpkgs; built from upstream. Pinned to the last commit before "Port to bigscreen-ui"
			# (2026-10-30): v26.11.0 imports org.kde.bigscreen.ui, which only
			# exists in Bigscreen 6.8.80+, while nixpkgs ships 6.8.2. On trial:
			# delete this block and its entry below to remove it.
			aura-browser = kde.mkKdeDerivation {
				pname = "aura-browser";
				version = "unstable-2026-07-23";
				src = pkgs.fetchFromGitLab {
					domain = "invent.kde.org";
					owner = "plasma-bigscreen";
					repo = "aura-browser";
					rev = "d1d8712cc618c51272efba4b0a2feafb2e029609";
					hash = "sha256-6/uIj8QYCJaKuAZHE9f3Cq5xr5z740E1/Hm5pVEFR5k=";
				};
				extraBuildInputs = with kde; [
					qtwebengine
					qtwebchannel
					qtdeclarative
				];
				meta.license = [ lib.licenses.gpl2Plus ];
			};

			# Jellyfin Desktop in TV mode, fullscreen. The app keeps the rest of
			# its settings in jellyfin-desktop.conf under
			# ~/.local/share/jellyfin-desktop/profiles/<id>/ and rewrites that
			# file itself, so only what has a command-line flag is declarative
			# here. Set the interface scale (an integer, or "auto") below.
			jellyfinTvScale = "auto";
			jellyfinTv = pkgs.writeShellScriptBin "jellyfin-tv" ''
				exec ${lib.getExe pkgs.jellyfin-desktop} --fullscreen --tv --scale-factor ${jellyfinTvScale} "$@"
			'';
			jellyfinTvDesktop = pkgs.makeDesktopItem {
				name = "jellyfin-tv";
				desktopName = "Jellyfin (TV mode)";
				exec = "jellyfin-tv";
				icon = "org.jellyfin.JellyfinDesktop";
				categories = [ "AudioVideo" "Video" "Player" "TV" ];
			};

			# Steam straight into Big Picture, as its own launcher tile.
			steamBigPicture = pkgs.makeDesktopItem {
				name = "steam-big-picture";
				desktopName = "Steam Big Picture";
				exec = "steam -gamepadui";
				icon = "steam";
				categories = [ "Game" ];
			};

			# Environment for anything that runs the Bigscreen shell. Upstream's
			# script first, then the shell uses KDE's own Qt theme instead of the
			# qt5ct + Kvantum theming this host sets system-wide for Hyprland
			# (Bigscreen's QML does not load with the Kvantum style). Keep this
			# split: Hyprland keeps the Stylix look, Bigscreen keeps Breeze.
			bigscreenEnv = ''
				. ${kde.plasma-bigscreen}/bin/plasma-bigscreen-common-env
				export QT_QPA_PLATFORMTHEME=kde
				unset QT_STYLE_OVERRIDE
				export QT_QUICK_CONTROLS_STYLE=org.kde.breeze
				export QT_QUICK_CONTROLS_MOBILE=true
			'';

			# Bigscreen in a window, for testing from Hyprland without logging
			# out (upstream README, "running in a window"). It uses its own
			# D-Bus session, so it does not touch the running desktop.
			bigscreenWindowed = pkgs.writeShellScriptBin "bigscreen-windowed" ''
				${bigscreenEnv}
				export XDG_CURRENT_DESKTOP=KDE
				exec dbus-run-session kwin_wayland --width 1920 --height 1080 "plasmashell -p org.kde.plasma.bigscreen"
			'';

			# The session the greeter starts. Upstream's own session script with
			# the Qt overrides from bigscreenEnv applied after its environment.
			bigscreenSessionScript = pkgs.writeShellScript "plasma-bigscreen-session" ''
				${bigscreenEnv}
				exec startplasma-wayland --xwayland --libinput --exit-with-session=${kde.plasma-workspace}/libexec/startplasma-waylandsession
			'';
			bigscreenSession = (pkgs.writeTextDir "share/wayland-sessions/plasma-bigscreen.desktop" ''
				[Desktop Entry]
				Name=Plasma Bigscreen
				Comment=Plasma Bigscreen by KDE
				Exec=${kde.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed ${bigscreenSessionScript}
				DesktopNames=KDE
				Type=Application
			'').overrideAttrs (_: {
				passthru.providedSessions = [ "plasma-bigscreen" ];
			});
			bigscreenWindowedDesktop = pkgs.makeDesktopItem {
				name = "bigscreen-windowed";
				desktopName = "Plasma Bigscreen (windowed test)";
				exec = "bigscreen-windowed";
				icon = "plasma";
				categories = [ "Utility" ];
			};
		in
		{
			# Bigscreen is a shell on top of a Plasma session, so it needs the
			# Plasma 6 base (KWin, plasma-workspace, KCMs, portals).
			services.desktopManager.plasma6.enable = true;
			services.displayManager.sessionPackages = [ bigscreenSession ];

			# Keep the Plasma base small: no desktop apps Hyprland already covers.
			environment.plasma6.excludePackages = with kde; [
				elisa
				gwenview
				okular
				kate
				khelpcenter
				konsole
				ark
				spectacle
				krdp
				plasma-browser-integration
				plasma-workspace-wallpapers
			];

			# Plasma defaults this host does not want.
			programs.kde-pim.enable = false;
			services.orca.enable = false;
			services.geoclue2.enable = false;
			services.fwupd.enable = false;

			# Stylix picks its "kde" Qt platform whenever plasma6 is enabled, which
			# would replace the qtct/Kvantum theming Hyprland uses. Hyprland is the
			# main session, so this host deliberately stays on qtct.
			stylix.targets.qt.platform = lib.mkForce "qtct";

			# Hyprland's portal config takes precedence over the plasma6 default;
			# add the Plasma one too so the Bigscreen session finds its portals.
			xdg.portal.configPackages = [ kde.plasma-workspace ];

			# Phone as remote, keyboard and touchpad; opens TCP/UDP 1714-1764.
			programs.kdeconnect.enable = true;

			environment.systemPackages = [
				kde.plasma-bigscreen
				kde.plasma-nano # shell package Bigscreen builds on
				bigscreenWindowed
				bigscreenWindowedDesktop

				pkgs.jellyfin-desktop
				jellyfinTv
				jellyfinTvDesktop
				pkgs.vacuum-tube # YouTube TV (leanback) UI
				steamBigPicture # steam itself comes from system/games.nix
				pkgs.retroarch # on trial
				aura-browser
			];
		};
}
