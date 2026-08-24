{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
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

      colorSchemes.useWallpaperColors = false;

      # Global clock widget config - applies to all monitors
      widget.clock.format = "{:%-I:%M:%S %p}"; 
    };
  };
}
