{pkgs, lib, inputs, ...}:
{

  #TODO: Create a way to save my personal theme and swap with preset ones on the fly
  

  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];


  # import preset themes available with nix-colors
  # colorScheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;
  
  # custom theme
  colorScheme = {
    slug = "personal";
    name = "personal theme";
    author = "me :)";
    palette = {           # Terminal Color | Text Editor -> ANSI Code
      base00 = "#191324"; # Default Background -> ANSI: None
      base01 = "#221d2b"; # Black | Lighter Background (Status Bars) -> ANSI: 0
      base02 = "#524763"; # Bright Black | Selection Background -> ANSI: 8
      base03 = "#373142"; # Grey | Comments-InvisibleLines -> ANSI: None
      base04 = "#524763"; # Light Grey | Dark Foreground -> ANSI: None
      base05 = "#b8b0c6"; # Foreground | Delimiters-Operators -> ANSI: None
      base06 = "#e1efff"; # White | Light Foreground -> ANSI: 7
      base07 = "#ffffff"; # Bright White | Lightest Foreground -> ANSI 15
      base08 = "#e54b4b"; # Red -> ANSI: 1
      base09 = "#f09c5e"; # Orange -> ANSI: ~3
      base0A = "#f0c05e"; # Yellow -> ANSI: 3
      base0B = "#3ad900"; # Green -> ANSI: 2
      base0C = "#82d8d8"; # Cyan -> ANSI: 6
      base0D = "#007bd3"; # Blue -> ANSI: 4
      base0E = "#cf256d"; # Magenta -> ANSI: 5
      base0F = "#e54b4b"; # Dark Red/Brown -> ANSI: None
      # base10 = ""; # Darker Black | Darker Background -> ANSI: None
      # base11 = ""; # Darkest Black | Darkest Background -> ANSI: None
      # base12 = ""; # Bright Red -> ANSI: 9
      # base13 = ""; # Bright Yellow -> ANSI: 11
      # base14 = ""; # Bright Green -> ANSI: 10
      # base15 = ""; # Bright Cyan -> ANSI: 14
      # base16 = ""; # Bright Blue -> ANSI: 12
      # base17 = ""; # Bright Magenta -> ANSI: 13
    };
  };
}
