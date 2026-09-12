{ ... }:
{
	flake.modules.homeManager."brave-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."search.brave.com" = let
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
	color: #${c.base0D} !important;
}

/* header / top bar */
header,
.sidebar,
.nav,
[class*="header"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* search box */
input,
textarea,
select,
[class*="search-input"],
[class*="SearchBar"] {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

button,
[type="button"] {
	background-color: #${c.base02} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

/* result cards */
.result,
.snippet,
.card,
[class*="result"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

.result-header .title,
[class*="result"] [class*="title"],
.snippet-title {
	color: #${c.base05} !important;
}

/* summary box on top */
[class*="summary"],
[class*="answer"] {
	background-color: #${c.base02} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* footer */
footer {
	background-color: #${c.base01} !important;
	border-top-color: #${c.base03} !important;
	color: #${c.base04} !important;
}

mark,
::selection {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}
		'';
	};
}