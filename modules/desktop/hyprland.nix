{ lib, config, ... }:
{
  options = {
    hyprland.enable = lib.mkEnableOption "enables hyprland module";
    hyprland.monitors = lib.mkOption {
      default = [ ",preferred,auto,auto" ];
      type = lib.types.listOf lib.types.str;
    };
    hyprland.bindel = lib.mkOption {
      default = [];
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = true;

      settings = let
        mkLuaInline = lib.generators.mkLuaInline;
        toLua = lib.generators.toLua;
        mkArgs = args: { _args = args; };

        bind = keys: dispatcher: options:
          mkArgs [ keys dispatcher options ];

        dsp = {
          exec_cmd = app: mkLuaInline "hl.dsp.exec_cmd(${toLua { } app})";
          focus = arg: mkLuaInline "hl.dsp.focus(${toLua { } arg})";
          workspace = {
            toggle_special = name: mkLuaInline "hl.dsp.workspace.toggle_special(${toLua { } name})";
          };
          window = {
            close = mkLuaInline "hl.dsp.window.close()";
            kill = mkLuaInline "hl.dsp.window.kill()";
            float = arg: mkLuaInline "hl.dsp.window.float(${toLua { } arg})";
            fullscreen = arg: mkLuaInline "hl.dsp.window.fullscreen(${toLua { } arg})";
            move = arg: mkLuaInline "hl.dsp.window.move(${toLua { } arg})";
            drag = mkLuaInline "hl.dsp.window.drag()";
            resize = mkLuaInline "hl.dsp.window.resize()";
          };
        };

        mainMod = "SUPER";
      in {
        config = {
          general = {
            gaps_in = 5;
            gaps_out = 15;
            border_size = 5;
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            rounding_power = 2;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          animations = {
            enabled = true;
            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];
            animation = [
              "global, 1, 10, default"
              "border, 1, 5.39, easeOutQuint"
              "windows, 1, 4.79, easeOutQuint"
              "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
              "windowsOut, 1, 1.49, linear, popin 87%"
              "fadeIn, 1, 1.73, almostLinear"
              "fadeOut, 1, 1.46, almostLinear"
              "fade, 1, 3.03, quick"
              "layers, 1, 3.81, easeOutQuint"
              "layersIn, 1, 4, easeOutQuint, fade"
              "layersOut, 1, 1.5, linear, fade"
              "fadeLayersIn, 1, 1.79, almostLinear"
              "fadeLayersOut, 1, 1.39, almostLinear"
              "workspaces, 1, 1.94, almostLinear, fade"
              "workspacesIn, 1, 1.21, almostLinear, fade"
              "workspacesOut, 1, 1.94, almostLinear, fade"
            ];
          };

          dwindle = { preserve_split = true; };
          master = { new_status = "master"; };

          misc = {
            force_default_wallpaper = -1;
            disable_hyprland_logo = true;
            focus_on_activate = true;
            disable_splash_rendering = true;
          };

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = true;
              disable_while_typing = true;
              tap_to_click = false;
              scroll_factor = 0.7;
              clickfinger_behavior = true;
            };
          };

          gesture = [{
            button = 3;
            direction = "horizontal";
            workspace_action = "workspace";
          }];

          device = {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          };
        };

        monitor = config.hyprland.monitors;

        env = [
          "XCURSOR_SIZE,27"
          "HYPRCURSOR_SIZE,27"
          "HYPRCURSOR_THEME,rose-pine-hyprcursor"
          "ELECTRON_OZONE_PLATFORM_HINT,wayland"
          "OZONE_PLATFORM_HINT,wayland"
        ];

        bind = lib.flatten [
          # Window control
          (bind "${mainMod} + Q" dsp.window.close { })
          (bind "${mainMod} + M" dsp.window.kill { })
          (bind "${mainMod} + V" (dsp.window.float { action = "toggle"; }) { })
          (bind "${mainMod} + SHIFT + L" (dsp.exec_cmd "hyprlock") { })

          # Screenshots
          (bind "ALT + S" (dsp.exec_cmd "grimblast copysave screen") { locked = true; })
          (bind "ALT + SHIFT + S" (dsp.exec_cmd "grimblast copysave area") { locked = true; })

          # Focus movement
          (bind "${mainMod} + H" (dsp.focus { direction = "left"; }) { })
          (bind "${mainMod} + J" (dsp.focus { direction = "down"; }) { })
          (bind "${mainMod} + K" (dsp.focus { direction = "up"; }) { })
          (bind "${mainMod} + L" (dsp.focus { direction = "right"; }) { })

          # Workspace navigation
          (bind "${mainMod} + 1" (dsp.focus { workspace = 1; }) { })
          (bind "${mainMod} + 2" (dsp.focus { workspace = 2; }) { })
          (bind "${mainMod} + 3" (dsp.focus { workspace = 3; }) { })
          (bind "${mainMod} + 4" (dsp.focus { workspace = 4; }) { })
          (bind "${mainMod} + 5" (dsp.focus { workspace = 5; }) { })
          (bind "${mainMod} + 6" (dsp.focus { workspace = 6; }) { })
          (bind "${mainMod} + 7" (dsp.focus { workspace = 7; }) { })
          (bind "${mainMod} + 8" (dsp.focus { workspace = 8; }) { })
          (bind "${mainMod} + 9" (dsp.focus { workspace = 9; }) { })
          (bind "${mainMod} + 0" (dsp.focus { workspace = 10; }) { })

          # Move window to workspace
          (bind "${mainMod} + SHIFT + 1" (dsp.window.move { workspace = 1; }) { })
          (bind "${mainMod} + SHIFT + 2" (dsp.window.move { workspace = 2; }) { })
          (bind "${mainMod} + SHIFT + 3" (dsp.window.move { workspace = 3; }) { })
          (bind "${mainMod} + SHIFT + 4" (dsp.window.move { workspace = 4; }) { })
          (bind "${mainMod} + SHIFT + 5" (dsp.window.move { workspace = 5; }) { })
          (bind "${mainMod} + SHIFT + 6" (dsp.window.move { workspace = 6; }) { })
          (bind "${mainMod} + SHIFT + 7" (dsp.window.move { workspace = 7; }) { })
          (bind "${mainMod} + SHIFT + 8" (dsp.window.move { workspace = 8; }) { })
          (bind "${mainMod} + SHIFT + 9" (dsp.window.move { workspace = 9; }) { })
          (bind "${mainMod} + SHIFT + 0" (dsp.window.move { workspace = 10; }) { })

          # Special workspace
          (bind "${mainMod} + S" (dsp.workspace.toggle_special "magic") { })
          (bind "${mainMod} + SHIFT + S" (dsp.window.move { workspace = "special:magic"; }) { })

          # Mouse scroll workspace switching
          (bind "${mainMod} + mouse_down" (dsp.focus { workspace = "e+1"; }) { })
          (bind "${mainMod} + mouse_up" (dsp.focus { workspace = "e-1"; }) { })

          # Fullscreen
          (bind "${mainMod} + F" (dsp.window.fullscreen { action = "toggle"; }) { })

          # PiP window position
          (bind "${mainMod} + ALT + H" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh left") { locked = true; })
          (bind "${mainMod} + ALT + J" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh down") { locked = true; })
          (bind "${mainMod} + ALT + K" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh up") { locked = true; })
          (bind "${mainMod} + ALT + L" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh right") { locked = true; })

          # Mouse drag/resize
          (bind "${mainMod} + mouse:272" dsp.window.drag { mouse = true; })
          (bind "${mainMod} + mouse:273" dsp.window.resize { mouse = true; })

          # Media keys
          (bind "XF86AudioNext" (dsp.exec_cmd "playerctl next") { locked = true; })
          (bind "XF86AudioPause" (dsp.exec_cmd "playerctl play-pause") { locked = true; })
          (bind "XF86AudioPlay" (dsp.exec_cmd "playerctl play-pause") { locked = true; })
          (bind "XF86AudioPrev" (dsp.exec_cmd "playerctl previous") { locked = true; })

          # Hardware controls
          (bind "XF86MonBrightnessUp" (dsp.exec_cmd "brightnessctl --device acpi_video0 -e4 -n2 set 5%+") { locked = true; repeating = true; })
          (bind "XF86MonBrightnessDown" (dsp.exec_cmd "brightnessctl --device acpi_video0 -e4 -n2 set 5%-") { locked = true; repeating = true; })
          (bind "XF86KbdBrightnessUp" (dsp.exec_cmd "brightnessctl --device kbd_backlight -e4 set 5%+") { locked = true; repeating = true; })
          (bind "XF86KbdBrightnessDown" (dsp.exec_cmd "brightnessctl --device kbd_backlight -e4 set 5%-") { locked = true; repeating = true; })

          # Extra bindel from option
          (map (e: let
            parts = lib.splitString "," e;
          in { _args = parts; }) config.hyprland.bindel)
        ];

        on = mkArgs [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd("bash $HOME/.nixos/start.sh")
              hl.exec_cmd("hyprctl dispatch hl.dsp.focus workspace=special:magic")
              hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
            end
          '')
        ];

        window_rule = [
          {
            match.class = "^steam_app_\\d+$";
            workspace = "special:magic";
          }
          {
            match.title = "^Picture-In-Picture$";
            float = true;
            pin = true;
            size = { x = 0.3; y = 0.3; };
            move = { x = "100%-w-20"; y = "100%-h-20"; };
          }
        ];
      };
    };
  };
}
