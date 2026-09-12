{ ... }:
{
	flake.modules.homeManager."instagram-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."instagram.com" = let
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

h1, h2, h3, h4 {
	color: #${c.base05} !important;
}

a {
	color: #${c.base05} !important;
}

/* Instagram paints almost everything with inline styles, so catch the common
   near-white paint colours directly on the big containers. */
div[style*="rgb(245, 245, 245)"],
div[style*="rgb(250, 250, 250)"],
div[style*="rgb(255, 255, 255)"],
div[style*="rgb(250,250,250)"],
div[style*="rgb(255,255,255)"],
div[style*="#FAFAFA"],
div[style*="#fafafa"] {
	background-color: #${c.base00} !important;
}

/* sidebar / rails / panels */
div[role="presentation"],
aside,
[role="navigation"],
[role="main"] {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

/* inputs (login/search/direct message) */
input,
textarea,
[class*="x2lah0s"],
[role="textbox"] {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* black icons/text get restyled */
svg[stroke="#000"] {
	stroke: #${c.base05} !important;
}

svg[fill="#000"] {
	fill: #${c.base05} !important;
}

div[style*="color: rgb(0, 0, 0)"],
div[style*="color: rgb(38, 38, 38)"],
div[style*="color: #000"],
div[style*="color: #262626"] {
	color: #${c.base05} !important;
}
		'';
	};
}