{ inputs, config, pkgs, ... }:
let
  c = config.lib.stylix.colors;
  mode = if config.stylix.polarity == "light" then "light" else "dark";

  caelestiaScheme = pkgs.writeText "stylix-caelestia-scheme.txt" ''
    primary_paletteKeyColor ${c.base0D}
    secondary_paletteKeyColor ${c.base0E}
    tertiary_paletteKeyColor ${c.base0C}
    neutral_paletteKeyColor ${c.base03}
    neutral_variant_paletteKeyColor ${c.base02}
    background ${c.base00}
    onBackground ${c.base05}
    surface ${c.base01}
    surfaceDim ${c.base00}
    surfaceBright ${c.base02}
    surfaceContainerLowest ${c.base00}
    surfaceContainerLow ${c.base01}
    surfaceContainer ${c.base01}
    surfaceContainerHigh ${c.base02}
    surfaceContainerHighest ${c.base03}
    onSurface ${c.base05}
    surfaceVariant ${c.base02}
    onSurfaceVariant ${c.base04}
    inverseSurface ${c.base05}
    inverseOnSurface ${c.base00}
    outline ${c.base03}
    outlineVariant ${c.base02}
    shadow ${c.base00}
    scrim ${c.base00}
    surfaceTint ${c.base0D}
    primary ${c.base0D}
    onPrimary ${c.base00}
    primaryContainer ${c.base01}
    onPrimaryContainer ${c.base0D}
    inversePrimary ${c.base0D}
    secondary ${c.base0E}
    onSecondary ${c.base00}
    secondaryContainer ${c.base01}
    onSecondaryContainer ${c.base0E}
    tertiary ${c.base0C}
    onTertiary ${c.base00}
    tertiaryContainer ${c.base01}
    onTertiaryContainer ${c.base0C}
    error ${c.base08}
    onError ${c.base00}
    errorContainer ${c.base01}
    onErrorContainer ${c.base08}
    primaryFixed ${c.base0D}
    primaryFixedDim ${c.base0D}
    onPrimaryFixed ${c.base00}
    onPrimaryFixedVariant ${c.base01}
    secondaryFixed ${c.base0E}
    secondaryFixedDim ${c.base0E}
    onSecondaryFixed ${c.base00}
    onSecondaryFixedVariant ${c.base01}
    tertiaryFixed ${c.base0C}
    tertiaryFixedDim ${c.base0C}
    onTertiaryFixed ${c.base00}
    onTertiaryFixedVariant ${c.base01}
    term0 ${c.base00}
    term1 ${c.base08}
    term2 ${c.base0B}
    term3 ${c.base0A}
    term4 ${c.base0D}
    term5 ${c.base0E}
    term6 ${c.base0C}
    term7 ${c.base05}
    term8 ${c.base03}
    term9 ${c.base08}
    term10 ${c.base0B}
    term11 ${c.base0A}
    term12 ${c.base0D}
    term13 ${c.base0E}
    term14 ${c.base0C}
    term15 ${c.base07}
    rosewater ${c.base06}
    flamingo ${c.base08}
    pink ${c.base0E}
    mauve ${c.base0E}
    red ${c.base08}
    maroon ${c.base08}
    peach ${c.base09}
    yellow ${c.base0A}
    green ${c.base0B}
    teal ${c.base0C}
    sky ${c.base0C}
    sapphire ${c.base0D}
    blue ${c.base0D}
    lavender ${c.base0D}
    text ${c.base05}
    subtext1 ${c.base04}
    subtext0 ${c.base04}
    overlay2 ${c.base03}
    overlay1 ${c.base03}
    overlay0 ${c.base02}
    surface2 ${c.base02}
    surface1 ${c.base01}
    surface0 ${c.base01}
    base ${c.base00}
    mantle ${c.base00}
    crust ${c.base00}
    custom0 ${c.base08}
    custom1 ${c.base09}
    custom2 ${c.base0A}
    custom3 ${c.base0B}
    custom4 ${c.base0C}
    custom5 ${c.base0D}
    custom6 ${c.base0E}
    custom7 ${c.base0F}
    custom8 ${c.base00}
    custom9 ${c.base01}
    custom10 ${c.base02}
    custom11 ${c.base03}
    custom12 ${c.base04}
    custom13 ${c.base05}
    custom14 ${c.base06}
    custom15 ${c.base07}
  '';
in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  home.file.".local/state/caelestia/schemes/stylix/default/${mode}.txt" = {
    source = caelestiaScheme;
  };

  home.file.".local/state/caelestia/scheme.json" = {
    text = builtins.toJSON {
      scheme = "stylix";
      variant = "default";
      inherit mode;
    };
    force = true;
  };

  xdg.configFile."caelestia/shell.json".text = builtins.toJSON {
    bar = {
      activeWindow = {
        rotateCounterClockwise = true;
      };
      status = {
        showBattery = false;
      };
    };
    services = {
      wallpaperEnabled = false;
      smartScheme = false;
    };
  };

  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [];
    };
    cli.enable = true;
  };
}
