{ ... }:
{
	flake.modules.homeManager."reddit-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."reddit.com" = let
			c = config.lib.stylix.colors;
		in ''
:root,
html.theme-rpl,
html.theme-beta,
html.theme-dark,
html.theme-light {
	color-scheme: dark !important;

	/* Reddit Shreddit design tokens: --color-* (declared on <html class="theme-rpl …">) */
	--color-neutral-background: #${c.base00} !important;
	--color-neutral-background-weak: #${c.base01} !important;
	--color-neutral-background-medium: #${c.base01} !important;
	--color-neutral-background-strong: #${c.base01} !important;
	--color-neutral-background-hover: #${c.base02} !important;
	--color-neutral-background-selected: #${c.base02} !important;
	--color-secondary-background: #${c.base01} !important;
	--color-secondary-background-hover: #${c.base02} !important;
	--color-secondary-background-selected: #${c.base02} !important;
	--color-transparent-background-hover: #${c.base02} !important;

	--color-neutral-border: #${c.base03} !important;
	--color-neutral-border-weak: color-mix(in srgb, #${c.base03} 55%, transparent) !important;
	--color-neutral-border-medium: #${c.base03} !important;
	--color-neutral-border-strong: #${c.base03} !important;

	--color-neutral-content: #${c.base05} !important;
	--color-neutral-content-strong: #${c.base05} !important;
	--color-neutral-content-weak: #${c.base04} !important;
	--color-neutral-content-disabled: #${c.base03} !important;
	--color-secondary: #${c.base04} !important;
	--color-secondary-weak: #${c.base04} !important;
	--color-secondary-hover: #${c.base05} !important;
	--color-secondary-plain: #${c.base04} !important;
	--color-secondary-plain-hover: #${c.base05} !important;
	--color-secondary-plain-weak: #${c.base04} !important;

	/* legacy tone ladder */
	--color-tone-1: #${c.base05} !important;
	--color-tone-2: #${c.base04} !important;
	--color-tone-3: #${c.base04} !important;
	--color-tone-4: #${c.base03} !important;
	--color-tone-5: #${c.base02} !important;
	--color-tone-6: #${c.base01} !important;
	--color-tone-7: #${c.base00} !important;

	/* brand / accent */
	--color-primary: #${c.base0D} !important;
	--color-primary-hover: #${c.base0E} !important;
	--color-primary-visited: #${c.base0E} !important;
	--color-primary-plain: #${c.base0D} !important;
	--color-primary-plain-hover: #${c.base0E} !important;
	--color-primary-background: #${c.base0D} !important;
	--color-primary-background-hover: #${c.base0E} !important;
	--color-primary-onBackground: #${c.base00} !important;
	--color-a-default: #${c.base0D} !important;
	--color-brand-background: #${c.base0D} !important;
	--color-brand-background-hover: #${c.base0E} !important;
	--color-brand-onBackground: #${c.base00} !important;
	--color-global-orangered: #${c.base0D} !important;
	--shreddit-color-wordmark: #${c.base05} !important;

	/* semantic */
	--color-danger-background: #${c.base02} !important;
	--color-danger-content: #${c.base08} !important;
	--color-success-background: #${c.base02} !important;
	--color-success-content: #${c.base0B} !important;
	--color-warning-background: #${c.base02} !important;
	--color-warning-content: #${c.base09} !important;

	/* voting */
	--color-upvote-content: #${c.base0D} !important;
	--color-upvote-background: #${c.base02} !important;
	--color-upvote-disabled: #${c.base03} !important;
	--color-downvote-content: #${c.base0E} !important;
	--color-downvote-background: #${c.base02} !important;
	--color-downvote-disabled: #${c.base03} !important;

	--color-scrim: #${c.base00} !important;
	--color-scrim-background: #${c.base01} !important;
	--color-ui-canvas: #${c.base00} !important;
	--color-ui-modalbackground: #${c.base01} !important;
	--color-interactive-hover: #${c.base02} !important;
	--color-interactive-pressed: #${c.base02} !important;
	--color-interactive-focused: #${c.base0D} !important;

	/* buttons + content surfaces */
	--button-color-background: #${c.base01} !important;
	--button-color-background-default: #${c.base01} !important;
	--button-color-background-hover: #${c.base02} !important;
	--button-color-text-default: #${c.base05} !important;
	--button-color-text-hover: #${c.base05} !important;
	--shreddit-content-background: transparent !important;

	/* legacy newCommunityTheme (old reddit) */
	--newCommunityTheme-body: #${c.base00} !important;
	--newCommunityTheme-bodyText: #${c.base05} !important;
	--newCommunityTheme-titleText: #${c.base05} !important;
	--newCommunityTheme-linkText: #${c.base0D} !important;
	--newCommunityTheme-post: #${c.base01} !important;
	--newCommunityTheme-postInside: #${c.base01} !important;
	--newCommunityTheme-button: #${c.base0D} !important;
	--newCommunityTheme-buttontext: #${c.base00} !important;
	--newCommunityTheme-line: #${c.base03} !important;
	--newCommunityTheme-header: #${c.base01} !important;
	--newCommunityTheme-canvas: #${c.base00} !important;
}

body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

a {
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
shreddit-post,
shreddit-xpost,
.thing,
[class*="post"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

.thing .entry .title {
	color: #${c.base05} !important;
}

/* sidebars */
#left-sidebar-container,
#right-sidebar-container,
#right-sidebar-contents aside,
reddit-sidebar-nav,
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