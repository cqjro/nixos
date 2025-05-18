{ config, pkgs, lib, inputs, ... }:
{
  imports = [ 
    inputs.hyprpanel.homeManagerModules.hyprpanel 
  ];

  programs.hyprpanel = {
    enable = false; 
    hyprland.enable = true;
    overwrite.enable = true;

    # Configure and theme almost all options from the GUI.
    # Options that require '{}' or '[]' are not yet implemented,
    # except for the layout above.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {
      layout = {
        "bar.layouts" = {
          "*" = {
            left = [ "dashboard" "cpu" "ram" "cputemp" "storage" "media" ];
            middle = [ "windowtitle" "workspaces" ];
            right = [ "network" "bluetooth" "battery" "clock" "power" "notifications" ];
          };
        };
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = true;

      menus.clock = {
        time = {
          military = false;
          hideSeconds = false;
        };
        weather.unit = "metric";
	weather.location = "Toronto";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = false;

      theme = {
        bar = {
          transparent = true;
	  buttons = {
            radius = "0.7em";
	  };
	};

	font = {
          name = "JetBrainsMono Nerd Font";
	  size = "16px";

	};
        osd = {
          muted_zero = true;
	  location = "bottom";
	};

      };


    };
  };
}
