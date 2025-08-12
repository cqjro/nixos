{pkgs, ...}:
{
	home.packages = with pkgs; [
		typescript
		go
		rust
		# texlive.combined.scheme-full
		texliveFull
		typst
	];

	imports = [
		
	];

}
