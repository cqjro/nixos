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

/* google.com presents no stable CSS variables; let the site's own dark mode
   paint the large surfaces and only restyle the individual elements below. */

/* the search field itself (not the surrounding pill / dropdown) */
input[type="text"],
input.gLFyf,
textarea {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input[type="text"]::placeholder,
input.gLFyf::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
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