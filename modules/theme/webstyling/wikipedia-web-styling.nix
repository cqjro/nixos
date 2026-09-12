{ ... }:
{
	flake.modules.homeManager."wikipedia-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."wikipedia.org" = ''
:root {
	color-scheme: dark !important;

	/* Wikipedia Codex design tokens */
	--color-base: var(--stylix-text) !important;
	--color-base--emphasized: var(--stylix-text) !important;
	--color-subtle: var(--stylix-text-dim) !important;
	--color-progressive: var(--stylix-brand) !important;
	--color-progressive--hover: var(--stylix-text) !important;
	--color-progressive--active: var(--stylix-text) !important;
	--color-progressive--focus: var(--stylix-brand) !important;
	--color-link: var(--stylix-brand) !important;
	--color-link--visited: var(--stylix-secondary) !important;
	--color-link--hover: var(--stylix-text) !important;
	--color-link--active: var(--stylix-text) !important;
	--color-destructive: var(--stylix-danger) !important;
	--color-warning: var(--stylix-warning) !important;
	--color-success: var(--stylix-success) !important;
	--background-color-base: var(--stylix-bg) !important;
	--background-color-canvas: var(--stylix-bg) !important;
	--background-color-canvas--sub: var(--stylix-surface) !important;
	--background-color-neutral: var(--stylix-hover) !important;
	--background-color-neutral-subtle: var(--stylix-surface) !important;
	--background-color-interactive: var(--stylix-hover) !important;
	--background-color-interactive-subtle: var(--stylix-surface) !important;
	--background-color-primary-subtle: var(--stylix-surface) !important;
	--background-color-progressive-subtle: var(--stylix-hover) !important;
	--background-color-destructive-subtle: var(--stylix-hover) !important;
	--background-color-warning-subtle: var(--stylix-hover) !important;
	--border-color-base: var(--stylix-border) !important;
	--border-color-subtle: var(--stylix-border) !important;
	--border-color-transparent: transparent !important;
	--border-color-interactive: var(--stylix-brand) !important;
	--border-color-progressive: var(--stylix-brand) !important;
	--border-color-destructive: var(--stylix-danger) !important;
	--emphasized-border-color: var(--stylix-border) !important;
	--box-shadow-drag: 0 0 0 1px var(--stylix-border) !important;
	--box-shadow-sticky-header: 0 1px color-mix(in srgb, var(--stylix-border) 70%, transparent) !important;
	--box-shadow-inset-small: inset 0 0 0 1px var(--stylix-border) !important;
}

html,
body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

h1, h2, h3, h4, h5, h6,
.mw-headline {
	color: var(--stylix-text) !important;
}

/* page container + title bars */
.vector-header-container,
.mw-page-container,
.mw-body,
.vector-page-titlebar,
.vector-sticky-header {
	background-color: var(--stylix-bg) !important;
	border-color: var(--stylix-border) !important;
}

/* infoboxes, tables, navboxes */
.infobox,
.wikitable,
table.metadata,
.navbox {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

.wikitable th,
.wikitable td,
.infobox th,
.infobox td,
.navbox th,
.navbox td {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

/* hatnotes / disambiguation / main-article boxes */
.hatnote,
.dablink {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

/* sidebars & portals */
.navbox,
.vertical-navbox,
.sidebar {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

/* code blocks */
pre,
code,
.mw-code {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

/* edit summary / search inputs */
input,
textarea,
select {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

input::placeholder,
textarea::placeholder {
	color: var(--stylix-text-dim) !important;
}

/* search suggestions box */
.mw-searchresults-has-iw .results-info,
.suggestions,
.mw-rcfilters-ui-filterWrapperWidget {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

/* footer */
.mw-footer-container,
footer {
	background-color: var(--stylix-surface) !important;
	border-top-color: var(--stylix-border) !important;
}
		'';
	};
}