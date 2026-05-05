{lib, config, ...}:
{ 
  options = {
    hyprland.enable = lib.mkEnableOption "enables hyprland module";
    hyprland.monitors = lib.mkOption {
      default = [
        { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
      ];
      description = "allowing monitor options within the module";
    };
		hyprland.bindel = lib.mkOption {
			default = [];
			description = "inputs for hardware specific brightness, audio, and keyboard brightness controls";
			type = lib.types.listOf (lib.types.submodule {
				options = {
					key = lib.mkOption {
						type = lib.types.str;
						description = "The key or key combo to bind";
					};
					cmd = lib.mkOption {
						type = lib.types.str;
						description = "The command to execute";
					};
				};
			});
		};
  };

  config = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
    };

    # Hyprland 0.55+ prefers hyprland.lua over hyprland.conf.
    # We write it directly via home.file so that the flake package is still
    # set by the wayland.windowManager.hyprland module above, while the Lua
    # config drives the actual compositor configuration.
    home.file.".config/hypr/hyprland.lua".text =
      let
        # Serialise the monitor list into hl.monitor() calls.
        monitorLines = lib.concatMapStrings (m: ''
          hl.monitor({ output = "${m.output}", mode = "${m.mode}", position = "${m.position}", scale = ${toString m.scale} })
        '') config.hyprland.monitors;

        # Serialise extra bindel entries (passthrough from per-machine config).
				bindelLines = lib.concatMapStrings (b: ''
					hl.bind("${b.key}", hl.dsp.exec_cmd("${b.cmd}"), { release = true, repeat = true })
				'') config.hyprland.bindel;
      in
      #lua
			''
        -- ########################################
        -- Hyprland Lua config (Hyprland >= 0.55)
        -- ########################################

        ----------------
        -- MONITORS
        ----------------
        ${monitorLines}

        ----------------
        -- PROGRAMS
        ----------------
        local terminal   = "ghostty"
        local fileManager = "ghostty -e yazi"
        local menu       = "rofi -show drun -show-icons"
        local browser    = "zen"
        local mainMod    = "SUPER"

        ----------------
        -- AUTOSTART
        ----------------
        hl.exec_once("waybar")
        hl.exec_once("bash $HOME/.nixos/start.sh")
        hl.exec_once("hyprctl dispatch createworkspace special:magic")
        hl.exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

        ----------------
        -- ENVIRONMENT VARIABLES
        ----------------
        hl.env("XCURSOR_SIZE",                "27")
        hl.env("HYPRCURSOR_SIZE",             "27")
        hl.env("HYPRCURSOR_THEME",            "rose-pine-hyprcursor")
        hl.env("ELECTRON_OZONE_PLATFORM_HINT","wayland")
        hl.env("OZONE_PLATFORM_HINT",         "wayland")

        ----------------
        -- LOOK AND FEEL
        ----------------
        hl.config({
          general = {
            gaps_in       = 5,
            gaps_out      = 15,
            border_size   = 5,
            ["col.active_border"] = "rgba(${config.lib.stylix.colors.base05}FF)",
            resize_on_border = false,
            allow_tearing    = false,
            layout           = "dwindle",
          },

          decoration = {
            rounding       = 10,
            rounding_power = 2,
            active_opacity   = 1.0,
            inactive_opacity = 1.0,
            shadow = {
              enabled      = true,
              range        = 4,
              render_power = 3,
            },
            blur = {
              enabled   = true,
              size      = 3,
              passes    = 1,
              vibrancy  = 0.1696,
            },
          },

          dwindle = {
            pseudotile     = true,
            preserve_split = true,
          },

          master = {
            new_status = "master",
          },

          misc = {
            force_default_wallpaper = -1,
            disable_hyprland_logo   = true,
            background_color        = "rgba(841F17FF)",
            focus_on_activate       = true,
          },

          input = {
            kb_layout    = "us",
            follow_mouse = 1,
            sensitivity  = 0,
            touchpad = {
              natural_scroll      = true,
              disable_while_typing = true,
              tap_to_click        = false,
              scroll_factor       = 0.7,
              clickfinger_behavior = true,
            },
          },
        })

        ----------------
        -- ANIMATIONS
        ----------------
        hl.curve("easeOutQuint",    { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
        hl.curve("easeInOutCubic",  { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
        hl.curve("linear",          { type = "bezier", points = { {0,    0},    {1,    1}   } })
        hl.curve("almostLinear",    { type = "bezier", points = { {0.5,  0.5},  {0.75, 1.0} } })
        hl.curve("quick",           { type = "bezier", points = { {0.15, 0},    {0.1,  1}   } })

        hl.animation({ leaf = "global",         enabled = true,  speed = 10,   bezier = "default"      })
        hl.animation({ leaf = "border",         enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windows",        enabled = true,  speed = 4.79, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windowsIn",      enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
        hl.animation({ leaf = "windowsOut",     enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
        hl.animation({ leaf = "fadeIn",         enabled = true,  speed = 1.73, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeOut",        enabled = true,  speed = 1.46, bezier = "almostLinear" })
        hl.animation({ leaf = "fade",           enabled = true,  speed = 3.03, bezier = "quick"        })
        hl.animation({ leaf = "layers",         enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
        hl.animation({ leaf = "layersIn",       enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
        hl.animation({ leaf = "layersOut",      enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
        hl.animation({ leaf = "fadeLayersIn",   enabled = true,  speed = 1.79, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeLayersOut",  enabled = true,  speed = 1.39, bezier = "almostLinear" })
        hl.animation({ leaf = "workspaces",     enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesIn",   enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesOut",  enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })

        ----------------
        -- PER-DEVICE CONFIG
        ----------------
        hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

        ----------------
        -- GESTURES
        ----------------
        -- 3-finger horizontal swipe to switch workspaces
        hl.config({ gestures = { workspace_swipe = true, workspace_swipe_fingers = 3 } })

        ----------------
        -- WINDOW RULES
        ----------------
        hl.window_rule({
          match   = { class = "steam_app_%d+" },
          workspace = "special:magic",
        })
        hl.window_rule({
          match = { title = "Picture-in-Picture" },
          float = true,
          pin   = true,
          size  = "30% 30%",
          move  = "100%-w-20 100%-w-20",
        })

        ----------------
        -- KEYBINDINGS
        ----------------

        -- Window management
        hl.bind(mainMod .. " + Q", hl.dsp.window.close())
        hl.bind(mainMod .. " + M", hl.dsp.exit())
        hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))

        -- Lock screen
        hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))

        -- Screenshots
        hl.bind("ALT + S",       hl.dsp.exec_cmd("grimblast copysave screen"))
        hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("grimblast copysave area"))

        -- Focus movement (vim-style)
        hl.bind(mainMod .. " + H", hl.dsp.window.focus({ direction = "l" }))
        hl.bind(mainMod .. " + J", hl.dsp.window.focus({ direction = "d" }))
        hl.bind(mainMod .. " + K", hl.dsp.window.focus({ direction = "u" }))
        hl.bind(mainMod .. " + L", hl.dsp.window.focus({ direction = "r" }))

        -- Workspace switching
        for i = 1, 10 do
          local key = tostring(i % 10)  -- 1-9 map to "1"-"9", 10 maps to "0"
          hl.bind(mainMod .. " + " .. key,         hl.dsp.workspace.go({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.workspace.move_window({ workspace = i }))
        end

        -- Special (magic) workspace
        hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special({ workspace = "magic" }))
        hl.bind(mainMod .. " + SHIFT + S", hl.dsp.workspace.move_window({ workspace = "special:magic" }))

        -- Scroll through workspaces with mouse wheel
        hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace.go({ workspace = "e+1" }), { mouse = true })
        hl.bind(mainMod .. " + mouse_up",   hl.dsp.workspace.go({ workspace = "e-1" }), { mouse = true })

        -- PiP window movement (custom script)
        hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh left"))
        hl.bind(mainMod .. " + ALT + J", hl.dsp.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh down"))
        hl.bind(mainMod .. " + ALT + K", hl.dsp.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh up"))
        hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("bash $HOME/.nixos/scripts/pip-move.sh right"))

        -- Mouse window manipulation
        hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- Extra per-machine bindel entries (injected from hyprland.bindel option)
        ${bindelLines}

        -- Media keys (release-triggered)
        hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { release = true })
        hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { release = true })
        hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { release = true })
        hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { release = true })
      '';
  };
}
