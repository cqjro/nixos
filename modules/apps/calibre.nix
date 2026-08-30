{ pkgs, ... }:
{
	home.packages = with pkgs; [
		(calibre.override {
			unrarSupport = false;
		})
	];
}
