{pkgs, config, ...}:
{ 
	stylix = {
		enable = true;
		autoEnable = true;
		enableReleaseChecks = false; # stops the version mismatch error

		base16Scheme = {
			base00 = "#191324"; # Default Background                      ANSI: None
			base01 = "#221d2b"; # Black | Lighter Background              ANSI: 0
			base02 = "#524763"; # Bright Black | Selection Background     ANSI: 8
			base03 = "#373142"; # Grey | Comments-InvisibleLines          ANSI: None
			base04 = "#524763"; # Light Grey | Dark Foreground            ANSI: None
			base05 = "#b8b0c6"; # Foreground | Delimiters-Operators       ANSI: None
			base06 = "#e1efff"; # White | Light Foreground                ANSI: 7
			base07 = "#ffffff"; # Bright White | Lightest Foreground      ANSI 15
			base08 = "#e54b4b"; # Red                                     ANSI: 1
			base09 = "#f09c5e"; # Orange                                  ANSI: ~3
			base0A = "#f0c05e"; # Yellow     Alt e6c62f                   ANSI: 3
			base0B = "#3ad900"; # Green                                   ANSI: 2
			base0C = "#00BD9C"; # Cyan                                    ANSI: 6 
			base0D = "#007bd3"; # Blue                                    ANSI: 4
			base0E = "#dc396a"; # Magenta    Alt cf256d                   ANSI: 5
			base0F = "#e54b4b"; # Dark Red/Brown                          ANSI: None
		};

		cursor = {
			name = "BreezeX-RosePine-Linux";
			package = pkgs.rose-pine-cursor;
			size = 27;
		};

		# iconTheme = {
		# 	enable = true;
		# 	# name = "Gruvbox-Plus-Dark";
		# 	package = pkgs.gruvbox-plus-icons;
		# };

		fonts = {
			monospace = {
				package = pkgs.nerd-fonts.jetbrains-mono;
				name = "JetBrainsMono Nerd Font Mono";
			};

			serif = config.stylix.fonts.monospace;
			sansSerif = config.stylix.fonts.monospace;
			emoji = config.stylix.fonts.monospace;
				
		};
	};
}
