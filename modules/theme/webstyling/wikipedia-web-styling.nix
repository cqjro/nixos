{ ... }:
{
	flake.modules.homeManager."wikipedia-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."wikipedia.org" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;

	/* Wikipedia Codex design tokens */
	--color-base: #${c.base05} !important;
	--color-base--emphasized: #${c.base05} !important;
	--color-subtle: #${c.base04} !important;
	--color-progressive: #${c.base0D} !important;
	--color-progressive--hover: #${c.base05} !important;
	--color-progressive--active: #${c.base05} !important;
	--color-progressive--focus: #${c.base0D} !important;
	--color-link: #${c.base0D} !important;
	--color-link--visited: #${c.base0E} !important;
	--color-link--hover: #${c.base05} !important;
	--color-link--active: #${c.base05} !important;
	--color-destructive: #${c.base08} !important;
	--color-warning: #${c.base09} !important;
	--color-success: #${c.base0B} !important;
	--background-color-base: #${c.base00} !important;
	--background-color-canvas: #${c.base00} !important;
	--background-color-canvas--sub: #${c.base01} !important;
	--background-color-neutral: #${c.base02} !important;
	--background-color-neutral-subtle: #${c.base01} !important;
	--background-color-interactive: #${c.base02} !important;
	--background-color-interactive-subtle: #${c.base01} !important;
	--background-color-primary-subtle: #${c.base01} !important;
	--background-color-progressive-subtle: #${c.base02} !important;
	--background-color-destructive-subtle: #${c.base02} !important;
	--background-color-warning-subtle: #${c.base02} !important;
	--border-color-base: #${c.base03} !important;
	--border-color-subtle: #${c.base03} !important;
	--border-color-transparent: transparent !important;
	--border-color-interactive: #${c.base0D} !important;
	--border-color-progressive: #${c.base0D} !important;
	--border-color-destructive: #${c.base08} !important;
	--emphasized-border-color: #${c.base03} !important;
	--box-shadow-drag: 0 0 0 1px #${c.base03} !important;
	--box-shadow-sticky-header: 0 1px color-mix(in srgb, #${c.base03} 70%, transparent) !important;
	--box-shadow-inset-small: inset 0 0 0 1px #${c.base03} !important;
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
.mw-searchresults-has-iw .results-info,
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