{ inputs, ... }:
let
  noctaliaHm = inputs.noctalia.homeModules.default;
in
{
  flake.modules.homeManager."noctalia-shell" = {
    imports = [ noctaliaHm ];

    # The unit follows graphical-session.target, which Plasma / Plasma
    # Bigscreen also reach; keep Noctalia's bar and wallpaper out of KDE
    # sessions. Negated so Hyprland still starts it if the variable is missing.
    systemd.user.services.noctalia.Unit.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=KDE";

    programs.noctalia = {
      enable = true;
      systemd = {
        enable = true;
      };
      settings = {
        plugins = {
          enabled = [
            "nightwatch75/file-search"
          ];
        };
        # Per-monitor scale overrides (others inherit from bar.default)
        bar.default.monitor."DP-3" = {
          scale = 1.3;
        };

        # wallpapers = [
        # 	"/home/cairo/.nixos/modules/desktop/wallpapers/blend-in.jpeg"
        # ];

        colorSchemes.useWallpaperColors = false;
        # Global clock widget config - applies to all monitors
        widget.clock.format = "{:%-I:%M:%S %p}";
      };
    };
  };
}