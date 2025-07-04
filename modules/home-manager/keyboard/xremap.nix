{inputs, ...}:
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
						super-o = { # focus app and open if not already open.
							remap = {	
								t.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-class.sh" "ghostty" "com.mitchellh.ghostty" "1"];
								z.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-initialtitle.sh" "zen" "Zen Browser" "2"];
								v.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-class.sh" "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland" "vesktop" "3"];
								s.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-name.sh" "ghostty -e ncspot" "ncspot" "4"];
								y.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-name.sh" "ghostty -e yazi" "yazi" "5"];
								b.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-name.sh" "ghostty -e btop" "" "6"]; # this doesn't have a window name
								e.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-name.sh" "ghostty -e nvim" "nvim" "1"];
								n.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-class.sh" "obsidian" "1"];
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

