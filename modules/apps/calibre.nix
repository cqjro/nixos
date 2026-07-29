{ pkgs, ... }:
{
	home.packages = with pkgs; [
		(calibre.override {
			unrarSupport = true;
		})
	];
}
