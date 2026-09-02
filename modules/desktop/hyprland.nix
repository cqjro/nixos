# https://www.reddit.com/r/NixOS/comments/1tg9cse/hyprland_hm_lua_config_migration/
{ lib, config, ... }:
{
  options = {
    hyprland.enable = lib.mkEnableOption "enables hyprland module";
    hyprland.monitors = lib.mkOption {
      default = [ ",preferred,auto,auto" ];
      description = "Raw Hyprland monitor strings (e.g., 'desc:XYZ,1920x1080@60,0x0,1')";
      type = lib.types.listOf lib.types.str;
    };
    hyprland.bindel = lib.mkOption {
      default = [];
      description = "Extra bindel entries as raw hyprlang format";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf config.hyprland.enable (let
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

    activeBorderCol = "rgba(${toString config.lib.stylix.colors.base05}FF)";
    inactiveBorderCol = "rgba(595959aa)";

    # Parse monitor string: "desc:XYZ,1920x1080@60,0x0,1" -> {output, mode, position, scale}
    parseMonitor = m: let
      parts = lib.splitString "," m;
      output = if lib.length parts >= 1 then builtins.elemAt parts 0 else "";
      mode = if lib.length parts >= 2 then builtins.elemAt parts 1 else "preferred";
      position = if lib.length parts >= 3 then builtins.elemAt parts 2 else "0x0";
      scale = if lib.length parts >= 4 then builtins.elemAt parts 3 else "1";
    in {
      inherit output mode position scale;
    };

    ##########################################################
    # NEW: animation/bezier handling
    #
    # hl.config({...}) only accepts general/decoration/input/
    # gestures/group/binds/debug/misc/dwindle/master/scrolling/
    # ecosystem. Animations are NOT one of those categories, so
    # nesting them under `config` (as the old rewrite did) makes
    # them silent no-ops and Hyprland falls back to its default
    # (slower, spring-based) animation set.
    #
    # Curves and animations instead need direct hl.curve() /
    # hl.animation() calls. These helpers convert your old
    # hyprlang-style strings into those calls automatically.
    ##########################################################

    trim = s: let
      trimLeft = str: if str == "" then str else
        if builtins.substring 0 1 str == " "
        then trimLeft (builtins.substring 1 (builtins.stringLength str - 1) str)
        else str;
      trimRight = str: if str == "" then str else
        if builtins.substring (builtins.stringLength str - 1) 1 str == " "
        then trimRight (builtins.substring 0 (builtins.stringLength str - 1) str)
        else str;
    in trimRight (trimLeft s);

    # "name,x1,y1,x2,y2" -> hl.curve("name", { type = "bezier", points = { {x1,y1}, {x2,y2} } })
    mkCurveLua = b: let
      parts = map trim (lib.splitString "," b);
      name = builtins.elemAt parts 0;
      x1 = builtins.elemAt parts 1;
      y1 = builtins.elemAt parts 2;
      x2 = builtins.elemAt parts 3;
      y2 = builtins.elemAt parts 4;
    in ''hl.curve("${name}", { type = "bezier", points = { {${x1}, ${y1}}, {${x2}, ${y2}} } })'';

    # "leaf, onoff, speed, curve[, style]" -> hl.animation({ leaf=..., enabled=..., speed=..., bezier=...[, style=...] })
    mkAnimationLua = a: let
      parts = map trim (lib.splitString "," a);
      leaf = builtins.elemAt parts 0;
      onoff = builtins.elemAt parts 1;
      speed = builtins.elemAt parts 2;
      curve = builtins.elemAt parts 3;
      hasStyle = lib.length parts >= 5;
      style = if hasStyle then builtins.elemAt parts 4 else null;
      enabled = if onoff == "1" then "true" else "false";
      styleField = if hasStyle then '', style = "${style}"'' else "";
    in ''hl.animation({ leaf = "${leaf}", enabled = ${enabled}, speed = ${speed}, bezier = "${curve}"${styleField} })'';

    bezierList = [
      "easeOutQuint,0.23,1,0.32,1"
      "easeInOutCubic,0.65,0.05,0.36,1"
      "linear,0,0,1,1"
      "almostLinear,0.5,0.5,0.75,1.0"
      "quick,0.15,0,0.1,1"
    ];

    animationList = [
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

    animationsLua = lib.concatStringsSep "\n" (
      (map mkCurveLua bezierList) ++ (map mkAnimationLua animationList)
    );
  in {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = true;

      settings = {
        config = {
				# TODO remove debug option if it causes gpu performance issues
					debug = {
						damage_tracking = 0; # full-frame redraw every frame to stop stale pixel errors
					};

					general = {
						gaps_in = 5;
						gaps_out = 15;
						border_size = 0;              # was 5 — no more border outline
							resize_on_border = false;
						allow_tearing = false;
						layout = "dwindle";
# col.active_border / col.inactive_border removed — moot with border_size = 0
					};

					decoration = {
						rounding = 10;
						rounding_power = 2;
						active_opacity = 1.0;
						inactive_opacity = 1.0;

						shadow = {
							enabled = true;
							range = 40;                  # bigger spread = softer "glow" vs. a hard shadow
								render_power = 4;            # higher = smoother falloff
								color = lib.mkForce "rgba(00000090)";    # focused window: visible soft shadow
								color_inactive = lib.mkForce "rgba(00000000)";  # unfocused: fully transparent = no shadow
						};

						blur = {
							enabled = true;
							size = 3;
							passes = 1;
							vibrancy = 0.1696;
						};
					};
          # animations block removed from here — see extraConfig below

          dwindle = { preserve_split = true; };
          master = { new_status = "master"; };

          misc = {
            force_default_wallpaper = -1;
            disable_hyprland_logo = true;
            # background_color = lib.mkForce "rgba(841F17FF)";
            focus_on_activate = true;
            disable_splash_rendering = true;
						vrr = 0; # disabling variable refresh rate (try to solve kvm isues)
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

          device = [{
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          }];
        };

        monitor = map parseMonitor config.hyprland.monitors;

        bind = lib.flatten [
          (bind "${mainMod} + Q" dsp.window.close { })
          (bind "${mainMod} + M" dsp.window.kill { })
          (bind "${mainMod} + V" (dsp.window.float { action = "toggle"; }) { })
          (bind "${mainMod} + SHIFT + L" (dsp.exec_cmd "hyprlock") { })
          (bind "ALT + S" (dsp.exec_cmd "grimblast copysave screen") { locked = true; })
          (bind "ALT + SHIFT + S" (dsp.exec_cmd "grimblast copysave area") { locked = true; })
          (bind "${mainMod} + H" (dsp.focus { direction = "left"; }) { })
          (bind "${mainMod} + J" (dsp.focus { direction = "down"; }) { })
          (bind "${mainMod} + K" (dsp.focus { direction = "up"; }) { })
          (bind "${mainMod} + L" (dsp.focus { direction = "right"; }) { })
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
          (bind "${mainMod} + S" (dsp.workspace.toggle_special "magic") { })
          (bind "${mainMod} + SHIFT + S" (dsp.window.move { workspace = "special:magic"; }) { })
          (bind "${mainMod} + mouse_down" (dsp.focus { workspace = "e+1"; }) { })
          (bind "${mainMod} + mouse_up" (dsp.focus { workspace = "e-1"; }) { })
          (bind "${mainMod} + F" (dsp.window.fullscreen { action = "toggle"; }) { })
          (bind "${mainMod} + ALT + H" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh left") { locked = true; })
          (bind "${mainMod} + ALT + J" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh down") { locked = true; })
          (bind "${mainMod} + ALT + K" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh up") { locked = true; })
          (bind "${mainMod} + ALT + L" (dsp.exec_cmd "bash $HOME/.nixos/scripts/pip-move.sh right") { locked = true; })
          (bind "${mainMod} + mouse:272" dsp.window.drag { mouse = true; })
          (bind "${mainMod} + mouse:273" dsp.window.resize { mouse = true; })
          (bind "XF86AudioNext" (dsp.exec_cmd "playerctl next") { locked = true; })
          (bind "XF86AudioPause" (dsp.exec_cmd "playerctl play-pause") { locked = true; })
          (bind "XF86AudioPlay" (dsp.exec_cmd "playerctl play-pause") { locked = true; })
          (bind "XF86AudioPrev" (dsp.exec_cmd "playerctl previous") { locked = true; })
          (bind "XF86MonBrightnessUp" (dsp.exec_cmd "brightnessctl --device acpi_video0 -e4 -n2 set 5%+") { locked = true; repeating = true; })
          (bind "XF86MonBrightnessDown" (dsp.exec_cmd "brightnessctl --device acpi_video0 -e4 -n2 set 5%-") { locked = true; repeating = true; })
          (bind "XF86KbdBrightnessUp" (dsp.exec_cmd "brightnessctl --device kbd_backlight -e4 set 5%+") { locked = true; repeating = true; })
          (bind "XF86KbdBrightnessDown" (dsp.exec_cmd "brightnessctl --device kbd_backlight -e4 set 5%-") { locked = true; repeating = true; })
        ];

        on = mkArgs [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd("bash $HOME/.nixos/start.sh")
              hl.dispatch(hl.dsp.focus({ workspace = "special:magic" }))
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
          }
        ];
      };

      extraConfig = ''
        hl.env("XCURSOR_SIZE", "27")
        hl.env("HYPRCURSOR_SIZE", "27")
        hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
        hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
        hl.env("OZONE_PLATFORM_HINT", "wayland")

        ${animationsLua}
      '';
    };

    xdg.configFile."hypr/hyprland-bindel.lua".text = lib.concatStringsSep "\n" config.hyprland.bindel;
  });
}
