{ ... }:
{
	flake.modules.homeManager."claude-web-styling" = { config, lib, ... }:
	let
		c = config.lib.stylix.colors;
		digits = {
			"0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
			"a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
			"A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
		};
		num = hex: builtins.foldl' (acc: d: acc * 16 + digits.${d}) 0 (lib.stringToCharacters hex);
		div = builtins.div;
		rgbOf = hex: let
			n = num hex;
		in [
			(div n 65536)
			(div (n - (65536 * (div n 65536))) 256)
			(n - (256 * (div n 256)))
		];
		maxA = a: b: if a > b then a else b;
		minA = a: b: if a < b then a else b;
		rnd1 = x: builtins.floor (x * 10 + 0.5);
		fmt = x: "${builtins.toString (div (rnd1 x) 10)}.${builtins.toString (rnd1 x - (10 * (div (rnd1 x) 10)))}";
		# Claude's tokens are used as `hsl(var(--token))`, so they need "H S% L%" triples.
		toHsl = hex: let
			rgb = rgbOf hex;
			r = (builtins.elemAt rgb 0) / 255.0;
			g = (builtins.elemAt rgb 1) / 255.0;
			b = (builtins.elemAt rgb 2) / 255.0;
			mx = maxA (maxA r g) b;
			mn = minA (minA r g) b;
			ln = (mx + mn) / 2.0;
			l = ln * 100.0;
			d = mx - mn;
			diff = 2.0 * ln - 1.0;
			absd = if diff < 0 then 0.0 - diff else diff;
			denom = if d == 0 then 1.0 else 1.0 - absd;
			s = if d == 0 then 0.0 else (d / denom) * 100.0;
			hue =
				if d == 0 then 0.0
				else if mx == r then ((g - b) / d) * 60.0
				else if mx == g then ((b - r) / d + 2.0) * 60.0
				else ((r - g) / d + 4.0) * 60.0;
			h = if hue < 0.0 then hue + 360.0 else hue;
		in "${fmt h} ${fmt s}% ${fmt l}%";
		hslName = name: toHsl c."${name}";
		styling = ''
:root[data-mode="dark"] {
	color-scheme: dark !important;

	/* Claude.ai real design tokens. Most are consumed via hsl(var(--token)),
	   so values must be "H S% L%" triples (accent-brand/clay are also used
	   raw, so those stay hex). */
	--bg-000: ${hslName "base00"} !important;
	--bg-100: ${hslName "base00"} !important;
	--bg-200: ${hslName "base01"} !important;
	--bg-300: ${hslName "base01"} !important;
	--bg-400: ${hslName "base02"} !important;
	--bg-500: ${hslName "base02"} !important;

	--text-000: ${hslName "base07"} !important;
	--text-100: ${hslName "base05"} !important;
	--text-200: ${hslName "base05"} !important;
	--text-300: ${hslName "base04"} !important;
	--text-400: ${hslName "base04"} !important;
	--text-500: ${hslName "base04"} !important;

	--border-000: ${hslName "base03"} !important;
	--border-100: ${hslName "base03"} !important;
	--border-200: ${hslName "base03"} !important;
	--border-300: ${hslName "base03"} !important;
	--border-400: ${hslName "base03"} !important;
	--border-500: ${hslName "base03"} !important;

	--oncolor-000: ${hslName "base02"} !important;
	--oncolor-100: ${hslName "base00"} !important;
	--oncolor-200: ${hslName "base00"} !important;
	--oncolor-300: ${hslName "base00"} !important;

	--pictogram-100: ${hslName "base05"} !important;
	--pictogram-200: ${hslName "base04"} !important;
	--pictogram-300: ${hslName "base04"} !important;
	--pictogram-400: ${hslName "base02"} !important;

	--accent-brand: #${c.base0D} !important;
	--accent-main-000: ${hslName "base0D"} !important;
	--accent-main-100: ${hslName "base0D"} !important;
	--accent-main-200: ${hslName "base0D"} !important;
	--accent-main-900: ${hslName "base01"} !important;
	--accent-pro-000: ${hslName "base0E"} !important;
	--accent-pro-100: ${hslName "base0E"} !important;
	--accent-pro-200: ${hslName "base0E"} !important;
	--accent-pro-900: ${hslName "base01"} !important;
	--accent-secondary-000: ${hslName "base0E"} !important;
	--accent-secondary-100: ${hslName "base0E"} !important;
	--accent-secondary-200: ${hslName "base0E"} !important;
	--accent-secondary-900: ${hslName "base01"} !important;

	--brand-000: ${hslName "base0D"} !important;
	--brand-100: ${hslName "base0D"} !important;
	--brand-200: ${hslName "base0D"} !important;
	--brand-900: ${hslName "base00"} !important;

	--danger-000: ${hslName "base08"} !important;
	--danger-100: ${hslName "base08"} !important;
	--danger-200: ${hslName "base08"} !important;
	--danger-900: ${hslName "base01"} !important;
	--warning-000: ${hslName "base09"} !important;
	--warning-100: ${hslName "base09"} !important;
	--warning-200: ${hslName "base09"} !important;
	--warning-900: ${hslName "base01"} !important;
	--success-000: ${hslName "base0B"} !important;
	--success-100: ${hslName "base0B"} !important;
	--success-200: ${hslName "base0B"} !important;
	--success-900: ${hslName "base01"} !important;

	/* Claude Design System (menus, modals, tooltips, popovers) */
	--cds-surface-0: ${hslName "base00"} !important;
	--cds-surface-1: ${hslName "base01"} !important;
	--cds-surface-2: ${hslName "base02"} !important;
	--cds-surface-3: ${hslName "base02"} !important;
	--cds-surface-panel: ${hslName "base01"} !important;
	--cds-surface-popover: ${hslName "base01"} !important;
	--cds-text-primary: ${hslName "base05"} !important;
	--cds-text-secondary: ${hslName "base04"} !important;
	--cds-text-muted: ${hslName "base04"} !important;
	--cds-text-accent: ${hslName "base0D"} !important;
	--cds-text-danger: ${hslName "base08"} !important;
	--cds-text-success: ${hslName "base0B"} !important;
	--cds-text-warning: ${hslName "base09"} !important;

	/* legacy claude-* aliases (stored as plain colors) */
	--claude-accent-clay: #${c.base0D} !important;
	--claude-background-color: #${c.base00} !important;
	--claude-foreground-color: #${c.base05} !important;
	--claude-secondary-color: #${c.base04} !important;
	--claude-border: #${c.base03} !important;
	--claude-border-300: #${c.base03} !important;
	--claude-border-300-more: #${c.base02} !important;
	--claude-text-100: #${c.base06} !important;
	--claude-text-200: #${c.base05} !important;
	--claude-text-400: #${c.base04} !important;
	--claude-text-500: #${c.base04} !important;
	--claude-description-text: #${c.base04} !important;
}

html,
body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

a {
	color: #${c.base0D} !important;
}

h1, h2, h3, h4, h5, h6 {
	color: #${c.base05} !important;
}

input,
textarea,
select {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

code,
pre {
	background-color: #${c.base01} !important;
	color: #${c.base06} !important;
}

mark {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}

::selection {
	background-color: ${hslName "base0D"} !important;
	color: #${c.base00} !important;
}
		'';
	in {
		zenWebStyling.siteStyles."claude.ai" = styling;
		zenWebStyling.siteStyles."claude.com" = styling;
		zenWebStyling.siteStyles."a.claude.ai" = styling;
	};
}