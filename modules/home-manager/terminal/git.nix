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
			};

			merge = {
				conflictstyle = "zdiff3";
			};
		};
	};

}
