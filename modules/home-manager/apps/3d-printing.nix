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
			# its ffmpeg libs, so it needs the FHS env for everything else, but
			# webkitgtk_4_1's runtime deps (libsoup_3, libpng) are not pulled in
			# and the binary dies with
			# "libsoup-3.0.so.0: cannot open shared object file". Re-wrap with the
			# same extraPkgs set the sibling package qidi-slicer-bin uses, until
			# upstream adds them. Tracked in the "Pending upstream fixes" registry
			# (AGENTS.md row 4 / README).
			appimageContents = pkgs.appimageTools.extract {
				inherit (pkgs.qidi-studio) pname version src;
			};
			qidiStudio = pkgs.appimageTools.wrapType2 {
				inherit (pkgs.qidi-studio) pname version src;
				extraPkgs = p: [ p.webkitgtk_4_1 p.libsoup_3 p.libpng ];
				nativeBuildInputs = [ pkgs.makeWrapper ];
				extraInstallCommands = ''
					install -m 444 -D ${appimageContents}/QIDIStudio.desktop $out/share/applications/QIDIStudio.desktop
					install -m 444 -D ${appimageContents}/QIDIStudio.png \
						$out/share/icons/hicolor/scalable/apps/QIDIStudio.png
					substituteInPlace $out/share/applications/QIDIStudio.desktop \
						--replace-fail 'Exec=AppRun' 'Exec=qidi-studio'
					wrapProgram "$out/bin/qidi-studio" \
						--set-default WEBKIT_DISABLE_COMPOSITING_MODE 0 \
						--set-default WEBKIT_DISABLE_DMABUF_RENDERER 0
				'';
			};
		in {
			home.packages = with pkgs; [
				qidiStudio # QIDI printer slicer (patched FHS env)
				freecad # parametric CAD
				solvespace # constraint-based parametric CAD
				openscad # script-based solid modelling
				blender # mesh modelling / sculpting / rendering
			];
		};
}
