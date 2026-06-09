{inputs, ...}:
{
	imports = [
		inputs.xremap-flake.homeManagerModules.default
	];
	services.xremap = {
		enable = true;
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
					super-t.remap.t.launch = ["ghostty"];
					super-o = {
						remap = {
							t.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "ghostty"                                                                                         "com.mitchellh.ghostty"  "1"];
							e.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title"        "ghostty -e nvim"                                                                                 "nvim"                   "1"];
							n.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "obsidian"                                                                                        "obsidian"               "1"];
							z.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "zen-twilight"                                                                                    "zen-twilight"           "2"];
							p.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "proton-mail --ozone-platform-hint=wayland"                                                       "Proton Mail"            "3"];
							v.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland"                  "vesktop"                "4"];
							m.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" 				"ghostty -e ncspot" 																																							"ncspot" 								 "5"];
							y.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title"        "ghostty -e yazi"                                                                                 "yazi"                   "6"];
							b.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title"        "ghostty -e btop"                                                                                 "btop"                   "7"];
							s.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" 				"steam"             																																							"steam"  								 "8"];
							f.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class"        "nemo"                                                                                            "nemo"                   ""];
						};
					};
					super-r = {
						remap = {
							o.launch = ["rofi" "-show" "drun" "-show-icons"];
							f.launch = ["rofi" "-show" "file-browser-extended" "~/"];
							c.launch = ["rofi" "-show" "calc" "-modi" "calc" "-no-show-match" "-no-sort" "-calc-command" "'echo -n '{result}' | xclip'"];
							n.launch = ["rofi-network-manager"];
							p.launch = ["rofi" "-show" "power-menu" "-modi" "power-menu:rofi-power-menu"];
							b.launch = ["rofi-bluetooth"];
						};
					};
				};
			}
			];
		};
	};
}
