{ ... }:
{
	flake.modules.homeManager."t3code" = { pkgs, ... }: {
		home.packages = with pkgs; [
			t3code
		];
	};
}
