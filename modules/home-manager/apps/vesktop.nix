{pkgs, lib, config, inputs, ...}:
{

	# stylix.targets.vencord.extraCss = ''
	# 	:root {
 #    	--font-primary: ${config.stylix.fonts.sansSerif.name};
 #      --font-display: ${config.stylix.fonts.sansSerif.name};
 #      --font-code: ${config.stylix.fonts.monospace.name};
 #    }
	#
 #    .visual-refresh {
	# 		--activity-card-background: var(--base00) !important;
 #      --background-accent: var(--base00) !important;
 #      --background-floating: var(--base00) !important;
 #      --background-mentioned-hover: var(--base00) !important;
 #      --background-mentioned: var(--base00) !important;
 #      --background-message-highlight: var(--base00) !important;
 #      --background-message-hover: var(--base00) !important;
 #      --background-modifier-accent: var(--base00) !important;
 #      --background-modifier-active: var(--base00) !important;
 #      --background-modifier-hover: var(--base00) !important;
 #      --background-modifier-selected: var(--base00) !important;
 #      --background-primary: var(--base00) !important;
 #      --background-secondary-alt: var(--base00) !important;
 #      --background-secondary: var(--base00) !important;
 #      --background-surface-highest: var(--base00) !important;
 #      --background-surface-higher: var(--base00) !important;
 #      --background-surface-high: var(--base00) !important;
 #      --background-tertiary: var(--base00) !important;
 #      --background-base-low: var(--base00) !important;
 #      --background-base-lower: var(--base00) !important;
 #      --background-base-lowest: var(--base00) !important;
 #      --background-base-tertiary: var(--base00) !important;
 #      --background-code: var(--base00) !important;
 #      --background-mod-subtle: var(--base00) !important;
	# 	}
	# 	
	# '';

	programs.vesktop = {
		enable = true;

		settings = {
			minimizeToTray = false;
		};

		vencord = {
			settings = {
				# settings here
			};
		};
	};	
}

