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
      systemd.enable = true;

      extraConfig = ''
        -- Hyprland 0.55+ Lua Configuration

        local terminal = "ghostty"
        local fileManager = "ghostty -e yazi"
        local menu = "rofi -show drun -show-icons"
        local browser = "zen"
        local mainMod = "SUPER"

        -- MONITORS (interpolated from hyprland.monitors option)
        ${lib.concatStringsSep "\n" (map (m: "hl.monitor(\"${m}\")") config.hyprland.monitors)}

        -- AUTOSTART
        on.hyprland.start = {
          hl.exec_cmd("bash $HOME/.nixos/start.sh"),
          hl.exec_cmd("hyprctl dispatch createworkspace special:magic"),
          hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"),
        }

        -- ENVIRONMENT VARIABLES
        hl.env("XCURSOR_SIZE", 27)
        hl.env("HYPRCURSOR_SIZE", 27)
        hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
        hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
        hl.env("OZONE_PLATFORM_HINT", "wayland")

        -- CONFIGURATION
        hl.config {
          general = {
            gaps_in = 5,
            gaps_out = 15,
            border_size = 5,
            resize_on_border = false,
            allow_tearing = false,
            layout = "dwindle",
          },
          decoration = {
            rounding = 10,
            rounding_power = 2,
            active_opacity = 1.0,
            inactive_opacity = 1.0,
            shadow = {
              enabled = true,
              range = 4,
              render_power = 3,
            },
            blur = {
              enabled = true,
              size = 3,
              passes = 1,
              vibrancy = 0.1696,
            },
          },
          animations = {
            enabled = true,
            bezier = {
              {"easeOutQuint", 0.23, 1, 0.32, 1},
              {"easeInOutCubic", 0.65, 0.05, 0.36, 1},
              {"linear", 0, 0, 1, 1},
              {"almostLinear", 0.5, 0.5, 0.75, 1.0},
              {"quick", 0.15, 0, 0.1, 1},
            },
            animation = {
              {"global", 1, 10, "default"},
              {"border", 1, 5.39, "easeOutQuint"},
              {"windows", 1, 4.79, "easeOutQuint"},
              {"windowsIn", 1, 4.1, "easeOutQuint", "popin 87%"},
              {"windowsOut", 1, 1.49, "linear", "popin 87%"},
              {"fadeIn", 1, 1.73, "almostLinear"},
              {"fadeOut", 1, 1.46, "almostLinear"},
              {"fade", 1, 3.03, "quick"},
              {"layers", 1, 3.81, "easeOutQuint"},
              {"layersIn", 1, 4, "easeOutQuint", "fade"},
              {"layersOut", 1, 1.5, "linear", "fade"},
              {"fadeLayersIn", 1, 1.79, "almostLinear"},
              {"fadeLayersOut", 1, 1.39, "almostLinear"},
              {"workspaces", 1, 1.94, "almostLinear", "fade"},
              {"workspacesIn", 1, 1.21, "almostLinear", "fade"},
              {"workspacesOut", 1, 1.94, "almostLinear", "fade"},
            },
          },
          dwindle = { preserve_split = true },
          master = { new_status = "master" },
          misc = {
            force_default_wallpaper = -1,
            disable_hyprland_logo = true,
            background_color = "rgba(841F17FF)",
            focus_on_activate = true,
            disable_splash_rendering = true,
          },
          input = {
            kb_layout = "us",
            follow_mouse = 1,
            sensitivity = 0,
            touchpad = {
              natural_scroll = true,
              disable_while_typing = true,
              tap_to_click = false,
              scroll_factor = 0.7,
              clickfinger_behavior = true,
            },
          },
          gesture = {{3, "horizontal", "workspace"}},
          device = { name = "epic-mouse-v1", sensitivity = -0.5 },
        }

        -- KEYBINDINGS
        hl.bind(mainMod .. " + Q", hl.dsp.window.close())
        hl.bind(mainMod .. " + M", hl.dsp.exit())
        hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mainMod .. " + SHIFT + L", hl.exec_cmd("hyprlock"))
        hl.bind("ALT + S", hl.exec_cmd("grimblast copysave screen"), { locked = true })
        hl.bind("ALT + SHIFT + S", hl.exec_cmd("grimblast copysave area"), { locked = true })
        hl.bind(mainMod .. " + H", hl.dsp.layout("movefocus", "left"))
        hl.bind(mainMod .. " + J", hl.dsp.layout("movefocus", "down"))
        hl.bind(mainMod .. " + K", hl.dsp.layout("movefocus", "up"))
        hl.bind(mainMod .. " + L", hl.dsp.layout("movefocus", "right"))

        hl.bind(mainMod .. " + 1", hl.dsp.workspace.change(1))
        hl.bind(mainMod .. " + 2", hl.dsp.workspace.change(2))
        hl.bind(mainMod .. " + 3", hl.dsp.workspace.change(3))
        hl.bind(mainMod .. " + 4", hl.dsp.workspace.change(4))
        hl.bind(mainMod .. " + 5", hl.dsp.workspace.change(5))
        hl.bind(mainMod .. " + 6", hl.dsp.workspace.change(6))
        hl.bind(mainMod .. " + 7", hl.dsp.workspace.change(7))
        hl.bind(mainMod .. " + 8", hl.dsp.workspace.change(8))
        hl.bind(mainMod .. " + 9", hl.dsp.workspace.change(9))
        hl.bind(mainMod .. " + 0", hl.dsp.workspace.change(10))

        hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
        hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
        hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
        hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
        hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
        hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
        hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
        hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
        hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
        hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

        hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
        hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
        hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace.change("+1"))
        hl.bind(mainMod .. " + mouse_up", hl.dsp.workspace.change("-1"))
        hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

        hl.bind(mainMod .. " + ALT + H", hl.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh left"), { locked = true })
        hl.bind(mainMod .. " + ALT + J", hl.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh down"), { locked = true })
        hl.bind(mainMod .. " + ALT + K", hl.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh up"), { locked = true })
        hl.bind(mainMod .. " + ALT + L", hl.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh right"), { locked = true })

        hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
        hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
        hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
        hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

        -- HARDWARE CONTROLS (bindel)
        hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl --device acpi_video0 -e4 -n2 set 5%+"), { locked = true, repeating = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl --device acpi_video0 -e4 -n2 set 5%-"), { locked = true, repeating = true })
        hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl --device kbd_backlight -e4 set 5%+"), { locked = true, repeating = true })
        hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl --device kbd_backlight -e4 set 5%-"), { locked = true, repeating = true })
        ${lib.concatStringsSep "\n" config.hyprland.bindel}

        -- WINDOW RULES
        hl.window_rule {
          match = { class = "^steam_app_\\d+$" },
          workspace = "special:magic",
        }
        hl.window_rule {
          match = { title = "^Picture-In-Picture$" },
          float = true,
          pin = true,
          size = { 0.3, 0.3 },
          move = { "100%-w-20", "100%-h-20" },
        }
      '';
    };
  };
}
