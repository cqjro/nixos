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

/* top header */
header,
#gb {
	background-color: #${c.base00} !important;
}

/* the search bar pill carries the surface */
.RNNXgb {
	background: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* the text field inside stays transparent -- no background/border of its own */
input[type="text"],
input.gLFyf,
input[name="q"],
textarea,
textarea[name="q"],
#input {
	background: transparent !important;
	border: none !important;
	box-shadow: none !important;
	color: #${c.base05} !important;
}

input[type="text"]::placeholder,
input.gLFyf::placeholder,
input[name="q"]::placeholder,
textarea::placeholder,
#input::placeholder {
	color: #${c.base04} !important;
}

/* AI overview "ask anything" plate gradient (uses element-scoped var) */
V {
	background: #${c.base00} !important;
	background-image: none !important;
}

/* "show all" pill on the AI overview sources row */
.YoEHmf {
	background-color: #${c.base02} !important;
	color: #${c.base04} !important;
}

/* expanded AI sources card */
.XEqVsf {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* search suggestions dropdown */
.ajZCb {
	background: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* "people also ask" dropdown hover + "people also search for" chips */
.fxvkXe,
.p8Jhnd {
	background-color: #${c.base02} !important;
}

/* page footer */
.f6F9Be {
	background: #${c.base00} !important;
}

/* result titles, urls, snippets */
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

mark {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}
		'';
	};
}