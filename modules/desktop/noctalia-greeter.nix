{ inputs, pkgs, ...}:
{
	imports = [
		inputs.noctalia-greeter.nixosModules.default
	];

	programs.noctalia-greeter = {
		enable = true;

		greeter-args = "--session hyprland";

		settings = {
			cursor = {
				theme = "rose-pine-cursor";
				size = 27;
				path = "${pkgs.rose-pine-cursor}/share/icons";
			};	

			keyboard = {
				layout = "us";
			};

		};

	};
	
}
