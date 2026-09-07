{ ... }:
{
	flake.modules.homeManager."languages-packages" = { pkgs, ... }: {
		home.packages = with pkgs; [
			typescript
			go
			typst
		];
	};
}