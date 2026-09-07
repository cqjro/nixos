{ ... }:
{
	flake.modules.homeManager."zoxide" = { pkgs, ... }: {
		home.packages = with pkgs; [
			zoxide
		];

		programs.zoxide = {
			enable = true;
			enableZshIntegration = true;
		};
	};
}