{ ... }:
{
	flake.modules.homeManager."google-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."google.com" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;

	/* hashed surface tokens google.com uses for the header, chips and the AI
	   "ask anything" gradient -- override so they resolve to the palette */
	--xhUGwc: #${c.base00} !important;
	--cIehld: #${c.base01} !important;
	--XKMDxc: #${c.base02} !important;
	--jINu6c: #${c.base04} !important;
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
textarea {
	background: transparent !important;
	border: none !important;
	color: #${c.base05} !important;
}

input[type="text"]::placeholder,
input.gLFyf::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* "people also ask" dropdown hover + "people also search for" chips + show-all */
.fxvkXe,
.p8Jhnd {
	background-color: #${c.base02} !important;
}

/* page footer */
.f6F9Be {
	background: #${c.base01} !important;
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