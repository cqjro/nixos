{ ... }:
{
	flake.modules.homeManager."yazi" = { pkgs, ... }: {
		home.packages = with pkgs; [
			yazi
		];

		programs.yazi = {
			enable = true;
			shellWrapperName = "y";
		};
	};
}