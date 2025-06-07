{inputs, pkgs, lib, ...}:
{
	imports = [
		inputs.xremap-flake.homeManagerModules.default
	];
	services.xremap = {
		withHypr = true;
		config = {
			modmap = [
				{
					name = "Remap Caps as Super/Escape";
					remap = {
						CapsLock = {
							held = "Super_L";
							alone = "esc";
							alone_timeout_millis = 150;
						};
					};
				}
			];

			keymap = [
				{
					name = "Opening Programs";
					remap = {
						super-o = {
							remap = {
								z.launch = ["zen"];
								t.launch = ["ghostty"];
								# r.launch = ["rofi"];
								d.launch = ["vesktop"];
								s.launch = ["ghostty" "-e" "ncspot"];
								f.launch = ["ghostty" "-e" "yazi"];
							};
						};	
					};
				}
			];

		};
	};
}

