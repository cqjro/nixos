{ inputs, ...}:
{

	imports = [
		inputs.noctalia.homeModules.default
	];

  programs.noctalia = {
    enable = true;
    settings = {
      # bar = {
      #   position = "top";
      #   density = "compact";
      #   showCapsule = true;
      #   widgets = {
      #     left = [
      #       { id = "SidePanelToggle"; useDistroLogo = true; }
      #       { id = "ActiveWindow"; }
      #     ];
      #     center = [
      #       { id = "Workspace"; hideUnoccupied = false; }
      #     ];
      #     right = [
      #       { id = "Tray"; }
      #       { id = "WiFi"; }
      #       { id = "Bluetooth"; }
      #       { id = "Battery"; warningThreshold = 30; }
      #       { id = "Volume"; }
      #       { id = "Clock"; formatHorizontal = "HH:mm"; }
      #       { id = "ControlCenter"; }
      #     ];
      #   };
      # };
      #
      # general.radiusRatio = 0.6;
      #
      # # Turn off Noctalia's own wallpaper-based/matugen color generation so
      # # it doesn't fight with Stylix, which is what's actually driving colors.
      colorSchemes.useWallpaperColors = false;
    };
  };


}
