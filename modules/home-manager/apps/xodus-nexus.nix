{ ... }:
{
	# Xodus Nexus: an Xbox-inspired launcher for Microsoft Store / PC Game Pass
	# games on Linux. It wraps the upstream Xodus backend (Microsoft sign-in,
	# licence checks, package downloads) and the Nexus runtime (a patched
	# Xodus Proton build). The launcher installs the backend and runtime from
	# its own releases into the user's data directory at first run, so only the
	# AppImage itself is packaged here. See the README's "Xbox Game Pass" notes.
	flake.modules.homeManager."xodus-nexus" = { pkgs, ... }:
		let
			# TODO-remove: Xodus Nexus is not in nixpkgs and upstream ships no
			# flake/Nix expression, so the launcher is pinned as an AppImage.
			# Switch to `pkgs.xodus-nexus` (or a flake input) when either is
			# available. Tracked in the "Pending upstream fixes" registry
			# (AGENTS.md row 8 / README).
			version = "0.3.11";
			src = pkgs.fetchurl {
				url = "https://github.com/domsvoboda/xodus-nexus/releases/download/v${version}/Xodus-Nexus-${version}-x86_64.AppImage";
				hash = "sha256-r1hpK/5dFTDui8/o7hIGCKLqcZ5FzZN4jk4m9MudvgM=";
			};
			appimageContents = pkgs.appimageTools.extract {
				pname = "xodus-nexus";
				inherit version src;
			};
			xodusNexus = pkgs.appimageTools.wrapType2 {
				pname = "xodus-nexus";
				inherit version src;

				# Electron needs the stock AppImage wrappers; the extra WebKitGTK
				# stack is for the separately-launched Xodus backend, whose
				# sign-in window is a WebKit webview. glib-networking supplies the
				# GIO TLS backend that webview needs.
				extraPkgs = p: with p; [
					webkitgtk_4_1
					libsoup_3
					glib-networking
				];

				nativeBuildInputs = [ pkgs.makeWrapper ];

				extraInstallCommands = ''
					install -m 444 -D ${appimageContents}/xodus-nexus.desktop \
						$out/share/applications/xodus-nexus.desktop
					install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/xodus-nexus.png \
						$out/share/icons/hicolor/512x512/apps/xodus-nexus.png
					substituteInPlace $out/share/applications/xodus-nexus.desktop \
						--replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=xodus-nexus %U'
					wrapProgram $out/bin/xodus-nexus \
						--add-flags --no-sandbox \
						--set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
						--set-default SSL_CERT_DIR ${pkgs.cacert}/etc/ssl/certs \
						--prefix GIO_EXTRA_MODULES : "${pkgs.glib-networking}/lib/gio/modules"
				'';

				meta = {
					description = "Xbox-inspired Microsoft Store and PC Game Pass launcher";
					homepage = "https://github.com/domsvoboda/xodus-nexus";
					license = pkgs.lib.licenses.mit;
					platforms = [ "x86_64-linux" ];
					mainProgram = "xodus-nexus";
				};
			};
		in {
			home.packages = [ xodusNexus ];

			# Provider for Electron's safeStorage and the backend's keyring.
			services.gnome-keyring.enable = true;
		};

	# Xodus Nexus stores the Microsoft sign-in in the system keyring. Hyprland is
	# launched by greetd on the desktop hosts, so unlock the login keyring from
	# the greetd PAM session as well as from login.
	flake.modules.nixos."xodus-nexus" = { ... }: {
		services.gnome.gnome-keyring.enable = true;
		# Keep the existing OpenSSH agent (modules/essentials/ssh.nix); GNOME's
		# gcr-ssh-agent would otherwise conflict with it.
		services.gnome.gcr-ssh-agent.enable = false;
		security.pam.services.greetd.enableGnomeKeyring = true;
	};
}
