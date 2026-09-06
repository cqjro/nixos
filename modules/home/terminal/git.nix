{ ... }:
{
	flake.modules.homeManager."git" = { pkgs, ... }: {
		home.packages = with pkgs; [
			git
			delta
		];
		programs.git = {
			enable = true;

			signing = {
				format = "ssh";
			};

			settings = {
				user = {
					name = "cqjro";
					email = "108373187+cqjro@users.noreply.github.com";
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
	};
}