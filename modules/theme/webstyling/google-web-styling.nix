{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."google.com" = ''
:root {
	color-scheme: dark !important;

	/* Material 3 tokens (search chrome + AI overview) */
	--gm3-sys-color-surface: var(--stylix-bg) !important;
	--gm3-sys-color-surface-dim: var(--stylix-bg) !important;
	--gm3-sys-color-surface-container-lowest: var(--stylix-bg) !important;
	--gm3-sys-color-surface-container-low: var(--stylix-surface) !important;
	--gm3-sys-color-surface-container: var(--stylix-surface) !important;
	--gm3-sys-color-surface-container-high: var(--stylix-hover) !important;
	--gm3-sys-color-surface-container-highest: var(--stylix-hover) !important;
	--gm3-sys-color-on-surface: var(--stylix-text) !important;
	--gm3-sys-color-on-surface-variant: var(--stylix-text-dim) !important;
	--gm3-sys-color-primary: var(--stylix-brand) !important;
	--gm3-sys-color-on-primary: var(--stylix-bg) !important;
	--gm3-sys-color-primary-container: var(--stylix-hover) !important;
	--gm3-sys-color-on-primary-container: var(--stylix-text) !important;
	--gm3-sys-color-secondary-container: var(--stylix-hover) !important;
	--gm3-sys-color-on-secondary-container: var(--stylix-text) !important;
	--gm3-sys-color-tertiary-container: var(--stylix-hover) !important;
	--gm3-sys-color-on-tertiary-container: var(--stylix-text) !important;
	--gm3-sys-color-outline-variant: var(--stylix-border) !important;
	--gm3-sys-color-outline: var(--stylix-border) !important;
	--gm3-sys-color-inverse-surface: var(--stylix-text) !important;
	--gm3-sys-color-inverse-on-surface: var(--stylix-bg) !important;
	--gm3-sys-color-scrim: var(--stylix-bg) !important;
	--gm3-sys-color-secondary: var(--stylix-secondary) !important;
	--gm3-sys-color-on-secondary: var(--stylix-bg) !important;
	--gm3-sys-color-error: var(--stylix-danger) !important;
	--gm3-sys-color-on-error: var(--stylix-bg) !important;

	/* classic Google homepage/search chrome */
	--ntp-fakebox-bg: var(--stylix-surface) !important;
	--ntp-fakebox-fg: var(--stylix-text) !important;
	--ntp-fakebox-hint-color: var(--stylix-text-dim) !important;
	--ntp-fakebox-shadow: none !important;
	--ntp-more-vert-icon-color: var(--stylix-text) !important;
	--ntp-outer-shadow: var(--stylix-border) !important;
}

html {
	background-color: var(--stylix-bg) !important;
}

body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

h1, h2, h3, h4 {
	color: var(--stylix-text) !important;
}

a {
	color: var(--stylix-brand) !important;
}

/* search box + omnibox */
input[type="text"],
textarea,
.A8SBwf,
.gLFyf {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

input[type="text"]::placeholder,
textarea::placeholder {
	color: var(--stylix-text-dim) !important;
}

/* top result cards / AI overview containers */
.aajZCb,
.RENK0b,
.ORc2of,
.g3hlLe,
[data-testid="ai-answer-wrapper"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

/* new tab page shortcuts */
.NnVire,
.MtgXee,
.fHHqKb,
.f6aMJd {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
}

/* footer */
#fbar,
#fbarcnt {
	background-color: var(--stylix-surface) !important;
	border-top-color: var(--stylix-border) !important;
	color: var(--stylix-text-dim) !important;
}
		'';
	};
}