{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { config, ... }:
	{
		# Google (www.google.com and every google.com page, incl. the /sorry block page
		# and the reCAPTCHA anchor frame, which is served from www.google.com/recaptcha).
		# Seen live (theme-shots, 2026-11-11, viewport and full page): the /sorry block
		# page, home, images, /preferences, /advanced_search, support.google.com,
		# news.google.com, translate.google.com and the accounts sign-in page.
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
			# Stylix fonts, as the Vesktop theme uses them (text only, never icon fonts)
			sans = config.stylix.fonts.sansSerif.name;
			mono = config.stylix.fonts.monospace.name;
			# one radius for every surface this file draws
			radius = "8px";
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

/* ---- flat style: fonts, shadows, focus, hover ---------------------------------- */
/* Stylix font on text elements. Icon fonts (Material Icons / Symbols, Google
   Symbols) are ligature fonts on their own elements: those are excluded by class
   and by aria-hidden, so their glyphs keep rendering. */
:is(body, p, a, span, div, li, dt, dd, h1, h2, h3, h4, h5, h6, td, th, label, input, textarea, select, button, cite, small, time, em, b, strong):not([class*="icon" i], [class*="material" i], [class*="symbol" i], [class*="glyph" i], [aria-hidden="true"], [data-icon]) {
	font-family: "${sans}", sans-serif !important;
}

code,
pre,
kbd,
samp {
	font-family: "${mono}", monospace !important;
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-radius: 4px !important;
}

/* no drop shadows anywhere: surfaces are separated by the 1px base03 borders */
*,
*::before,
*::after {
	box-shadow: none !important;
	text-shadow: none !important;
}

/* keyboard focus: one accent ring on controls; text fields are autofocused on
   most pages and show focus through their own border instead */
:focus-visible:not(input, textarea, [contenteditable]) {
	outline: 2px solid #${c.base0D} !important;
	outline-offset: 2px !important;
}

:is(input, textarea, [contenteditable]):focus-visible {
	outline: none !important;
}

/* hover on buttons and links */
button:hover,
[role="button"]:hover,
[role="tab"]:hover {
	background-color: ${hover} !important;
}

a:hover {
	text-decoration-color: currentColor !important;
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
@-moz-document url-prefix("https://www.google.com/preferences"), domain("support.google.com"), domain("news.google.com"), url-prefix("https://accounts.google.com/v3/signin"), url-prefix("https://accounts.google.com/signin"), url-prefix("https://accounts.google.com/ServiceLogin") {
	/* every box and its state layer (the selected-rail pill and the accordion
	   header are drawn by ones these tag names missed); specific rules above and
	   below still win on specificity */
	*,
	*::before,
	*::after {
		background-color: transparent !important;
	}

	/* Google's light-grey outlines (accordions, outlined buttons, fields) become
	   the quiet border (measured on help: the accordion edge was a light grey);
	   links and tabs keep their own border colours (forcing one there drew boxes
	   around the help tabs) */
	*:not(a, [role="tab"], [aria-current="page"], [aria-current="true"], [aria-selected="true"]) {
		border-color: #${c.base03} !important;
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

	/* icons drawn in a fixed dark colour: Google sets their fill in a class rule,
	   which beats a plain user rule, so !important; only icons inside buttons (the
	   search magnifier), never the multicolour logos */
	svg {
		fill: currentColor;
	}

	button svg,
	[role="button"] svg {
		fill: currentColor !important;
	}

	/* the hero search field ("Describe your issue") is the input itself (name="q",
	   48px tall): the raised surface with the quiet border (a box on its wrapper
	   came out ~90px tall) */
	input[name="q"] {
		background-color: #${c.base01} !important;
		border: 1px solid #${c.base03} !important;
		border-radius: ${radius} !important;
	}
}

/* /preferences: the setting rows are rounded [jsaction] boxes (found with an
   outline probe), the footer "Feedback" a button-role element drawn as plain text
   next to accent links, the "Parental controls" tile a link to Family Link.
   The page wrapper, header, rail and button-role elements are excluded from the
   card rule. */
@-moz-document url-prefix("https://www.google.com/preferences") {
	[jsaction]:not(html, body, header, nav, [role="banner"], [role="navigation"], [role="button"], :has([jsaction])),
	a[href*="families.google"],
	a[href*="familylink"] {
		background-color: #${c.base01} !important;
		border: 1px solid #${c.base03} !important;
		border-radius: ${radius} !important;
	}

	[role="button"],
	[role="button"] * {
		color: #${c.base0D} !important;
	}

	/* the Family Link tile reads like the other rows (accent is for links in text) */
	a[href*="families.google"],
	a[href*="families.google"] *,
	a[href*="familylink"],
	a[href*="familylink"] * {
		color: #${c.base05} !important;
	}

	/* the cookie notice keeps a panel */
	[role="alert"],
	[role="status"] {
		background-color: #${c.base01} !important;
		border: 1px solid #${c.base03} !important;
		border-radius: ${radius} !important;
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

	/* the dropdowns are custom listbox buttons (found with an outline probe): their
	   shown value ("Any format", "Anytime") was Google's placeholder grey */
	[aria-haspopup],
	[aria-haspopup] *,
	[role="combobox"],
	[role="combobox"] * {
		color: #${c.base05} !important;
	}
}

/* news.google.com: no dark mode of its own; after the flattening above, links
   (headlines, topic tabs) read as bright text with the accent on hover, not a
   page of blue links; stories get a hover surface, the search field the raised
   surface */
@-moz-document domain("news.google.com") {
	:is(a, a span, [role="link"]) {
		color: #${c.base06} !important;
	}

	:is(a, [role="link"]):hover,
	:is(a, [role="link"]):hover span {
		color: #${c.base0D} !important;
	}

	/* sources, bylines and times one step down */
	time {
		color: ${muted} !important;
	}

	article {
		border-radius: ${radius} !important;
	}

	article:hover {
		background-color: ${hover} !important;
	}

	/* the search field: its form is the raised surface, the input inside is clear */
	form:has(input[type="text"]) {
		background-color: #${c.base01} !important;
		border: 1px solid #${c.base03} !important;
		border-radius: 24px !important;
	}

	input[type="text"] {
		background: transparent !important;
		border: none !important;
	}

	/* pill links ("See more headlines") keep a quiet outline */
	a[role="button"] {
		border: 1px solid #${c.base03} !important;
		border-radius: 999px !important;
	}

	/* every rule Google draws in light grey (header, nav bar) */
	* {
		border-color: #${c.base03} !important;
	}

	/* selected topic tab: accent text and underline, not a tinted block */
	html [role="tab"][aria-selected="true"],
	html [aria-current="page"] {
		background-color: transparent !important;
		border-bottom: 2px solid #${c.base0D} !important;
		color: #${c.base0D} !important;
	}

	html [role="tab"][aria-selected="true"] *,
	html [aria-current="page"] * {
		color: #${c.base0D} !important;
	}

	/* the sign-in call-to-action links ("Picks for you", the "More news" row) have
	   no child element and lost their label: draw it, as a pill like the header one */
	a[href*="ServiceLogin"]:not(:has(*)) {
		display: flex !important;
		align-items: center;
		justify-content: center;
		min-height: 48px;
		border-radius: 999px !important;
	}

	a[href*="ServiceLogin"]:not(:has(*))::before {
		content: "Sign in";
		color: #${c.base06};
	}

	/* the weather card paints its own white and stacks its slides: the card (found
	   as the level-4 ancestor of its buttons with an outline probe on 2026-11-13;
	   structural, so re-probe if Google's DOM changes) and everything
	   in it is an opaque raised surface. The page header (its icon buttons matched
	   too and got a lighter box) and any story list are excluded. */
	*:has(> * > * > * > button):not(header, [role="banner"], header *, [role="banner"] *, :has(input, article)),
	*:has(> * > * > * > button):not(header, [role="banner"], header *, [role="banner"] *, :has(input, article)) * {
		background-color: #${c.base01} !important;
		background-image: none !important;
		border-color: transparent !important;
	}

	/* the rule above on every element made Google's transparent borders visible:
	   the card's 9px left edge showed as a grey bar and the apps-grid button got a
	   ring; both go back to transparent */
	[aria-label*="apps" i],
	[aria-label*="apps" i] * {
		border-color: transparent !important;
	}
}

/* translate.google.com: the source textarea is clear inside its panel (Google's
   own surfaces otherwise), quiet outlines on the mode chips, the selected
   language tab is accent text on the page (its underline stays), and Google's dim
   greys (counter, feedback link, History/Saved labels) take the text colour */
@-moz-document domain("translate.google.com") {
	textarea {
		background: transparent !important;
		border: none !important;
	}

	button,
	[role="tab"],
	[role="button"] {
		border-color: #${c.base03} !important;
	}

	html [role="tab"][aria-selected="true"] {
		background-color: transparent !important;
		color: #${c.base0D} !important;
	}

	html [role="tab"][aria-selected="true"] * {
		color: #${c.base0D} !important;
	}

	:is(span, div, label, p):not([role="tab"], [role="tab"] *) {
		color: #${c.base05} !important;
	}

	[role="button"],
	[role="button"] * {
		color: #${c.base05} !important;
	}

	/* inactive language tabs: the text colour, not Google's dim grey */
	[role="tab"]:not([aria-selected="true"]),
	[role="tab"]:not([aria-selected="true"]) * {
		color: #${c.base05} !important;
	}

	/* icons inside buttons (the source-box pencil was near-black), not the logo */
	button svg,
	[role="button"] svg,
	[aria-label*="andwriting" i] svg,
	[aria-label*="eyboard" i] svg {
		fill: currentColor !important;
		color: #${c.base05} !important;
	}

	/* the "Translation" placeholder is aria-hidden, which the font rule skips
	   (it is there to protect icon-font ligatures, so icon-like classes stay out) */
	[aria-hidden="true"]:not(svg, [class*="icon" i], [class*="material" i], [class*="symbol" i], [class*="glyph" i]) {
		font-family: "${sans}", sans-serif !important;
	}
}

/* accounts.google.com sign-in pages (not its embedded widgets): Google's own
   grey dark mode is replaced by the palette (flattened above). The text field
   keeps Google's notched outline (drawn by its own boxes, recoloured to the
   quiet border) so the floating label stays clear of it; both buttons take the
   raised surface */
@-moz-document url-prefix("https://accounts.google.com/v3/signin"), url-prefix("https://accounts.google.com/signin"), url-prefix("https://accounts.google.com/ServiceLogin") {
	html,
	body {
		background-color: #${c.base00} !important;
	}

	* {
		border-color: #${c.base03} !important;
	}

	input[type="email"],
	input[type="text"],
	input[type="password"] {
		background: transparent !important;
		color: #${c.base06} !important;
	}

	/* the three buttons ("Forgot email?", "Create account", "Next") are plain
	   button elements (outline probe): text buttons in accent, no pill */
	button {
		background-color: transparent !important;
		border: none !important;
		border-radius: 999px !important;
		color: #${c.base0D} !important;
	}

	button * {
		color: inherit !important;
	}

	/* the floating label is wider in the mono font than Google's notch, so the
	   focused outline ran through its text (verified on a zoomed shot): an opaque
	   page-coloured label knocks the line out */
	label,
	label *,
	[class*="label" i],
	*:has(> input) > :not(input),
	*:has(> input) > :not(input) * {
		background-color: #${c.base00} !important;
	}

	label {
		padding: 0 4px !important;
	}

	/* the primary action keeps the accent fill (Google's ids for the identifier
	   and password steps; if they change, Next falls back to an accent text button) */
	#identifierNext button,
	#passwordNext button {
		background-color: #${c.base0D} !important;
		color: #${c.base07} !important;
	}

	button:hover {
		background-color: ${hover} !important;
	}

	#identifierNext button:hover,
	#passwordNext button:hover {
		background-color: color-mix(in srgb, #${c.base0D} 85%, #${c.base07}) !important;
	}

	/* the focused field's notched outline is the accent (it was forced grey above) */
	*:has(input:focus) * {
		border-color: #${c.base0D} !important;
	}
}

/* Google's embedded "Sign in with Google" button (an accounts.google.com/gsi
   frame inside other google.com pages): the raised surface, bright label */
@-moz-document url-prefix("https://accounts.google.com/gsi/") {
	html,
	body {
		background: transparent !important;
	}

	[role="button"] {
		background-color: #${c.base01} !important;
		border: 1px solid #${c.base03} !important;
		color: #${c.base06} !important;
	}

	[role="button"] * {
		color: #${c.base06} !important;
	}
}
		'';
	};
}
