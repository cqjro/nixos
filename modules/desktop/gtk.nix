{pkgs, ...}:
{
	gtk = {
		enable = true;
		iconTheme = {
			name = "Gruvbox-Plus-Dark";
			package = pkgs.gruvbox-plus-icons;
		};

		# cursorTheme = {
		# 	name = "Rose Pine";
		# 	package = pkgs.rose-pine-cursor;
		# };

	};
}
