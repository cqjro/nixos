{ ... }:
{
	flake.modules.homeManager."wikipedia-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."wikipedia.org" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;

	/* Wikipedia / MediaWiki Codex design tokens (Vector 2022) */
	--color-base: #${c.base05} !important;
	--color-base--hover: #${c.base05} !important;
	--color-emphasized: #${c.base05} !important;
	--color-neutral: #${c.base04} !important;
	--color-subtle: #${c.base04} !important;
	--color-placeholder: #${c.base04} !important;
	--color-disabled: #${c.base03} !important;
	--color-disabled-emphasized: #${c.base03} !important;
	--color-inverted: #${c.base00} !important;

	--color-progressive: #${c.base0D} !important;
	--color-progressive--hover: #${c.base0E} !important;
	--color-progressive--active: #${c.base0E} !important;
	--color-progressive--focus: #${c.base0D} !important;
	--color-visited: #${c.base0E} !important;
	--color-visited--hover: #${c.base0E} !important;
	--color-visited--active: #${c.base0E} !important;
	--color-link: #${c.base0D} !important;
	--color-link--visited: #${c.base0E} !important;
	--color-destructive: #${c.base08} !important;
	--color-error: #${c.base08} !important;
	--color-warning: #${c.base09} !important;
	--color-success: #${c.base0B} !important;

	--color-icon-progressive: #${c.base0D} !important;
	--color-icon-error: #${c.base08} !important;
	--color-icon-warning: #${c.base09} !important;
	--color-icon-success: #${c.base0B} !important;

	--background-color-base: #${c.base00} !important;
	--background-color-neutral: #${c.base02} !important;
	--background-color-neutral-subtle: #${c.base01} !important;
	--background-color-interactive: #${c.base02} !important;
	--background-color-interactive-subtle: #${c.base01} !important;
	--background-color-progressive-subtle: #${c.base02} !important;
	--background-color-destructive-subtle: #${c.base02} !important;
	--background-color-warning-subtle: #${c.base02} !important;
	--background-color-success-subtle: #${c.base02} !important;

	--border-color-base: #${c.base03} !important;
	--border-color-emphasized: #${c.base02} !important;
	--border-color-subtle: #${c.base03} !important;
	--border-color-muted: #${c.base03} !important;
	--border-color-divider: #${c.base03} !important;
	--border-color-interactive: #${c.base0D} !important;
	--border-color-progressive: #${c.base0D} !important;
	--border-color-destructive: #${c.base08} !important;
	--border-color-inverted: #${c.base05} !important;

	/* logo / icon inversion for dark mode */
	--filter-invert-icon: invert(1) !important;
}

html,
body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

h1, h2, h3, h4, h5, h6,
.mw-headline {
	color: #${c.base05} !important;
}

/* page container + title bars */
.vector-header-container,
.mw-page-container,
.mw-body,
.vector-page-titlebar,
.vector-sticky-header {
	background-color: #${c.base00} !important;
	border-color: #${c.base03} !important;
}

/* infoboxes, tables, navboxes */
.infobox,
.wikitable,
table.metadata,
.navbox {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

.wikitable th,
.wikitable td,
.infobox th,
.infobox td,
.navbox th,
.navbox td {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* hatnotes / disambiguation / main-article boxes */
.hatnote,
.dablink {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* sidebars & portals */
.navbox,
.vertical-navbox,
.sidebar {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* code blocks */
pre,
code,
.mw-code {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

/* edit summary / search inputs */
input,
textarea,
select {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

input::placeholder,
textarea::placeholder {
	color: #${c.base04} !important;
}

/* search suggestions box */
.suggestions,
.mw-rcfilters-ui-filterWrapperWidget {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

/* footer */
.mw-footer-container,
footer {
	background-color: #${c.base01} !important;
	border-top-color: #${c.base03} !important;
}
		'';
	};
}