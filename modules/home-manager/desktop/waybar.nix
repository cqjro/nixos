# Stole this from Simple Hyprland
{ pkgs, lib, config, inputs, ... }: {
	programs.waybar = {
		enable = true;
		# style = ./style.css;
		settings = [
			{
				margin-top = 10;
				margin-left = 10;
				margin-right = 10;
				layer = "top";
				position = "top";

				modules-left = [
					"custom/start"
					"clock"
					"mpris"
					"hyprland/workspaces"
				];
				modules-center = [
					"hyprland/window"
				];
				modules-right = [
					# "tray"
					"cpu"
					"memory"
					"disk"
					"network"
					"bluetooth"
					"battery"
					"backlight"
					"pulseaudio"
					#"pulseaudio#microphone"
				];

				"cpu" = {
					states = {
						critical = 85;
					};
					interval = 1;
					format = " {usage}%";
					format-alt = "{icon0}{icon1}{icon2}{icon3}";
					format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
					on-click = "ghostty -e btop";
				};

				"memory" = {
					states = {
						c = 90; # critical
						h = 60; # high
						m = 30; # medium
					};
					interval = 1;
					format = " {percentage}%";
					on-click = "ghostty -e btop";
					tooltip = true;
					tooltip-format = "󰾆 {percentage}%\n {used:0.1f}GB/{total:0.1f}GB";
				};

				"disk" = {
					states = {
						critical = 85;
					};
					interval = 5;
					format = " {percentage_used}%";
					on-click = "ghostty -e btop";
				};

				"network" = {
					# format-ethernet = " {bandwidthDownOctets}";
					format-ethernet = " Ethernet"; 
					format-wifi = " {essid}";
					format-disconnected = "󰖪 ";
					tooltip-format-disconneted = "Disconnected";
					format-disabled = "󰖪 ";
					format-linked = " {ifname} (No IP)";
					tooltip = true;
					tooltip-format =  "Network: <big><b>{essid}</b></big>\nSignal strength: <b>{signaldBm}dBm ({signalStrength}%)</b>\nFrequency: <b>{frequency}MHz</b>\nInterface: <b>{ifname}</b>\nIP: <b>{ipaddr}/{cidr}</b>\nGateway: <b>{gwaddr}</b>\nNetmask: <b>{netmask}</b>";
					format-alt =  "<span foreground='#99ffdd'> {bandwidthDownBytes}</span> <span foreground='#ffcc66'> {bandwidthUpBytes}</span>";
					on-click = "rofi-network-manager";
					interval = 2;
				};

				"temperature" = {
					critical-threshold = 80;
					format = " {temperatureC}°C";
					interval = 1;
					on-click = "ghostty -e btop";
				};

				"power-profiles-daemon" = {
					format = "{icon} {profile}";
					format-icons = {
						performance = "";
						power-saver = "";
						balanced = "";
					};
				};

				"hyprland/workspaces" = {
					format = "{name}";
					format-icons = {
						default = " ";
						active = " ";
						urgent = " ";
					};
					on-click = "activate";
					all-outputs = true;
					disable_scroll = true;
					# on-scroll-down = "hyprctl dispatch workspace e+1";
					# on-scroll-up = "hyprctl dispatch workspace e-1";
				};

				"hyprland/window" = {
					icon = true;
					max-length = 45;
					separate-outputs = false;
					# rewrite = {
					# "" = "${username}@${hostname}";
					# "~" = "${username}@${hostname}";
					# };
					on-click-right = "hyprctl dispatch fullscreen 0";
					on-click-middle = "hyprctl dispatch killactive";
					on-click = "hyprctl dispatch fullscreen 1";
				};

				"clock" = {
					# format = "{:%A    %B-%d-%Y    %I:%M:%S %p}";
					format = " {:%B-%d-%Y   %I:%M:%S %p}";

					interval = 1;
					rotate = 0;
					tooltip-format = "<tt>{calendar}</tt>";
					calendar = {
						mode = "month";
						mode-mon-col = 3;
						on-scroll = 1;
						on-click-right = "mode";
						format = {
							month = "<span color='#a6adc8'><b>{}</b></span>";
							weekdays = "<span color='#a6adc8'><b>{}</b></span>";
							today =  "<span color='#a6adc8'><b>{}</b></span>";
							days =  "<span color='#555869'><b>{}</b></span>";
						};
					};
				};

				"backlight" = {
					device = "apci_video0";
					format = "{icon} {percent}%";
					format-icons =  ["󰃞" "󰃟" "󰃠"];
					on-scroll-up = "brightnessctl set 1%+";
					on-scroll-down = "brightnessctl set 1%-";
					min-length = 6;
				};

				"tray" = {
					icon-size = 13;
					spacing = 10;
				};

				"taskbar" = {
					icon-size = 10;
					icon-theme = "Papirus-Dark";
					on-click = "activate";
					on-click-right = "fullscreen";
					on-click-middle = "close";
					on-scroll-up = "maximize";
					on-scroll-down = "minimize";
				};

				"pulseaudio" = {
					tooltip = false;
					format = "{icon} {volume}%";
					format-bluetooth = " {icon} {volume}%";
					format-bluetooth-muted = " {icon} {volume}%";
					format-muted = "  {volume}%";
					format-source = "";
					format-source-muted = "";
					format-icons = {
						headphone = "";
						hands-free = "";
						headset = "";
						phone = "";
						portable = "";
						car = "";
						default =  ["" "" "" ""];
					};
					on-click = "pavucontrol";
					on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
				};

				"pulseaudio#microphone" = {
					format = "{format_source}";
					format-source =  "{volume}%";
					format-source-muted =  " Muted";
				};

				"battery" = {
					states = {
						good = 95;
						warning = 30;
						critical = 15;
					};
					format = "{icon} {capacity}%";
					format-charging = " {capacity}%";
					format-plugged = " {capacity}%";
					format-alt = "{time} {icon}";
					format-icons =  ["󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
					interval = 1;
					on-click = "";
				};

				"custom/start" = {
					format = "{icon}";
					format-icons = ["󱄅"];
					on-click = "rofi -show power-menu -modi power-menu:rofi-power-menu";
				};

				"bluetooth" = {
					# "controller": "controller1", // specify the alias of the controller if there are more than 1 on the system
					format = " {status}";
					format-disabled =""; # an empty format will hide the module
					format-connected = "{num_connections}";
					# format-connected = " {device_alias}";
					max-length = 20;
					tooltip-format = "{controller_alias}\t{controller_address}";
					tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
					tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
					on-click = "rofi-bluetooth";
				};

				"mpris" = {
					format = "{player_icon} {artist} - {title}";
					format-paused = "{status_icon} {artist} - {title}";
					max-length = 45;
					interval = 1;
					player-icons = {
						default = "";
						mpv= "";
					};
					status-icons = {
						paused = "󰏤";
					};
					ignored-players = ["firefox"];
				};


			}
		];
		style = ''
		* {
				border: none;
				border-radius: 0;
				font-family: JetBrainsMono Nerd Font, monospace;
				font-weight: bold;
				font-size: 15px;
				min-height: 0;
		}

		window#waybar {
				background: rgba(21, 18, 27, 0);
				color: #cdd6f4;
		}

		#workspaces button {
				padding: 5px;
				color: #${config.lib.stylix.colors.base03};
				margin-right: 5px;
		}

		#workspaces button.active {
				color: #${config.lib.stylix.colors.base05};
		}

		#workspaces button.focused {
				color: #${config.lib.stylix.colors.base05};
				border-radius: 10px;
		}

		#workspaces button.urgent {
				/* color: #11111b; */
				/* background: #a6e3a1; */
				border-radius: 10px;
		}

		#workspaces button:hover {
				background: #${config.lib.stylix.colors.base00};  
				color: #${config.lib.stylix.colors.base05}; 
	text-decoration: underline;
		}

		#window,
		#clock,
		#battery,
		#pulseaudio,
		#network,
		#cpu,
		#memory,
		#workspaces,
		#tray,
		#backlight,
		#custom-start,
		#bluetooth,
		#mpris,
		#disk {
				background: #${config.lib.stylix.colors.base00};
				color: #${config.lib.stylix.colors.base05};
				padding: 0px 10px;
				margin: 3px 0px;
				margin-top: 5px;
				/* border: 1px solid #181825; */
		}

		#backlight {
				border-radius: 10px 0px 0px 10px;
		}

		#tray {
				border-radius: 10px;
				margin-right: 10px;
		}

		#custom-start {
				border-radius: 10px;
				margin-left: 5px;
				padding-right: 15px;
				padding-left: 10px;
				font-size: 20px;
		}

		#workspaces {
				border-radius: 10px;
				margin-left: 10px;
				padding-right: 0px;
				padding-left: 5px;
		}

		#mpris {
			 border-radius: 10px;
			 margin-left: 10px;
		}

		#disk {
				margin-right: 10px;
				border-radius: 0px 10px 10px 0px;
		}

		#memory {
				border-radius: 0px 0px 0px 0px;
		}

		#cpu {
				border-radius: 10px 0px 0px 10px;
		}

		#window {
				border-radius: 10px;
				margin-left: 60px;
				margin-right: 60px;
		}

		#clock {
				border-radius: 10px 10px 10px 10px;
				margin-left: 10px;
				border-right: 0px;
		}

		#network {
				border-radius: 10px 0px 0px 10px;
		}

		#bluetooth {
			 border-left: 0px;
			 border-right: 0px;
		}

		#pulseaudio {
				border-left: 0px;
				border-right: 0px;
				border-radius: 0px 10px 10px 0px;
				margin-right: 5px;
		}

		#pulseaudio.microphone {
				border-radius: 0px 10px 10px 0px;
				border-left: 0px;
				border-right: 0px;
				margin-right: 5px;
		}

		#battery {
				border-radius: 0px 10px 10px 0px;
				margin-right: 10px;
		}
		'';
	};
}
