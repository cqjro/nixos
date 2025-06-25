{pkgs, lib, config, inputs, ...}:
{
	programs.git = {
		enable = true;
		userName  = "cqjro";
		userEmail = "cairo.cristante@gmail.com";

		extraConfig = {
			core = {
				pager = "delta";
			};

			interative = {
				diffFilter = "delta --color-only";
			};

			delta = {
				navigate = true; # use n and N to move between sections
				line-numbers = true;
				hyprlinks = true;
				side-by-side = true;
			};

			merge = {
				conflictstyle = "zdiff3";
			};
		};
	};

}
