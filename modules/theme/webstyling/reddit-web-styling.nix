{ ... }:
{
	flake.modules.homeManager."reddit-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."reddit.com" = ''
:root,
html[data-theme],
html[data-theme="dark"],
html[data-theme="light"] {
	color-scheme: dark !important;

	/* Reddit design tokens */
	--background-container: var(--stylix-bg) !important;
	--background-container-hover: var(--stylix-hover) !important;
	--background-raised: var(--stylix-surface) !important;
	--background-secondary: var(--stylix-surface) !important;
	--color-secondary-onlight: var(--stylix-text) !important;
	--color-primary-onlight: var(--stylix-text) !important;
	--color-primary-plain: var(--stylix-brand) !important;
	--color-tertiary-plain: var(--stylix-text-dim) !important;
	--color-tertiary-onlight: var(--stylix-text-dim) !important;
	--color-neutral-header-text: var(--stylix-text) !important;
	--color-neutral-body-text: var(--stylix-text) !important;
	--color-neutral-secondary-text: var(--stylix-text-dim) !important;
	--color-neutral-bg-weak: var(--stylix-surface) !important;
	--color-neutral-bg-weaker: var(--stylix-bg) !important;
	--color-neutral-border-strong: var(--stylix-border) !important;
	--color-neutral-border-medium: var(--stylix-border) !important;
	--color-neutral-border-weak: var(--stylix-border) !important;
	--color-brand-primary: var(--stylix-brand) !important;
	--color-brand-primary-hover: var(--stylix-secondary) !important;
	--color-brand-primary-onlight: var(--stylix-brand) !important;
	--color-brand-primary-plain: var(--stylix-brand) !important;
	--color-brand-primary-plain-hover: var(--stylix-secondary) !important;
	--color-interactive-hover: var(--stylix-hover) !important;
	--color-ui-active: var(--stylix-hover) !important;
	--color-highlight: var(--stylix-hover) !important;
	--color-overlay: var(--stylix-surface) !important;
	--color-global-bg-weak: var(--stylix-bg) !important;

	/* legacy reddit tokens */
	--newCommunityTheme-body: var(--stylix-bg) !important;
	--newCommunityTheme-bodyText: var(--stylix-text) !important;
	--newCommunityTheme-actionIcon: var(--stylix-text-dim) !important;
	--newCommunityTheme-button: var(--stylix-brand) !important;
	--newCommunityTheme-buttontext: var(--stylix-bg) !important;
	--newCommunityTheme-line: var(--stylix-border) !important;
	--newCommunityTheme-post: var(--stylix-surface) !important;
	--newCommunityTheme-postInside: var(--stylix-surface) !important;
	--newCommunityTheme-titleText: var(--stylix-text) !important;
	--newCommunityTheme-linkText: var(--stylix-brand) !important;
	--newCommunityTheme-header: var(--stylix-surface) !important;
	--newCommunityTheme-banner-backgroundImage: var(--stylix-surface) !important;
	--newCommunityTheme-canvas: var(--stylix-bg) !important;
}

body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

a,
.link .linkflairlabel {
	color: var(--stylix-brand) !important;
}

h1, h2, h3, h4, h5, h6 {
	color: var(--stylix-text) !important;
}

/* search bar + inputs */
input,
textarea,
select,
#search-container,
[class*="search"] input {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

/* main post cards */
.shreddit-post,
[class*="post"],
.thing {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

.thing .entry .title {
	color: var(--stylix-text) !important;
}

.sidebar,
[class*="sidebar"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

hr {
	border-color: var(--stylix-border) !important;
}
		'';
	};
}