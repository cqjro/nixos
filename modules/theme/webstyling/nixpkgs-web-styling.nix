{ ... }:
{
	flake.modules.homeManager."nixpkgs-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."search.nixos.org" = ''
:root {
	color-scheme: dark !important;
}

html,
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

/* top search bar */
input,
textarea,
select,
[class*="search"],
[class*="Search"] {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

input::placeholder,
textarea::placeholder {
	color: var(--stylix-text-dim) !important;
}

/* nav / header */
header,
nav,
[class*="header"],
[class*="navbar"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

/* result list (packages/options tables) */
table,
thead,
tr,
th,
td {
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

th {
	background-color: var(--stylix-surface) !important;
}

tbody tr:hover {
	background-color: var(--stylix-hover) !important;
}

/* package/option rows */
[class*="row"] {
	color: var(--stylix-text) !important;
}

code,
[class*="code"] {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text-dim) !important;
}

/* pill selectors / chips */
[class*="chip"],
[class*="badge"],
[class*="pill"] {
	background-color: var(--stylix-hover) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

mark,
::selection {
	background-color: var(--stylix-brand) !important;
	color: var(--stylix-bg) !important;
}

footer {
	background-color: var(--stylix-surface) !important;
	border-top-color: var(--stylix-border) !important;
	color: var(--stylix-text-dim) !important;
}
		'';

		zenWebStyling.siteStyles."nixos.org" = ''
:root {
	color-scheme: dark !important;
}

html,
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

header,
nav,
footer,
[class*="header"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

input,
textarea,
select,
button {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}
		'';
	};
}