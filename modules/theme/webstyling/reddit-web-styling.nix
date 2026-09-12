{ ... }:
{
	flake.modules.homeManager."reddit-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."reddit.com" = let
			c = config.lib.stylix.colors;
		in ''
:root,
html[data-theme],
html[data-theme="dark"],
html[data-theme="light"] {
	color-scheme: dark !important;

	/* Reddit design tokens */
	--background-container: #${c.base00} !important;
	--background-container-hover: #${c.base02} !important;
	--background-raised: #${c.base01} !important;
	--background-secondary: #${c.base01} !important;
	--color-secondary-onlight: #${c.base05} !important;
	--color-primary-onlight: #${c.base05} !important;
	--color-primary-plain: #${c.base0D} !important;
	--color-tertiary-plain: #${c.base04} !important;
	--color-tertiary-onlight: #${c.base04} !important;
	--color-neutral-header-text: #${c.base05} !important;
	--color-neutral-body-text: #${c.base05} !important;
	--color-neutral-secondary-text: #${c.base04} !important;
	--color-neutral-bg-weak: #${c.base01} !important;
	--color-neutral-bg-weaker: #${c.base00} !important;
	--color-neutral-border-strong: #${c.base03} !important;
	--color-neutral-border-medium: #${c.base03} !important;
	--color-neutral-border-weak: #${c.base03} !important;
	--color-brand-primary: #${c.base0D} !important;
	--color-brand-primary-hover: #${c.base0E} !important;
	--color-brand-primary-onlight: #${c.base0D} !important;
	--color-brand-primary-plain: #${c.base0D} !important;
	--color-brand-primary-plain-hover: #${c.base0E} !important;
	--color-interactive-hover: #${c.base02} !important;
	--color-ui-active: #${c.base02} !important;
	--color-highlight: #${c.base02} !important;
	--color-overlay: #${c.base01} !important;
	--color-global-bg-weak: #${c.base00} !important;

	/* legacy reddit tokens */
	--newCommunityTheme-body: #${c.base00} !important;
	--newCommunityTheme-bodyText: #${c.base05} !important;
	--newCommunityTheme-actionIcon: #${c.base04} !important;
	--newCommunityTheme-button: #${c.base0D} !important;
	--newCommunityTheme-buttontext: #${c.base00} !important;
	--newCommunityTheme-line: #${c.base03} !important;
	--newCommunityTheme-post: #${c.base01} !important;
	--newCommunityTheme-postInside: #${c.base01} !important;
	--newCommunityTheme-titleText: #${c.base05} !important;
	--newCommunityTheme-linkText: #${c.base0D} !important;
	--newCommunityTheme-header: #${c.base01} !important;
	--newCommunityTheme-banner-backgroundImage: #${c.base01} !important;
	--newCommunityTheme-canvas: #${c.base00} !important;
}

body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

a,
.link .linkflairlabel {
	color: #${c.base0D} !important;
}

h1, h2, h3, h4, h5, h6 {
	color: #${c.base05} !important;
}

/* search bar + inputs */
input,
textarea,
select,
#search-container,
[class*="search"] input {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

/* main post cards */
.shreddit-post,
[class*="post"],
.thing {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

.thing .entry .title {
	color: #${c.base05} !important;
}

.sidebar,
[class*="sidebar"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

hr {
	border-color: #${c.base03} !important;
}
		'';
	};
}