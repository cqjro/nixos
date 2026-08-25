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
					super-t.remap.t.launch = ["ghostty"]; # Open a new terminal
					super-o = {
						remap = {
# Terminal apps
							t.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "ghostty" "com.mitchellh.ghostty" "1"]; # Focus or launch terminal
							e.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e nvim" "nvim" "1"]; # Focus or launch Neovim

# Core applications
							n.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "obsidian" "obsidian" "1"]; # Focus or launch Obsidian
							z.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "zen-twilight" "zen-twilight" "2"]; # Focus or launch Zen browser
							p.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "proton-mail --ozone-platform-hint=wayland" "Proton Mail" "3"]; # Focus or launch Proton Mail
							v.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland" "vesktop" "4"]; # Focus or launch Discord (Vesktop)

# Terminal utilities
							m.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e ncspot" "ncspot" "5"]; # Focus or launch ncspot (Spotify TUI)
							y.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e yazi" "yazi" "6"]; # Focus or launch Yazi file manager
							b.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "title" "ghostty -e btop" "btop" "7"]; # Focus or launch btop system monitor

# Gaming & Files
							s.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "steam" "steam" "8"]; # Focus or launch Steam
							f.launch = ["bash" "/home/cairo/.nixos/modules/scripts/focus-window.sh" "--by" "class" "nemo" "nemo" ""]; # Focus or launch Nemo file manager
						};
					};

# Media Controls - Super+M
					super-m = {
						remap = {
							j.launch = ["noctalia" "msg" "media" "previous"]; # Previous track
							k.launch = ["noctalia" "msg" "media" "next"]; # Next track
							l.launch = ["noctalia" "msg" "media" "playPause"]; # Play/pause media
							u.launch = ["noctalia" "msg" "media" "toggle"]; # Toggle media player
						};
					};

# Volume Controls - Super+V (Verified: volume-up/down/mute/osd)
					super-v = {
						remap = {
							j.launch = ["noctalia" "msg" "volume-down"]; # Decrease volume
							k.launch = ["noctalia" "msg" "volume-up"]; # Increase volume
							l.launch = ["noctalia" "msg" "volume-mute"]; # Mute/unmute volume
							u.launch = ["noctalia" "msg" "volume-osd"]; # Show volume OSD
						};
					};

# Brightness Controls - Super+B (Verified: brightness-up/down/osd)
					super-b = {
						remap = {
							j.launch = ["noctalia" "msg" "brightness-down"]; # Decrease brightness
							k.launch = ["noctalia" "msg" "brightness-up"]; # Increase brightness
							u.launch = ["noctalia" "msg" "brightness-osd"]; # Show brightness OSD
						};
					};

# System Controls - Super+R (Verified from help output)
					super-r = {
						remap = {
							o.launch = ["noctalia" "msg" "panel-toggle" "launcher"]; # Toggle app launcher
							f.launch = ["noctalia" "msg" "settings-open-plugin" "nightwatch75/file-search"]; # Open file search plugin
							c.launch = ["noctalia" "msg" "panel-toggle" "calculator"]; # Toggle calculator panel
							n.launch = ["noctalia" "msg" "network-toggle"]; # Toggle network
							p.launch = ["noctalia" "msg" "power-cycle"]; # Open power menu
							b.launch = ["noctalia" "msg" "bluetooth-toggle"]; # Toggle Bluetooth
							v.launch = ["noctalia" "msg" "notification-dnd-toggle"]; # Toggle do-not-disturb
							k.launch = ["noctalia" "msg" "caffeine-toggle"]; # Toggle caffeine (prevent sleep)
							l.launch = ["noctalia" "msg" "nightlight-force-toggle"]; # Toggle night light
							w.launch = ["noctalia" "msg" "dock-toggle"]; # Toggle dock
						};
					};

# Lock/Session Controls - Super+L (Verified: session <action>, dpms)
					super-l = {
						remap = {
							l.launch = ["noctalia" "msg" "session" "lock"]; # Lock session
							s.launch = ["noctalia" "msg" "session" "suspend"]; # Suspend system
							h.launch = ["noctalia" "msg" "dpms-off"]; # Turn off display (DPMS)
							r.launch = ["noctalia" "msg" "session" "reboot"]; # Reboot system
						};
					};

# Panel Shortcuts - Super+A (Additional panels)
					super-a = {
						remap = {
							l.launch = ["noctalia" "msg" "panel-toggle" "launcher"]; # Toggle app launcher
							c.launch = ["noctalia" "msg" "panel-toggle" "control-center"]; # Toggle control center
							a.launch = ["noctalia" "msg" "panel-toggle" "control-center" "audio"]; # Open control center: audio tab
							b.launch = ["noctalia" "msg" "panel-toggle" "control-center" "bluetooth"]; # Open control center: Bluetooth tab
							n.launch = ["noctalia" "msg" "panel-toggle" "control-center" "network"]; # Open control center: network tab
							s.launch = ["noctalia" "msg" "settings-toggle"]; # Toggle settings panel
							t.launch = ["noctalia" "msg" "theme-mode-toggle"]; # Toggle light/dark theme
						};
					};

# Dock/Widgets - Super+D
					super-d = {
						remap = {
							d.launch = ["noctalia" "msg" "dock-toggle"]; # Toggle dock
							h.launch = ["noctalia" "msg" "desktop-widgets-hide"]; # Hide desktop widgets
							s.launch = ["noctalia" "msg" "desktop-widgets-show"]; # Show desktop widgets
							w.launch = ["noctalia" "msg" "desktop-widgets-toggle"]; # Toggle desktop widgets
							e.launch = ["noctalia" "msg" "desktop-widgets-toggle-edit"]; # Toggle desktop widgets edit mode
						};
					};

# Screenshots - Super+S (with shift)
					super-s = {
						remap = {
							f.launch = ["noctalia" "msg" "screenshot-fullscreen"]; # Screenshot full screen
							r.launch = ["noctalia" "msg" "screenshot-region"]; # Screenshot selected region
							w.launch = ["noctalia" "msg" "window-switcher"]; # Open window switcher
						};
					};
# Keybind Cheatsheets - Super+K
					super-k = {
						remap = {
							x.launch = ["bash" "~/nixos/modules/scripts/keybind-cheatsheat.sh"];
						};
					};
				};
			}
			];
		};
	};
}

