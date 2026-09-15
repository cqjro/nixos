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
html.theme-light,
/* Shreddit also applies theme classes to an inner root (shreddit-app) */
.theme-rpl,
.theme-beta,
.theme-dark,
.theme-light,
shreddit-app {
	color-scheme: dark !important;

	/* Reddit Shreddit design tokens: --color-* (declared on <html class="theme-rpl …">) */
	--color-pizzaRed: #${c.base0D} !important;
	--color-global-brand-orangered: #${c.base0D} !important;
	--color-global-focus: #${c.base0D} !important;
	/* used by some overlays/headers that refuse to route through any other token */
	--color-global-white: #${c.base00} !important;

	--color-interactive-content-disabled: #${c.base03} !important;
	--color-interactive-background-disabled: color-mix(in srgb, #${c.base02} 70%, transparent) !important;
	--color-interactive-pressed: #${c.base02} !important;
	--color-interactive-hover: #${c.base02} !important;
	--color-interactive-focused: #${c.base0D} !important;

	--color-neutral-background: #${c.base00} !important;
	--color-neutral-background-weak: #${c.base01} !important;
	--color-neutral-background-medium: #${c.base00} !important;
	--color-neutral-background-strong: #${c.base00} !important;
	--color-neutral-background-hover: #${c.base02} !important;
	--color-neutral-background-selected: #${c.base02} !important;
	--color-secondary-background: #${c.base01} !important;
	--color-secondary-background-hover: #${c.base02} !important;
	--color-secondary-background-selected: #${c.base02} !important;
	--color-transparent-background-hover: color-mix(in srgb, #${c.base02} 40%, transparent) !important;

	--color-neutral-border: #${c.base03} !important;
	--color-neutral-border-weak: color-mix(in srgb, #${c.base03} 55%, transparent) !important;
	--color-neutral-border-medium: #${c.base03} !important;
	--color-neutral-border-strong: #${c.base03} !important;

	--color-neutral-content: #${c.base05} !important;
	--color-neutral-content-strong: #${c.base05} !important;
	--color-neutral-content-weak: #${c.base04} !important;
	--color-neutral-content-disabled: #${c.base03} !important;
	--color-secondary: #${c.base04} !important;
	--color-secondary-hover: #${c.base05} !important;
	--color-secondary-weak: #${c.base04} !important;
	--color-secondary-onBackground: #${c.base05} !important;
	--color-secondary-plain: #${c.base04} !important;
	--color-secondary-plain-hover: #${c.base05} !important;
	--color-secondary-plain-weak: #${c.base04} !important;

	/* brand / accent */
	--color-primary: #${c.base0D} !important;
	--color-primary-hover: #${c.base0E} !important;
	--color-primary-visited: #${c.base0E} !important;
	--color-primary-plain: #${c.base0D} !important;
	--color-primary-plain-hover: #${c.base0E} !important;
	--color-primary-background: #${c.base0D} !important;
	--color-primary-background-hover: #${c.base0E} !important;
	--color-primary-background-selected: #${c.base0E} !important;
	--color-primary-onBackground: #${c.base00} !important;
	--color-primary-onBackground-selected: #${c.base00} !important;
	--color-a-default: #${c.base0D} !important;
	--color-brand-background: #${c.base0D} !important;
	--color-brand-background-hover: #${c.base0E} !important;
	--color-brand-onBackground: #${c.base00} !important;
	--color-global-orangered: #${c.base0D} !important;
	--color-action-upvote: #${c.base0D} !important;
	--color-action-downvote: #${c.base0E} !important;
	--color-avatar-gradient: #${c.base0D} !important;
	--color-online: #${c.base0B} !important;
	--color-favorite: #${c.base0A} !important;
	--color-opacity-50: color-mix(in srgb, #${c.base00} 50%, transparent) !important;
	--color-scrim: #${c.base00} !important;
	--color-scrim-background: #${c.base01} !important;
	--color-ui-canvas: #${c.base00} !important;
	--color-ui-modalbackground: #${c.base02} !important;
	--shreddit-color-wordmark: #${c.base05} !important;
	--shreddit-content-background: transparent !important;

	/* semantic */
	--color-danger-background: #${c.base02} !important;
	--color-danger-background-disabled: color-mix(in srgb, #${c.base08} 20%, transparent) !important;
	--color-danger-background-hover: color-mix(in srgb, #${c.base08} 90%, #${c.base00}) !important;
	--color-danger-content: #${c.base08} !important;
	--color-danger-content-default: #${c.base08} !important;
	--color-danger-content-hover: #${c.base0E} !important;
	--color-danger-onBackground: #${c.base00} !important;
	--color-success-content: #${c.base0B} !important;
	--color-success-hover: #${c.base0C} !important;
	--color-success-onBackground: #${c.base00} !important;
	--color-success-background: #${c.base02} !important;
	--color-success-background-hover: color-mix(in srgb, #${c.base0B} 30%, #${c.base02}) !important;
	--color-warning-content: #${c.base0A} !important;
	--color-warning-content-hover: #${c.base09} !important;
	--color-warning-onBackground: #${c.base00} !important;
	--color-warning-background: #${c.base02} !important;
	--color-warning-background-hover: color-mix(in srgb, #${c.base0A} 30%, #${c.base02}) !important;

	/* voting */
	--color-upvote-content: #${c.base0D} !important;
	--color-upvote-onBackground: #${c.base00} !important;
	--color-upvote-background: #${c.base02} !important;
	--color-upvote-background-hover: color-mix(in srgb, #${c.base0D} 35%, #${c.base02}) !important;
	--color-upvote-background-disabled: #${c.base02} !important;
	--color-upvote-disabled: #${c.base03} !important;
	--color-downvote-content: #${c.base0E} !important;
	--color-downvote-content-weak: #${c.base0E} !important;
	--color-downvote-onBackground: #${c.base00} !important;
	--color-downvote-background: #${c.base02} !important;
	--color-downvote-background-hover: color-mix(in srgb, #${c.base0E} 35%, #${c.base02}) !important;
	--color-downvote-background-disabled: #${c.base02} !important;
	--color-downvote-disabled: #${c.base03} !important;

	/* legacy tone ladder */
	--color-tone-1: #${c.base05} !important;
	--color-tone-2: #${c.base05} !important;
	--color-tone-3: #${c.base04} !important;
	--color-tone-4: #${c.base03} !important;
	--color-tone-5: #${c.base02} !important;
	--color-tone-6: #${c.base01} !important;
	--color-tone-7: #${c.base00} !important;

	/* buttons */
	--button-color-background: #${c.base01} !important;
	--button-color-background-default: #${c.base01} !important;
	--button-color-background-hover: #${c.base02} !important;
	--button-color-text-default: #${c.base05} !important;
	--button-color-text-hover: #${c.base05} !important;

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

body,
shreddit-app,
main,
#shreddit-app {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

/* community-theme post credit bar */
#pdp-credit-bar {
	--color-neutral-background: #${c.base01} !important;
	--color-neutral-content: #${c.base05} !important;
	--color-neutral-content-weak: #${c.base04} !important;
}

/* header bar */
reddit-header-large,
shreddit-header,
header[role="banner"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

a {
	color: #${c.base0D} !important;
}

a:visited {
	color: #${c.base0E} !important;
}

h1, h2, h3, h4, h5, h6 {
	color: #${c.base05} !important;
}

/* feed + post cards */
shreddit-feed,
shreddit-post,
shreddit-xpost,
.thing,
[class*="post"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

shreddit-post [slot="title"],
a[id^="post-title"],
h1[id^="post-title"],
h2[id^="post-title"],
h3[id^="post-title"],
.thing .entry .title {
	color: #${c.base06} !important;
}

/* comments */
shreddit-comment-tree,
shreddit-comment,
.comment {
	color: #${c.base05} !important;
}

/* overlays, menus, modals, toasts, composer */
rpl-modal-card,
faceplate-modal,
faceplate-drawer,
faceplate-menu,
faceplate-dropdown-menu,
faceplate-tier-1-menu,
faceplate-banner,
faceplate-toast,
shreddit-post-modal,
shreddit-composer,
.dropdown,
[role="dialog"] {
	background-color: #${c.base02} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

/* sidebars */
#left-sidebar-container,
#right-sidebar-container,
#right-sidebar-contents aside,
#left-sidebar-container nav,
#right-sidebar-container nav,
reddit-sidebar-nav,
reddit-recent-pages,
[class*="sidebar"] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

hr {
	border-color: #${c.base03} !important;
}

/* search bar + inputs */
#search-container,
[class*="search"] input,
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

/* misc utility-fixed classes */
.text-primary-onBackground {
	color: #${c.base05} !important;
}

.text-coolgray-350 {
	color: #${c.base04} !important;
}

/* reddit logo */
#reddit-logo circle[fill="#FF4500"] {
	fill: #${c.base0D} !important;
}

#reddit-logo path[fill="#FFF"] {
	fill: #${c.base00} !important;
}
		'';
	};
}