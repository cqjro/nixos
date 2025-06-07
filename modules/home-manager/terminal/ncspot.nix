{pkgs, lib, config, inputs, ...}:
{
	programs.ncspot = {
		enable = true;
		settings = {
			use_nerdfont = true;
			notify = true;
			gapless = true;
			default_keybindings = true;
			keybindings = {
				"1" = "focus queue";
				"2" = "focus library";
				"3" = "focus search";
			};
		};
	};
}
