{ ... }:
{
	# 3D printing toolchain for the desktop hosts: QIDI Studio as the slicer
	# (a Bambu Studio / PrusaSlicer fork for QIDI printers) plus the modelling
	# suite — FreeCAD and SolveSpace for parametric CAD, OpenSCAD for
	# script-driven solids and Blender for mesh work. All are in nixpkgs.
	flake.modules.homeManager."3d-printing" = { pkgs, ... }: {
		home.packages = with pkgs; [
			qidi-studio # QIDI printer slicer
			freecad # parametric CAD
			solvespace # constraint-based parametric CAD
			openscad # script-based solid modelling
			blender # mesh modelling / sculpting / rendering
		];
	};
}
