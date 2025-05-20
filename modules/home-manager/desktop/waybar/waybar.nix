# Stole this from https://github.com/SX-9/nix-conf/blob/master/rice/waybar.nix
{ pkgs, lib, inputs, ... }: {
  programs.waybar = {
    enable = true;
    style = ./style.css;
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
	  "battery"
          "backlight"
          "pulseaudio"
	  "pulseaudio#microphone"
        ];

        "cpu" = {
          states = {
            critical = 85;
          };
          interval = 1;
          format = " {usage}%";
	  format-alt = "{icon0}{icon1}{icon2}{icon3}";
	  format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
          on-click = "ghostty btop";
        };

        "memory" = {
          states = {
            c = 90; # critical
            h = 60; # high
	    m = 30; # medium
          };
          interval = 1;
          format = " {percentage}%";
          on-click = "ghostty btop";
	  max-length = 10;
	  tooltip = true;
	  tooltip-format = "󰾆 {percentage}%\n {used:0.1f}GB/{total:0.1f}GB";
        };

        "disk" = {
          states = {
            critical = 85;
          };
          interval = 5;
          format = " {percentage_used}%";
          on-click = "ghostty btop";
        };

        "network" = {
          format-ethernet = " {bandwidthDownOctets}";
          format-wifi = " {essid}%";
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
          on-click = "ghostty btop";
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
          format = "{:%A    %B-%d-%Y    %I:%M:%S %p}";
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
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {volume}% {format_source_muted}";
          format-muted = " {volume}% {format_source_muted}";
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
	  format-source =  " {volume}%";
	  format-source-muted =  "  Muted";
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
      }
    ];
  };
}
