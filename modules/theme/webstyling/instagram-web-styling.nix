{ ... }:
{
	flake.modules.homeManager."instagram-web-styling" = { config, lib, ... }:
	let
		c = config.lib.stylix.colors;
		toRgb = hex: let
			digits = {
				"0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
				"a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
				"A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
			};
			num = builtins.foldl' (acc: d: acc * 16 + digits.${d}) 0 (lib.stringToCharacters hex);
		in "${toString (lib.div num 65536)}, ${toString (lib.mod (lib.div num 256) 256)}, ${toString (lib.mod num 256)}";
	in {
		zenWebStyling.siteStyles."instagram.com" = ''
:root,
* {
	color-scheme: dark !important;

	/* Instagram design tokens. These are consumed as rgb(var(--ig-*)), so must be RGB triplets
	   (""important" is required because the app emits the vars on hashed class containers). */
	--ig-primary-background: ${toRgb c.base00} !important;
	--ig-secondary-background: ${toRgb c.base01} !important;
	--ig-banner-background: ${toRgb c.base01} !important;
	--ig-highlight-background: ${toRgb c.base02} !important;
	--ig-elevated-background: ${toRgb c.base01} !important;
	--ig-elevated-highlight-background: ${toRgb c.base02} !important;
	--ig-hover-overlay: ${toRgb c.base02} !important;

	--ig-primary-text: ${toRgb c.base05} !important;
	--ig-secondary-text: ${toRgb c.base04} !important;
	--ig-tertiary-text: ${toRgb c.base04} !important;
	--ig-text-on-color: ${toRgb c.base00} !important;
	--ig-text-on-media: ${toRgb c.base05} !important;
	--ig-link: ${toRgb c.base0D} !important;

	--ig-primary-button: ${toRgb c.base0D} !important;
	--ig-primary-button-hover: ${toRgb c.base0E} !important;
	--ig-badge: ${toRgb c.base0D} !important;
	--ig-secondary-button: ${toRgb c.base02} !important;
	--ig-secondary-button-background: ${toRgb c.base02} !important;
	--ig-secondary-button-hover: ${toRgb c.base03} !important;
	--ig-error-or-destructive: ${toRgb c.base08} !important;
	--ig-success: ${toRgb c.base0B} !important;

	--ig-separator: ${toRgb c.base03} !important;
	--ig-elevated-separator: ${toRgb c.base03} !important;
	--ig-stroke: ${toRgb c.base03} !important;

	--ig-primary-icon: ${toRgb c.base05} !important;
	--ig-secondary-icon: ${toRgb c.base04} !important;
	--ig-tertiary-icon: ${toRgb c.base03} !important;

	--ig-text-input-border-hover-prism: ${toRgb c.base0D} !important;
	--ig-toggle-background-on-prism: ${toRgb c.base0D} !important;
}

html,
body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

h1, h2, h3, h4 {
	color: #${c.base05} !important;
}

a {
	color: #${c.base0D} !important;
}

/* inputs (login/search/direct message) */
input,
textarea,
[role="textbox"],
[class*="x2lah0s"] {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* the app paints many near-white backgrounds inline -- repaint them */
div[style*="rgb(245, 245, 245)"],
div[style*="rgb(250, 250, 250)"],
div[style*="rgb(255, 255, 255)"],
body[style*="background: white"] {
	background-color: #${c.base00} !important;
}

/* black icons / text get restyled */
svg[stroke="#000"] {
	stroke: #${c.base05} !important;
}

svg[fill="#000"] {
	fill: #${c.base05} !important;
}

div[style*="color: rgb(0, 0, 0)"],
div[style*="color: rgb(38, 38, 38)"] {
	color: #${c.base05} !important;
}
		'';
	};
}