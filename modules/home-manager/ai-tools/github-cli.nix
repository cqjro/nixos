{ ... }:
{
	flake.modules.homeManager."github-cli" = { pkgs, ... }: {
		home.packages = with pkgs; [
			gh
			git
		];

		programs.gh = {
			enable = true;
			settings = {
				git_protocol = "ssh";
			};
		};
	};
}
