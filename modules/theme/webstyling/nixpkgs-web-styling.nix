{ ... }:
{
	flake.modules.homeManager."nixpkgs-web-styling" = { config, lib, ... }: let
		c = config.lib.stylix.colors;
		search = ''
:root {
	color-scheme: dark !important;

	/* search.nixos.org design tokens (Elm app, index.scss) */
	--background-color: #${c.base00} !important;
	--text-color: #${c.base05} !important;
	--text-color-light: #${c.base04} !important;
	--text-color-warning: #${c.base09} !important;
	--line-color: #${c.base03} !important;
	--hover-background: color-mix(in srgb, #${c.base02} 30%, transparent) !important;
	--hovered-item-background: #${c.base02} !important;
	--selected-item-background: #${c.base0D} !important;
	--selected-item-color: #${c.base00} !important;
	--button-background: #${c.base01} !important;
	--button-hover-background: #${c.base02} !important;
	--button-active-background: #${c.base02} !important;
	--button-active-hover-background: #${c.base03} !important;
	--terminal-background: #${c.base01} !important;
	--terminal-color: #${c.base05} !important;
	--link-color: #${c.base0D} !important;
	--light-blue: #${c.base0D} !important;
	--dark-blue: #${c.base0E} !important;
	--headerbar-background-color: #${c.base01} !important;
	--badge-background: #${c.base02} !important;
	--color-hover-tab: #${c.base02} !important;
	--color-active-tab: #${c.base02} !important;
	--color-active-hover-tab: #${c.base03} !important;
	--search-result-title-color: #${c.base0D} !important;
	--search-result-short-details-color: #${c.base04} !important;
	--search-sidebar-container-border-color: #${c.base03} !important;
	--search-sidebar-link-color: #${c.base05} !important;
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

/* navbar + header */
header,
nav,
.navbar,
.navbar > .navbar-inner {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* search box + typeahead */
#search-query-input,
input,
textarea,
select,
.typeahead-suggestions,
.typeahead-item {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* results */
.search-results table,
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

/* terminal / install blocks */
pre,
code,
.terminal {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
}

/* pills / badges */
.badge,
.label {
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
		nixosOrg = ''
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

/* nixos.org is compiled Tailwind utilities (no CSS variables) -- target surfaces directly */
header,
nav,
footer {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* active / inactive nav underlines are the brand-blue tints */
.text-secondary-afghani-blue-45 {
	color: #${c.base0D} !important;
}

.text-secondary-afghani-blue-15 {
	color: #${c.base0E} !important;
}

.bg-secondary-afghani-blue-95,
.bg-secondary-afghani-blue-85 {
	background-color: #${c.base02} !important;
}

.border-secondary-afghani-blue-95,
.border-secondary-afghani-blue-85,
.border-secondary-afghani-blue-55 {
	border-color: #${c.base0D} !important;
}

input,
textarea,
select {
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

pre,
code {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

blockquote {
	background-color: #${c.base01} !important;
	border-color: #${c.base0D} !important;
}
		'';
	in {
		zenWebStyling.siteStyles."search.nixos.org" = search;
		zenWebStyling.siteStyles."nixos.org" = nixosOrg;
	};
}