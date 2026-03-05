{pkgs, ...}:
{
	home.packages = with pkgs; [
		git
		delta
	];
	programs.git = {
		enable = true;
		settings = {
			user = {
				name = "cqjro";
				email = "github@cqjro.ca";
			};
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
