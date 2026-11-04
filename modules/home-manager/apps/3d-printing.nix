{ ... }:
{
	# 3D printing toolchain for the desktop hosts: QIDI Studio as the slicer
	# (a Bambu Studio / PrusaSlicer fork for QIDI printers) plus the modelling
	# suite — FreeCAD and SolveSpace for parametric CAD, OpenSCAD for
	# script-driven solids and Blender for mesh work. All are in nixpkgs.
	flake.modules.homeManager."3d-printing" = { pkgs, ... }:
		let
			# TODO-remove: nixpkgs' qidi-studio builds its AppImage FHS env with
			# `extraPkgs = [ webkitgtk_4_1 ]` only (see
			# pkgs/by-name/qi/qidi-studio/package.nix). The AppImage bundles only
			# its ffmpeg libs, so it needs the FHS env for everything else, and
			# three gaps bite:
			#   1. webkitgtk_4_1's runtime deps (libsoup_3, libpng) are not pulled
			#      in, so the binary dies with
			#      "libsoup-3.0.so.0: cannot open shared object file".
			#   2. the env has no CA bundle at the Fedora path the app probes
			#      (/etc/pki/tls/certs/ca-bundle.crt), so it nags about the system
			#      certificate store — pin SSL_CERT_FILE/SSL_CERT_DIR at cacert.
			#   3. the env lacks glib-networking's GIO TLS backend, so every
			#      web view says "TLS support not available" — add glib-networking
			#      and point GIO_EXTRA_MODULES at it (same fix as nixpkgs #528942,
			#      the QBZ package).
			# Re-wrap with the same extraPkgs set the sibling package
			# qidi-slicer-bin uses, until upstream adds them.
			#
			# TODO-remove: QIDIStudio hardcodes a webview User-Agent without any
			# browser token (src/slic3r/GUI/Widgets/WebView.cpp, the non-Windows
			# branch), so the login / online-model pages can't sniff a browser to
			# set the X-DeviceType header and api.qidimaker.com rejects them with
			# "X-DeviceType missing in request header". Windows works because its
			# UA carries "Chrome/... Safari/...". patch-qidi-studio-ua.py rewrites
			# the literal in place (same length) to the Safari UA the issue
			# validated, so the page sends "X-DeviceType: safari 17.4" and the
			# gateway accepts it. It must NOT advertise Chrome: the webview is
			# WebKitGTK, and the qidimaker SPA then takes Chrome-only code paths
			# it cannot run, rendering the pages blank. See
			# QIDITECH/QIDIStudio#244.
			# Both workarounds are tracked in the "Pending upstream fixes"
			# registry (docs/agents/upstream-registry.md rows 2 and 3 / README).
			appimageContents = pkgs.appimageTools.extract {
				inherit (pkgs.qidi-studio) pname version src;
				postExtract = ''
					chmod u+w $out/bin/qidi-studio
					${pkgs.python3}/bin/python3 ${../../scripts/patch-qidi-studio-ua.py} $out/bin/qidi-studio
				'';
			};
			qidiStudio = pkgs.appimageTools.wrapAppImage {
				pname = pkgs.qidi-studio.pname;
				version = pkgs.qidi-studio.version;
				contents = appimageContents;
				extraPkgs = p: [ p.webkitgtk_4_1 p.libsoup_3 p.libpng p.glib-networking ];
				nativeBuildInputs = [ pkgs.makeWrapper ];
				extraInstallCommands = ''
					install -m 444 -D ${appimageContents}/QIDIStudio.desktop $out/share/applications/QIDIStudio.desktop
					install -m 444 -D ${appimageContents}/QIDIStudio.png \
						$out/share/icons/hicolor/scalable/apps/QIDIStudio.png
					substituteInPlace $out/share/applications/QIDIStudio.desktop \
						--replace-fail 'Exec=AppRun' 'Exec=qidi-studio'
					wrapProgram "$out/bin/qidi-studio" \
						--set-default WEBKIT_DISABLE_COMPOSITING_MODE 0 \
						--set-default WEBKIT_DISABLE_DMABUF_RENDERER 0 \
						--set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
						--set-default SSL_CERT_DIR ${pkgs.cacert}/etc/ssl/certs \
						--prefix GIO_EXTRA_MODULES : "${pkgs.glib-networking}/lib/gio/modules"
				'';
			};
		in {
			home.packages = with pkgs; [
				qidiStudio # QIDI printer slicer (patched FHS env + UA)
				freecad # parametric CAD
				solvespace # constraint-based parametric CAD
				openscad # script-based solid modelling
				blender # mesh modelling / sculpting / rendering
			];
		};
}
