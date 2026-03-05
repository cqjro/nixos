{pkgs, ...}:
{
	home.packages = with pkgs; [
		typescript
		go
		typst
	];

	imports = [
		# ./latex.nix	
	];

}
