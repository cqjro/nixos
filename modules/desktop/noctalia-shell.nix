{ inputs, ...}:
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
      bar.default.monitor."DP-3" = {
        # `match` defaults to the subtable key ("DP-3") when omitted,
        # so no need to set it explicitly here.
        scale = 1.3;  # bump icons/text on DP-3; tweak to taste (clamped ~0.2–2.5)
      };
      # HDMI-A-1 gets no override entry, so it stays at bar.default's scale = 1.0
      #
      # general.radiusRatio = 0.6;
      #
      # # Turn off Noctalia's own wallpaper-based/matugen color generation so
      # # it doesn't fight with Stylix, which is what's actually driving colors.
      colorSchemes.useWallpaperColors = false;
    };
  };
}
