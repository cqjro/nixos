{ ... }:
{
	flake.modules.homeManager."nixpkgs-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."search.nixos.org" = let
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

/* top search bar */
input,
textarea,
select,
[class*="search"],
[class*="Search"] {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* nav / header */
header,
nav,
[class*="header"],
[class*="navbar"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* result list (packages/options tables) */
table,
thead,
tr,
th,
td {
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

th {
	background-color: #${c.base01} !important;
}

tbody tr:hover {
	background-color: #${c.base02} !important;
}

/* package/option rows */
[class*="row"] {
	color: #${c.base05} !important;
}

code,
[class*="code"] {
	background-color: #${c.base01} !important;
	color: #${c.base04} !important;
}

/* pill selectors / chips */
[class*="chip"],
[class*="badge"],
[class*="pill"] {
	background-color: #${c.base02} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

mark,
::selection {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}

footer {
	background-color: #${c.base01} !important;
	border-top-color: #${c.base03} !important;
	color: #${c.base04} !important;
}
		'';

		zenWebStyling.siteStyles."nixos.org" = let
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

header,
nav,
footer,
[class*="header"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

input,
textarea,
select,
button {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}
		'';
	};
}