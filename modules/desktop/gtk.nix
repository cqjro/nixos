{pkgs, ...}:
{
	gtk = {
		enable = true;
		iconTheme = {
			name = "Gruvbox-Plus-Dark";
			package = pkgs.gruvbox-plus-icons;
		};

		gtk4.theme = null; # new default behaviour?

		# cursorTheme = {
		# 	name = "Rose Pine";
		# 	package = pkgs.rose-pine-cursor;
		# };

	};
}
