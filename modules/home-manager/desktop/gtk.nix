{pkgs, ...}:
{
	gtk = {
		enable = true;
		iconTheme = {
			name = "GruvboxPlus";
			package = pkgs.gruvbox-plus-icons;
		};
	};
}
