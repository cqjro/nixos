{ ... }:
{
	flake.modules.homeManager."bat" = { pkgs, ... }: {
		home.packages = with pkgs; [
			bat
		];
		programs.bat = {
			enable = true;
		};
	};
}