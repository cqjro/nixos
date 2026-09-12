{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."google.com" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;

	/* Material 3 tokens (search chrome + AI overview) */
	--gm3-sys-color-surface: #${c.base00} !important;
	--gm3-sys-color-surface-dim: #${c.base00} !important;
	--gm3-sys-color-surface-container-lowest: #${c.base00} !important;
	--gm3-sys-color-surface-container-low: #${c.base01} !important;
	--gm3-sys-color-surface-container: #${c.base01} !important;
	--gm3-sys-color-surface-container-high: #${c.base02} !important;
	--gm3-sys-color-surface-container-highest: #${c.base02} !important;
	--gm3-sys-color-on-surface: #${c.base05} !important;
	--gm3-sys-color-on-surface-variant: #${c.base04} !important;
	--gm3-sys-color-primary: #${c.base0D} !important;
	--gm3-sys-color-on-primary: #${c.base00} !important;
	--gm3-sys-color-primary-container: #${c.base02} !important;
	--gm3-sys-color-on-primary-container: #${c.base05} !important;
	--gm3-sys-color-secondary-container: #${c.base02} !important;
	--gm3-sys-color-on-secondary-container: #${c.base05} !important;
	--gm3-sys-color-tertiary-container: #${c.base02} !important;
	--gm3-sys-color-on-tertiary-container: #${c.base05} !important;
	--gm3-sys-color-outline-variant: #${c.base03} !important;
	--gm3-sys-color-outline: #${c.base03} !important;
	--gm3-sys-color-inverse-surface: #${c.base05} !important;
	--gm3-sys-color-inverse-on-surface: #${c.base00} !important;
	--gm3-sys-color-scrim: #${c.base00} !important;
	--gm3-sys-color-secondary: #${c.base0E} !important;
	--gm3-sys-color-on-secondary: #${c.base00} !important;
	--gm3-sys-color-error: #${c.base08} !important;
	--gm3-sys-color-on-error: #${c.base00} !important;

	/* classic Google homepage/search chrome */
	--ntp-fakebox-bg: #${c.base01} !important;
	--ntp-fakebox-fg: #${c.base05} !important;
	--ntp-fakebox-hint-color: #${c.base04} !important;
	--ntp-fakebox-shadow: none !important;
	--ntp-more-vert-icon-color: #${c.base05} !important;
	--ntp-outer-shadow: #${c.base03} !important;
}

html {
	background-color: #${c.base00} !important;
}

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

/* search box + omnibox */
input[type="text"],
textarea,
.A8SBwf,
.gLFyf {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input[type="text"]::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* top result cards / AI overview containers */
.aajZCb,
.RENK0b,
.ORc2of,
.g3hlLe,
[data-testid="ai-answer-wrapper"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* new tab page shortcuts */
.NnVire,
.MtgXee,
.fHHqKb,
.f6aMJd {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
}

/* footer */
#fbar,
#fbarcnt {
	background-color: #${c.base01} !important;
	border-top-color: #${c.base03} !important;
	color: #${c.base04} !important;
}
		'';
	};
}