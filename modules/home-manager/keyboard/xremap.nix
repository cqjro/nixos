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
					name = "Program Workflow Remaps";
					remap = {
						super-t.remap.t.launch = ["ghostty"]; # want to open terminal fast
						super-o = { # open
							remap = {
								z.launch = ["bash" "~/.nixos/modules/scripts/focus.sh" "zen" "zen-beta" "2"];
								t.launch = ["ghostty"];
								# d.launch = ["vesktop"];
								d.launch = ["bash" "~/.nixos/modules/scripts/focus.sh" "vesktop --ozone-platform-hint=wayland" "vesktop" "3"];
								s.launch = ["ghostty" "-e" "ncspot"];
								y.launch = ["ghostty" "-e" "yazi"];
								b.launch = ["ghostty" "-e" "btop"];
								e.launch = ["ghostty" "-e" "nvim"];
								n.launch = ["obsidian"];
							};
						};
						super-r = { #rofi
							remap = {
								o.launch = ["rofi" "-show" "drun" "-show-icons"]; # open apps	
								f.launch = ["rofi" "-show" "file-browser-extended" "~/"]; # files - need to change to fuzzy finder
								c.launch = ["rofi" "-show" "calc" "-modi" "calc" "-no-show-match" "-no-sort" "-calc-command" "'echo -n '{result}' | xclip'"]; # calc	
								n.launch = ["rofi-network-manager"]; # network manager
								p.launch = ["rofi" "-show" "power-menu" "-modi" "power-menu:rofi-power-menu"]; # power menu
								b.launch = ["rofi-bluetooth"]; # bluetooth menu
							};
						};
					};
				}
			];
		};
	};
}

