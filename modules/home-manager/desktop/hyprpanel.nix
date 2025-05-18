{ config, pkgs, lib, inputs, ... }:
{
  imports = [ 
    inputs.hyprpanel.homeManagerModules.hyprpanel 
  ];

  programs.hyprpanel = {
    enable = true; 
    hyprland.enable = true;
    overwrite.enable = true;
    overlay.enable = true;
    # theme = "Monochrome";
    override = {
      # theme.bar.menus.text = "#123ABC";
    };

    # Configure and theme almost all options from the GUI.
    # Options that require '{}' or '[]' are not yet implemented,
    # except for the layout above.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {
      layout = {
        "bar.layouts" = {
          "*" = {
            left = [ "dashboard" "workspaces" "windowtitle" "media" "cava" ];
            middle = [ "windowtitle" ];
            right = [ "volume" "network" "bluetooth" "cpu" "ram" "battery" "clock" "power" "notifications" ];
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


      };


    };
  };
}
