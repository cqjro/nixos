{ inputs, ... }:
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
# Terminal apps
							t.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "ghostty" "com.mitchellh.ghostty" "1"];
							e.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e nvim" "nvim" "1"];

# Core applications
							n.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "obsidian" "obsidian" "1"];
							z.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "zen-twilight" "zen-twilight" "2"];
							p.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "proton-mail --ozone-platform-hint=wayland" "Proton Mail" "3"];
							v.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland" "vesktop" "4"];

# Terminal utilities
							m.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e ncspot" "ncspot" "5"];
							y.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e yazi" "yazi" "6"];
							b.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e btop" "btop" "7"];

# Gaming & Files
							s.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "steam" "steam" "8"];
							f.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "nemo" "nemo" ""];
						};
					};

# Media Controls - Super+M
					super-m = {
						remap = {
							j.launch = ["noctalia" "msg" "media" "previous"];
							k.launch = ["noctalia" "msg" "media" "next"];
							l.launch = ["noctalia" "msg" "media" "playPause"];
							u.launch = ["noctalia" "msg" "media" "toggle"];
						};
					};

# Volume Controls - Super+V (Verified: volume-up/down/mute/osd)
					super-v = {
						remap = {
							j.launch = ["noctalia" "msg" "volume-down"];
							k.launch = ["noctalia" "msg" "volume-up"];
							l.launch = ["noctalia" "msg" "volume-mute"];
							u.launch = ["noctalia" "msg" "volume-osd"];
						};
					};

# Brightness Controls - Super+B (Verified: brightness-up/down/osd)
					super-b = {
						remap = {
							j.launch = ["noctalia" "msg" "brightness-down"];
							k.launch = ["noctalia" "msg" "brightness-up"];
							u.launch = ["noctalia" "msg" "brightness-osd"];
						};
					};

# System Controls - Super+R (Verified from help output)
					super-r = {
						remap = {
							o.launch = ["noctalia" "msg" "panel-toggle" "launcher"];
							f.launch = ["noctalia" "msg" "plugin" "noctalia/file-launcher" "" "toggle"];
							c.launch = ["noctalia" "msg" "panel-toggle" "calculator"];
							n.launch = ["noctalia" "msg" "network-toggle"];
							p.launch = ["noctalia" "msg" "power-cycle"];
							b.launch = ["noctalia" "msg" "bluetooth-toggle"];
							v.launch = ["noctalia" "msg" "notification-dnd-toggle"];
							k.launch = ["noctalia" "msg" "caffeine-toggle"];
							l.launch = ["noctalia" "msg" "nightlight-force-toggle"];
							w.launch = ["noctalia" "msg" "dock-toggle"];
						};
					};

# Lock/Session Controls - Super+L (Verified: session <action>, dpms)
					super-l = {
						remap = {
							l.launch = ["noctalia" "msg" "session" "lock"];
							s.launch = ["noctalia" "msg" "session" "suspend"];
							h.launch = ["noctalia" "msg" "dpms-off"];
							r.launch = ["noctalia" "msg" "session" "reboot"];
						};
					};

# Panel Shortcuts - Super+A (Additional panels)
					super-a = {
						remap = {
							l.launch = ["noctalia" "msg" "panel-toggle" "launcher"];
							c.launch = ["noctalia" "msg" "panel-toggle" "control-center"];
							a.launch = ["noctalia" "msg" "panel-toggle" "control-center" "audio"];
							b.launch = ["noctalia" "msg" "panel-toggle" "control-center" "bluetooth"];
							n.launch = ["noctalia" "msg" "panel-toggle" "control-center" "network"];
							s.launch = ["noctalia" "msg" "settings-toggle"];
							t.launch = ["noctalia" "msg" "theme-mode-toggle"];
						};
					};

# Dock/Widgets - Super+D
					super-d = {
						remap = {
							d.launch = ["noctalia" "msg" "dock-toggle"];
							h.launch = ["noctalia" "msg" "desktop-widgets-hide"];
							s.launch = ["noctalia" "msg" "desktop-widgets-show"];
							w.launch = ["noctalia" "msg" "desktop-widgets-toggle"];
							e.launch = ["noctalia" "msg" "desktop-widgets-toggle-edit"];
						};
					};

# Screenshots - Super+S (with shift)
					super-s = {
						remap = {
							f.launch = ["noctalia" "msg" "screenshot-fullscreen"];
							r.launch = ["noctalia" "msg" "screenshot-region"];
							w.launch = ["noctalia" "msg" "window-switcher"];
						};
					};
				};
			}
			];
		};
	};
}
