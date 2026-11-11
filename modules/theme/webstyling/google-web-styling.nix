{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { config, ... }:
	{
		# Google (www.google.com and every google.com page, incl. the /sorry block page
		# and the reCAPTCHA anchor frame, which is served from www.google.com/recaptcha).
		# Seen live (theme-shots, 2026-11-11, top viewport only): the /sorry block page,
		# home, /preferences, /advanced_search and support.google.com/websearch.
		# The search-results rules (snippets, keyword highlights, AI overview, chips,
		# menus) are UNVERIFIED: /search is bot-blocked to /sorry. They were written
		# from the previous file, the web-styling-colours candidate and
		# catppuccin/userstyles "google" (MIT) as a reference for which Google colour
		# tokens exist; no rules were copied.
		zenWebStyling.siteStyles."google.com" = let
			c = config.lib.stylix.colors;
			# base04 equals base02 (~2:1 on base00), too dim to read: blend base05 toward base00
			muted = "color-mix(in srgb, #${c.base05} 75%, #${c.base00})";
			# no lavender slot: blue/magenta blend for visited links
			violet = "color-mix(in srgb, #${c.base0D} 50%, #${c.base0E})";
			# translucent accent wash for highlights and selection (text stays readable on it)
			wash = "color-mix(in srgb, #${c.base0D} 30%, transparent)";
			# hover/selected row: one quiet step above the base01 surface
			hover = "color-mix(in srgb, #${c.base05} 8%, #${c.base01})";
			# selected rail item / container fills: an accent tint of the surface, not a loud fill
			active = "color-mix(in srgb, #${c.base0D} 22%, #${c.base01})";
		in ''
:root {
	color-scheme: dark !important;
	scrollbar-color: #${c.base02} #${c.base00} !important;
}

/* Google's own colour tokens (results page, dark and light builds). Setting the
   variables recolours every element that reads them, without hashed classes.
   (/preferences and support.google.com do not read them: setting them on every
   element changed nothing there, see the scoped blocks at the end.) */
:root {
	--xhUGwc: #${c.base00} !important;
	--bbQxAb: #${c.base05} !important;
	--IXoxUe: ${muted} !important;
	--COEmY: #${c.base05} !important;
	--YLNNHc: #${c.base05} !important;
	--JKqx2: #${c.base0D} !important;
	--gS5jXb: #${c.base01} !important;
	--mXZkqc: #${c.base01} !important;
	--EpFNW: #${c.base01} !important;
	--XKMDxc: #${c.base01} !important;
	--TSWZIb: #${c.base01} !important;
	--Nsm0ce: #${c.base0D} !important;

	--uv-styles-color-surface: #${c.base00} !important;
	--uv-styles-color-primary: #${c.base00} !important;
	--uv-styles-color-tertiary: #${c.base01} !important;
	--uv-styles-color-on-tertiary: #${c.base05} !important;
	--uv-styles-color-text-default: ${muted} !important;
	--uv-styles-color-text-emphasis: #${c.base05} !important;
	--uv-styles-color-text-primary: #${c.base0D} !important;
	--uv-styles-color-icon-default: #${c.base05} !important;
	--uv-styles-color-outline: #${c.base03} !important;

	--gm3-sys-color-surface: #${c.base00} !important;
	--gm3-sys-color-surface-container: #${c.base01} !important;
	--gm3-sys-color-surface-container-low: #${c.base01} !important;
	--gm3-sys-color-surface-container-high: #${c.base01} !important;
	--gm3-sys-color-surface-container-highest: #${c.base01} !important;
	--gm3-sys-color-on-surface: #${c.base05} !important;
	--gm3-sys-color-on-surface-variant: ${muted} !important;
	--gm3-sys-color-primary: #${c.base0D} !important;
	--gm3-sys-color-outline: #${c.base03} !important;
	--gm3-sys-color-outline-variant: #${c.base03} !important;
	--gm3-sys-color-background: #${c.base00} !important;
	--gm3-sys-color-on-background: #${c.base05} !important;
	--gm3-sys-color-surface-bright: #${c.base01} !important;
	--gm3-sys-color-surface-dim: #${c.base00} !important;
	--gm3-sys-color-surface-container-lowest: #${c.base00} !important;
	--gm3-sys-color-surface-variant: #${c.base01} !important;
	--gm3-sys-color-on-primary: #${c.base07} !important;
	--gm3-sys-color-primary-container: ${active} !important;
	--gm3-sys-color-on-primary-container: #${c.base06} !important;
	--gm3-sys-color-secondary: #${c.base0D} !important;
	--gm3-sys-color-secondary-container: ${active} !important;
	--gm3-sys-color-on-secondary-container: #${c.base06} !important;
	--gm3-sys-color-tertiary-container: #${c.base01} !important;
	--gm3-sys-color-on-tertiary-container: #${c.base05} !important;
	--gm3-sys-color-inverse-surface: #${c.base05} !important;
	--gm3-sys-color-inverse-on-surface: #${c.base00} !important;
}

html,
body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

h1, h2, h3, h4, h5, h6 {
	color: #${c.base05} !important;
}

a {
	color: #${c.base0D} !important;
}

/* headings drawn as divs (preferences page sections) */
[role="heading"] {
	color: #${c.base05} !important;
}

[role="link"] {
	color: #${c.base0D} !important;
}

/* selected navigation item: an accent tint, bright text */
[aria-current="page"],
[aria-current="true"],
[role="tab"][aria-selected="true"] {
	background-color: ${active} !important;
	color: #${c.base06} !important;
}

/* the "Sign in" link is drawn as a filled pill; the accent link colour made it
   blue on blue. Quiet surface button with bright text instead. */
a[href*="ServiceLogin"],
a[href*="accounts.google.com/v3/signin"],
a[href*="accounts.google.com/signin"] {
	background: #${c.base01} !important;
	border: 1px solid #${c.base03} !important;
	box-shadow: none !important;
	color: #${c.base06} !important;
}

a[href*="ServiceLogin"] *,
a[href*="accounts.google.com/v3/signin"] *,
a[href*="accounts.google.com/signin"] * {
	color: inherit !important;
}

/* form buttons ("Google Search", "I'm Feeling Lucky"): flat surface buttons */
input[type="submit"],
input[type="button"],
input[type="reset"] {
	background: #${c.base01} !important;
	border: 1px solid #${c.base03} !important;
	box-shadow: none !important;
	color: #${c.base05} !important;
}

input[type="submit"]:hover,
input[type="button"]:hover,
input[type="reset"]:hover {
	background: ${hover} !important;
}

/* rules (the /sorry page draws its dividers with <hr noshade>) */
hr {
	border: none !important;
	border-top: 1px solid #${c.base03} !important;
	height: 0 !important;
	color: #${c.base03} !important;
	background: none !important;
}

/* ---- text highlighting -------------------------------------------------------
   Keyword highlights in snippets (<em>/<b>), AI-overview marks, selection and
   scroll-to-text fragments. Generic element/pseudo selectors, so a renamed
   snippet class cannot bring the old fill back: no element gets a solid
   background, emphasis is weight plus the bright text colour. */
em,
b,
strong {
	background-color: transparent !important;
	background-image: none !important;
	box-shadow: none !important;
}

[role="main"] em,
[role="main"] b,
[data-sncf] em,
[data-sncf] b,
.VwiC3b em,
.VwiC3b b {
	color: #${c.base06} !important;
	font-weight: 600 !important;
}

mark {
	background-color: ${wash} !important;
	color: #${c.base06} !important;
	border-radius: 2px !important;
}

/* separate rule: an unsupported pseudo-element would drop the whole selector list */
::target-text {
	background-color: ${wash} !important;
	color: #${c.base06} !important;
}

::selection {
	background-color: ${wash} !important;
	color: #${c.base06} !important;
}

/* ---- header and search box ------------------------------------------------ */
header,
#gb {
	background-color: #${c.base00} !important;
}

/* the search bar pill carries the surface */
.RNNXgb {
	background: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* search pill shows the accent border while it has focus */
.RNNXgb:focus-within {
	border-color: color-mix(in srgb, #${c.base0D} 55%, #${c.base03}) !important;
}

/* native form fields: one flat surface, no stray boxes */
textarea,
input[type="text"],
input[type="search"],
input[type="email"],
input:not([type]),
select {
	color-scheme: dark !important;
	-webkit-appearance: none !important;
	appearance: none !important;
	background: #${c.base01} !important;
	color: #${c.base05} !important;
}

/* except inside the search pill where the pill itself carries the surface */
.RNNXgb textarea,
.RNNXgb input,
textarea[name="q"],
input[name="q"],
input.gLFyf,
#input {
	background: transparent !important;
	border: none !important;
	box-shadow: none !important;
	color: #${c.base05} !important;
}

input::placeholder,
textarea::placeholder {
	color: ${muted} !important;
}

/* the class is reused for the search-bar text container: transparent inside the pill */
.RNNXgb .XEqVsf,
.RNNXgb .XEqVsf * {
	background: transparent !important;
	background-image: none !important;
	border: none !important;
	box-shadow: none !important;
}

/* ---- menus, suggestion lists, dialogs ---------------------------------------- */
[role="listbox"],
[role="menu"],
g-menu,
.ajZCb {
	background: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

[role="option"]:hover,
[role="option"][aria-selected="true"],
[role="menuitem"]:hover,
[role="menuitemradio"]:hover {
	background: ${hover} !important;
}

[role="dialog"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* sticky header bar while scrolling */
.VHFyob .CvDJxb {
	background: #${c.base00} !important;
}

/* page footer */
.f6F9Be {
	background: #${c.base00} !important;
}

/* ---- results ------------------------------------------------------------------- */
/* titles carry the link colour (accent), visited ones shift to the blue/magenta blend */
a h3,
.LC20lb,
.DKV0Md {
	color: #${c.base0D} !important;
}

a:visited h3,
a:visited .LC20lb,
a:visited .DKV0Md {
	color: ${violet} !important;
}

/* urls, breadcrumbs and snippets sit one step down the text hierarchy */
cite,
.VuuXrf,
.NJjxre,
.tjvcx,
.VwiC3b,
.lEBKkf,
.IsZvec,
.aCOpRe,
[data-sncf] {
	color: ${muted} !important;
}

/* AI overview plate and its gradient scrim: flat page colour */
.Zze5V,
.RDmXvc {
	background: #${c.base00} !important;
	background-image: none !important;
}

/* expanded AI sources card */
.XEqVsf {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* pills and chips ("show all", "show more", people-also-search-for); base03 keeps
   base05 text readable, base02 only ~4:1 */
.YoEHmf,
.mWokkb,
.b2Rnsc,
.fxvkXe,
.p8Jhnd {
	background-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* ---- reCAPTCHA checkbox (www.google.com/recaptcha anchor frame) ----------------- */
.rc-anchor,
.rc-anchor-light,
.rc-anchor-normal {
	background: #${c.base01} !important;
	border: 1px solid #${c.base03} !important;
	box-shadow: none !important;
	color: #${c.base05} !important;
}

.rc-anchor-checkbox-label,
.rc-anchor-center-item {
	color: #${c.base05} !important;
}

.rc-anchor-logo-text,
.rc-anchor-pt,
.rc-anchor-pt a {
	color: ${muted} !important;
}

.recaptcha-checkbox-border {
	background: #${c.base00} !important;
	border-color: #${c.base02} !important;
}

/* the multicolour logo sprite: quiet monochrome, like the other secondary marks */
.rc-anchor-logo-img {
	filter: grayscale(1) !important;
	opacity: 0.6 !important;
}

/* ---- pages with hard-coded light surfaces ---------------------------------------
   /preferences and support.google.com paint white/pale-blue panels with fixed
   colours, not Google's tokens. Inside these two scopes only, every box drops its
   own background (flat page) and takes the light text colour; cards get the one
   surface step back. Never applied to search results. */
@-moz-document url-prefix("https://www.google.com/preferences"), domain("support.google.com") {
	/* every box and its state layer (the selected-rail pill and the accordion
	   header are drawn by ones these tag names missed); specific rules above and
	   below still win on specificity */
	*,
	*::before,
	*::after {
		background-color: transparent !important;
	}

	div,
	section,
	ul,
	li,
	span,
	p,
	button,
	label,
	h1, h2, h3, h4, h5, h6 {
		color: #${c.base05} !important;
	}

	a,
	a span {
		color: #${c.base0D} !important;
	}

	/* selected rail entry */
	[aria-selected="true"],
	[aria-current="page"],
	[aria-current="true"] {
		background-color: ${active} !important;
		color: #${c.base06} !important;
	}

	[aria-selected="true"] *,
	[aria-current="page"] *,
	[aria-current="true"] * {
		color: #${c.base06} !important;
	}

	/* icons drawn in a fixed dark colour */
	svg {
		fill: currentColor;
	}

	/* the hero search field ("Describe your issue") is transparent (name="q"):
	   a quiet underline marks it (a box on its wrapper came out ~90px tall) */
	input[name="q"] {
		border-bottom: 1px solid #${c.base03} !important;
	}
}

/* /advanced_search: the header rule and the select outlines are drawn in a
   light grey; quiet base03 borders there (scoped: a global border colour would
   reveal borders other pages keep transparent); the text fields get the same
   outline as the selects */
@-moz-document url-prefix("https://www.google.com/advanced_search") {
	* {
		border-color: #${c.base03} !important;
	}

	input[type="text"],
	input:not([type]) {
		border: 1px solid #${c.base03} !important;
	}

	/* field labels are drawn in a dim grey */
	main,
	[role="main"],
	label,
	td {
		color: #${c.base05} !important;
	}
}
		'';
	};
}
