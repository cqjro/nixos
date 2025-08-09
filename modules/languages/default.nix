{pkgs, ...}:
{
	home.packages = with pkgs; [
		typescript
		go
		rust
		texlive.combined.scheme-full
		typst
	];

	imports = [
		
	];

}
