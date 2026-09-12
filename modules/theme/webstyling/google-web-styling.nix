{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."google.com" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;
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

/* google.com exposes only per-build hashed CSS variables, so theme via classes */

/* search box + omnibox + autocomplete dropdown */
.RNNXgb,
.A8SBwf,
.gLFyf,
input[type="text"],
textarea {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input[type="text"]::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* top tab bar */
#hdtb,
#searchform {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* result cards */
#rso > .g,
#rso > .MjjYud,
.hlcw0c,
.Ww4FFb,
.g-blk {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* titles, urls, snippets */
h3,
.LC20lb,
.DKV0Md {
	color: #${c.base05} !important;
}

cite,
.VuuXrf,
.NJjxre,
.tjvcx {
	color: #${c.base04} !important;
}

.VwiC3b,
.lEBKkf,
.IsZvec,
.aCOpRe {
	color: #${c.base04} !important;
}

/* AI overview / featured answer containers */
.M8OgIe,
.Kevs9.SLPe5b,
.olrp5b,
.xpdopen,
.kp-blk,
[data-testid="ai-answer-wrapper"] {
	background-color: #${c.base02} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* knowledge panel / right rail */
.kp-wholepage,
.rhsblk,
.kno-kp {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
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