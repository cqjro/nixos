{ ... }:
{
	flake.modules.homeManager."reddit-web-styling" = { config, ... }:
	{
		# Flat, Vesktop-like Reddit: base00 page, one base01 step for cards and
		# rails, base03 hairlines, base0D as the only accent. Shreddit draws most
		# of its UI inside shadow roots, so the work is done through its --color-*
		# design tokens (they inherit into shadow DOM); element rules only cover
		# light-DOM content (post bodies, comments, code, quotes).
		# Own rules; no community theme copied.
		zenWebStyling.siteStyles."reddit.com" = let
			c = config.lib.stylix.colors;
			# base04 equals base02 (~2:1 on base00), too dim to read: blend base05 toward base00
			muted = "color-mix(in srgb, #${c.base05} 78%, #${c.base00})";
			# no lavender slot: blue/magenta blend for visited links
			violet = "color-mix(in srgb, #${c.base0D} 50%, #${c.base0E})";
			# chip/pill surface: one notch above the card step so pills stay visible on cards
			chip = "#${c.base03}";
			# card/rail surface: base01 nudged toward base03 so the one step reads on base00
			card = "color-mix(in srgb, #${c.base01} 75%, #${c.base03})";
			chipHover = "color-mix(in srgb, #${c.base03} 60%, #${c.base02})";
			# selected/voted state: accent tint instead of a loud solid fill
			# (primary buttons such as Join / Log In are plain chips)
			tint = "color-mix(in srgb, #${c.base0D} 30%, #${c.base01})";
		in ''
:root,
html.theme-rpl,
html.theme-beta,
html.theme-dark,
html.theme-light,
/* Shreddit also applies theme classes to inner roots (shreddit-app, panels) */
.theme-rpl,
.theme-beta,
.theme-dark,
.theme-light,
shreddit-app {
	color-scheme: dark !important;

	--color-pizzaRed: #${c.base0D} !important;
	--color-global-brand-orangered: #${c.base0D} !important;
	--color-global-orangered: #${c.base0D} !important;
	--color-global-focus: #${c.base0D} !important;
	--color-global-white: #${c.base00} !important;

	/* surfaces */
	--color-neutral-background: #${c.base00} !important;
	--color-neutral-background-weak: #${c.base01} !important;
	--color-neutral-background-medium: #${c.base01} !important;
	--color-neutral-background-strong: #${c.base01} !important;
	--color-neutral-background-container: ${card} !important;
	--color-neutral-background-container-strong: ${card} !important;
	--color-neutral-background-container-hover: ${chip} !important;
	--color-neutral-background-hover: ${chip} !important;
	--color-neutral-background-selected: #${c.base03} !important;
	--color-neutral-background-pressed: #${c.base03} !important;
	--color-secondary-background: ${chip} !important;
	--color-secondary-background-hover: ${chipHover} !important;
	--color-secondary-background-selected: #${c.base03} !important;
	--color-secondary-background-pressed: #${c.base03} !important;
	--color-transparent-background-hover: color-mix(in srgb, #${c.base03} 60%, transparent) !important;
	--color-media-background: #${c.base01} !important;
	--color-ui-canvas: #${c.base00} !important;
	--color-ui-modalbackground: #${c.base01} !important;
	--color-scrim: color-mix(in srgb, #${c.base00} 70%, transparent) !important;
	--color-scrim-background: color-mix(in srgb, #${c.base00} 70%, transparent) !important;
	--color-opacity-50: color-mix(in srgb, #${c.base00} 50%, transparent) !important;
	--shreddit-content-background: transparent !important;

	/* interactive */
	--color-interactive-content-disabled: ${muted} !important;
	--color-interactive-background-disabled: #${c.base01} !important;
	--color-interactive-pressed: #${c.base03} !important;
	--color-interactive-hover: #${c.base03} !important;
	--color-interactive-focused: #${c.base0D} !important;

	/* borders: quiet 1px hairlines */
	--color-neutral-border: #${c.base03} !important;
	--color-neutral-border-weak: #${c.base03} !important;
	--color-neutral-border-medium: #${c.base03} !important;
	--color-neutral-border-strong: #${c.base03} !important;

	/* text */
	--color-neutral-content: #${c.base05} !important;
	--color-neutral-content-strong: #${c.base05} !important;
	--color-neutral-content-weak: ${muted} !important;
	--color-neutral-content-disabled: ${muted} !important;
	--color-secondary: #${c.base05} !important;
	--color-secondary-hover: #${c.base06} !important;
	--color-secondary-weak: ${muted} !important;
	--color-secondary-onBackground: #${c.base05} !important;
	--color-secondary-plain: #${c.base05} !important;
	--color-secondary-plain-hover: #${c.base06} !important;
	--color-secondary-plain-weak: ${muted} !important;
	--shreddit-color-wordmark: #${c.base06} !important;

	/* accent: links, focus, active state */
	--color-primary: #${c.base0D} !important;
	--color-primary-hover: #${c.base0D} !important;
	--color-primary-visited: ${violet} !important;
	--color-primary-plain: #${c.base0D} !important;
	--color-primary-plain-hover: #${c.base06} !important;
	--color-primary-plain-visited: ${violet} !important;
	--color-a-default: #${c.base0D} !important;
	--color-primary-background: ${chip} !important;
	--color-primary-background-hover: ${chipHover} !important;
	--color-primary-background-selected: ${tint} !important;
	--color-primary-onBackground: #${c.base06} !important;
	--color-primary-onBackground-selected: #${c.base06} !important;
	--color-brand-background: ${chip} !important;
	--color-brand-background-hover: ${chipHover} !important;
	--color-brand-onBackground: #${c.base06} !important;
	--color-avatar-gradient: #${c.base0D} !important;
	--color-online: #${c.base0B} !important;
	--color-favorite: #${c.base0A} !important;

	/* semantic */
	--color-danger-background: color-mix(in srgb, #${c.base08} 25%, #${c.base01}) !important;
	--color-danger-background-disabled: #${c.base01} !important;
	--color-danger-background-hover: color-mix(in srgb, #${c.base08} 40%, #${c.base01}) !important;
	--color-danger-content: #${c.base08} !important;
	--color-danger-content-default: #${c.base08} !important;
	--color-danger-content-hover: #${c.base08} !important;
	--color-danger-onBackground: #${c.base06} !important;
	--color-success-content: #${c.base0B} !important;
	--color-success-hover: #${c.base0C} !important;
	--color-success-onBackground: #${c.base06} !important;
	--color-success-background: color-mix(in srgb, #${c.base0B} 25%, #${c.base01}) !important;
	--color-success-background-hover: color-mix(in srgb, #${c.base0B} 40%, #${c.base01}) !important;
	--color-warning-content: #${c.base0A} !important;
	--color-warning-content-hover: #${c.base09} !important;
	--color-warning-onBackground: #${c.base06} !important;
	--color-warning-background: color-mix(in srgb, #${c.base0A} 25%, #${c.base01}) !important;
	--color-warning-background-hover: color-mix(in srgb, #${c.base0A} 40%, #${c.base01}) !important;

	/* voting: pill stays the chip surface; only the active arrow takes a colour */
	--color-action-upvote: #${c.base0D} !important;
	--color-action-downvote: #${c.base0E} !important;
	--color-upvote-content: #${c.base0D} !important;
	--color-upvote-onBackground: #${c.base06} !important;
	--color-upvote-background: ${tint} !important;
	--color-upvote-background-hover: #${c.base03} !important;
	--color-upvote-background-disabled: transparent !important;
	--color-upvote-disabled: #${c.base05} !important;
	--color-downvote-content: #${c.base0E} !important;
	--color-downvote-content-weak: #${c.base0E} !important;
	--color-downvote-onBackground: #${c.base06} !important;
	--color-downvote-background: color-mix(in srgb, #${c.base0E} 30%, #${c.base01}) !important;
	--color-downvote-background-hover: #${c.base03} !important;
	--color-downvote-background-disabled: transparent !important;
	--color-downvote-disabled: #${c.base05} !important;

	/* legacy tone ladder */
	--color-tone-1: #${c.base05} !important;
	--color-tone-2: #${c.base05} !important;
	--color-tone-3: ${muted} !important;
	--color-tone-4: #${c.base03} !important;
	--color-tone-5: ${chip} !important;
	--color-tone-6: #${c.base01} !important;
	--color-tone-7: #${c.base00} !important;

	/* legacy newCommunityTheme (old new-reddit) */
	--newCommunityTheme-body: #${c.base00} !important;
	--newCommunityTheme-bodyText: #${c.base05} !important;
	--newCommunityTheme-titleText: #${c.base06} !important;
	--newCommunityTheme-linkText: #${c.base0D} !important;
	--newCommunityTheme-post: #${c.base00} !important;
	--newCommunityTheme-postInside: #${c.base01} !important;
	--newCommunityTheme-button: #${c.base0D} !important;
	--newCommunityTheme-buttontext: #${c.base06} !important;
	--newCommunityTheme-line: #${c.base03} !important;
	--newCommunityTheme-header: #${c.base00} !important;
	--newCommunityTheme-canvas: #${c.base00} !important;
}

html {
	scrollbar-color: #${c.base03} #${c.base00} !important;
}

::selection {
	background-color: color-mix(in srgb, #${c.base0D} 40%, transparent) !important;
	color: #${c.base06} !important;
}

body,
shreddit-app,
#shreddit-app {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

/* header: flat page colour with one hairline */
reddit-header-large,
reddit-header-small,
shreddit-header {
	background-color: #${c.base00} !important;
	border-bottom-color: #${c.base03} !important;
}

/* feed and posts are flat on the page; hairlines separate them */
shreddit-feed,
shreddit-post,
shreddit-ad-post,
shreddit-xpost,
shreddit-comment-tree,
shreddit-comment {
	background-color: transparent !important;
	color: #${c.base05} !important;
}

hr {
	border-color: #${c.base03} !important;
	background-color: #${c.base03} !important;
}

shreddit-post [slot="title"],
a[id^="post-title"],
h1[id^="post-title"],
h2[id^="post-title"],
h3[id^="post-title"] {
	color: #${c.base06} !important;
}

/* links inside user-written text only (nav and titles keep the text colour) */
.md a,
[slot="text-body"] a,
[slot="comment"] a,
shreddit-comment [id$="-comment-rtjson-content"] a {
	color: #${c.base0D} !important;
}

.md a:visited,
[slot="text-body"] a:visited,
[slot="comment"] a:visited {
	color: ${violet} !important;
}

/* code and quotes in posts and comments */
.md pre,
[slot="text-body"] pre,
[slot="comment"] pre {
	background-color: #${c.base01} !important;
	border: 1px solid #${c.base03} !important;
	color: #${c.base05} !important;
}

.md code,
[slot="text-body"] code,
[slot="comment"] code {
	background-color: #${c.base03} !important;
	color: #${c.base06} !important;
}

.md pre code,
[slot="text-body"] pre code,
[slot="comment"] pre code {
	background-color: transparent !important;
}

.md blockquote,
[slot="text-body"] blockquote,
[slot="comment"] blockquote {
	border-left: 2px solid #${c.base03} !important;
	color: ${muted} !important;
}

.md table th,
.md table td {
	border-color: #${c.base03} !important;
}

.md table th {
	background-color: #${c.base01} !important;
}

mark {
	background-color: color-mix(in srgb, #${c.base0A} 30%, transparent) !important;
	color: #${c.base06} !important;
}

/* flair: one quiet chip instead of per-community fills */
.flair,
shreddit-post-flair .flair-content,
[class*="flair-content"] {
	background-color: ${chip} !important;
	color: #${c.base05} !important;
}

/* left rail (logged out: the sign-in panel) */
#left-sidebar-container,
flex-left-nav-container {
	background-color: #${c.base00} !important;
}

/* Google One Tap frame: keep its own (light) scheme so Zen does not paint an
	opaque dark backdrop behind the transparent iframe */
#credential_picker_container iframe,
iframe[src*="accounts.google.com"] {
	color-scheme: light !important;
}

/* utility classes that hard-code a colour */
.text-primary-onBackground {
	color: #${c.base05} !important;
}

.text-coolgray-350 {
	color: ${muted} !important;
}

#reddit-logo circle[fill="#FF4500"] {
	fill: #${c.base0D} !important;
}

#reddit-logo path[fill="#FFF"] {
	fill: #${c.base00} !important;
}
		'';
	};
}
