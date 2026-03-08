{pkgs, ...}:
{
	home.packages = with pkgs; [
		elephant
		walker
	];

	services.walker = {
		enable = true;
		# package = pkgs.walker;
	};
}
