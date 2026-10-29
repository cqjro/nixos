{ ... }:
{
	flake.modules.homeManager."claude-code" = { pkgs, ... }: {
		home.packages = with pkgs; [
			claude-code
		];
	};
}
