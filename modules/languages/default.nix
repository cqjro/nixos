{pkgs, ...}:
{
	home.packages = with pkgs; [
		typescript
		go
		texlive.combined.scheme-full
		# texliveFull
		typst
	];

	imports = [
		
	];

}
