{ ... }:
{
	flake.modules.homeManager."youtube-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."youtube.com" = let
			c = config.lib.stylix.colors;
		in ''
:root,
html[dark] {
	color-scheme: dark !important;

	/* YouTube (current) design tokens: --yt-sys-color-baseline--* */
	--yt-sys-color-baseline--base-background: #${c.base00} !important;
	--yt-sys-color-baseline--raised-background: #${c.base01} !important;
	--yt-sys-color-baseline--menu-background: #${c.base01} !important;
	--yt-sys-color-baseline--tonal-background: color-mix(in srgb, #${c.base02} 45%, transparent) !important;
	--yt-sys-color-baseline--tonal-rim: color-mix(in srgb, #${c.base03} 55%, transparent) !important;
	--yt-sys-color-baseline--button-chip-background-hover: color-mix(in srgb, #${c.base02} 40%, transparent) !important;
	--yt-sys-color-baseline--additive-background: color-mix(in srgb, #${c.base02} 30%, transparent) !important;
	--yt-sys-color-baseline--mono-tonal-hover: color-mix(in srgb, #${c.base02} 40%, transparent) !important;
	--yt-sys-color-baseline--suggested-action: color-mix(in srgb, #${c.base0D} 30%, #${c.base01}) !important;

	--yt-sys-color-baseline--text-primary: #${c.base05} !important;
	--yt-sys-color-baseline--text-primary-inverse: #${c.base00} !important;
	--yt-sys-color-baseline--text-secondary: #${c.base04} !important;
	--yt-sys-color-baseline--text-secondary-inverse: #${c.base04} !important;
	--yt-sys-color-baseline--text-disabled: #${c.base03} !important;
	--yt-sys-color-baseline--text-error: #${c.base08} !important;

	--yt-sys-color-baseline--call-to-action: #${c.base0D} !important;
	--yt-sys-color-baseline--call-to-action-hover: #${c.base0E} !important;
	--yt-sys-color-baseline--call-to-action-inverse: #${c.base0D} !important;
	--yt-sys-color-baseline--overlay-call-to-action: #${c.base0D} !important;
	--yt-sys-color-baseline--wordmark-text: #${c.base05} !important;
	--yt-sys-color-baseline--red-indicator: #${c.base08} !important;
	--yt-sys-color-baseline--error-indicator: #${c.base08} !important;
	--yt-sys-color-baseline--error-text: #${c.base08} !important;

	--yt-sys-color-baseline--outline: color-mix(in srgb, #${c.base03} 55%, transparent) !important;
	--yt-sys-color-baseline--outline-opaque: #${c.base03} !important;
	--yt-sys-color-baseline--outline-inverse: color-mix(in srgb, #${c.base03} 55%, transparent) !important;

	--yt-sys-color-baseline--overlay-background-solid: #${c.base00} !important;
	--yt-sys-color-baseline--overlay-background-light: color-mix(in srgb, #${c.base01} 60%, transparent) !important;
	--yt-sys-color-baseline--overlay-background-heavy: #${c.base00} !important;
	--yt-sys-color-baseline--overlay-text-primary: #${c.base06} !important;
	--yt-sys-color-baseline--overlay-text-secondary: #${c.base04} !important;
	--yt-sys-color-baseline--overlay-button-primary: #${c.base05} !important;

	/* legacy --yt-spec-* aliases some surfaces still consume */
	--yt-spec-base-background: #${c.base00} !important;
	--yt-spec-raised-background: #${c.base01} !important;
	--yt-spec-menu-background: #${c.base01} !important;
	--yt-spec-general-background-a: #${c.base00} !important;
	--yt-spec-general-background-b: #${c.base01} !important;
	--yt-spec-general-background-c: #${c.base02} !important;
	--yt-spec-text-primary: #${c.base05} !important;
	--yt-spec-text-primary-inverse: #${c.base00} !important;
	--yt-spec-text-secondary: #${c.base04} !important;
	--yt-spec-text-secondary-inverse: #${c.base04} !important;
	--yt-spec-text-invert: #${c.base00} !important;
	--yt-spec-wordmark-text: #${c.base05} !important;
	--yt-spec-call-to-action: #${c.base0D} !important;
	--yt-spec-brand-link-solid: #${c.base0D} !important;
	--yt-spec-icon-inactive: #${c.base04} !important;
	--yt-spec-icon-disabled: #${c.base03} !important;
	--yt-spec-icon-active-other: #${c.base05} !important;
	--yt-spec-themed-blue: #${c.base0D} !important;
	--yt-spec-brand-subscribe-button-background: #${c.base0D} !important;
	--yt-spec-brand-subscribe-button-text: #${c.base00} !important;
	--yt-spec-brand-button-background: #${c.base0D} !important;
	--yt-spec-filled-button-text: #${c.base00} !important;
	--yt-spec-10-percent-layer: color-mix(in srgb, #${c.base02} 45%, transparent) !important;
	--yt-spec-15-percent-layer: color-mix(in srgb, #${c.base02} 45%, transparent) !important;
	--yt-spec-30-percent-layer: color-mix(in srgb, #${c.base02} 50%, transparent) !important;
	--yt-spec-60-percent-layer: color-mix(in srgb, #${c.base03} 50%, transparent) !important;
	--yt-spec-tooltip-background: #${c.base01} !important;
	--yt-spec-tooltip-text: #${c.base05} !important;
}

html,
body,
ytd-app,
ytd-page-manager,
ytd-browse,
ytd-watch-flexy,
#page-container {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

#masthead-container,
ytd-masthead,
#container.ytd-masthead {
	background-color: #${c.base00} !important;
	border-bottom-color: #${c.base03} !important;
}

/* search bar box (new searchbox component) */
#container.ytd-searchbox,
.ytSearchboxComponentInputBoxDark,
.ytSearchboxComponentInputBoxLight,
.ytSearchboxComponentInputBoxDark[expanded],
.ytSearchboxComponentInputBoxLight[expanded] {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

#search-input,
#search {
	color: #${c.base05} !important;
}

#search-input::placeholder {
	color: #${c.base04} !important;
}

#guide-inner-content,
#chips,
.app-header,
.app-drawer,
ytd-guide-renderer {
	background-color: #${c.base00} !important;
	border-color: #${c.base03} !important;
}

/* chip row (uses rotating hashed vars -- target the class shapes directly) */
.ytChipShapeInactive,
.ytChipBarViewModelChipWrapper {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

.ytChipShapeActive,
yt-chip-cloud-chip-renderer[selected] {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
	border-color: #${c.base0D} !important;
}

.ytChipShapeInactive:hover,
.ytChipShapeActive:hover {
	background-color: #${c.base02} !important;
}

/* playlist sort bar header (background comes from a rotating hashed var) */
ytd-item-section-renderer[use-chip-bar-view-model-header][page-subtype="playlist"] #header.ytd-item-section-renderer,
#header.ytd-item-section-renderer {
	background-color: #${c.base00} !important;
}

/* account / profile popup menu (background comes from a rotating hashed var) */
ytd-multi-page-menu-renderer,
ytd-multi-page-menu-renderer > #menu,
ytd-account-settings-menu-renderer {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
}

ytd-video-primary-info-renderer h1.title,
#video-title,
.yt-lockup-metadata-view-model__title {
	color: #${c.base05} !important;
}

#content-text.ytdcomment-renderer,
#author-text.ytd-comment-renderer {
	color: #${c.base05} !important;
}

/* ambient "cinematics" reflection layer behind the player uses element-scoped
   --yt-saturated-* tokens -- remove the layer entirely and flatten the watch
   page surfaces to the page colour */
#cinematics-container,
#cinematics,
ytd-watch-flexy #cinematics-container {
	display: none !important;
}

ytd-watch-flexy,
ytd-watch-flexy #player-container,
ytd-watch-flexy #player-container-inner,
#cinematics.ytd-watch-flexy,
#cinematics {
	background-color: #${c.base00} !important;
	background-image: none !important;
}

/* theater mode: solid themed background around the player */
ytd-watch-flexy[theater] #player-container,
ytd-watch-flexy[theater] #full-bleed-container {
	background: #${c.base00} !important;
}

/* the watch-page metadata / description section sits on that surface */
#below.ytd-watch-flexy,
ytd-watch-metadata,
ytd-video-primary-info-renderer,
ytd-text-inline-expander {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

/* description box -- one consistent surface, children stay transparent */
#description-inline-expander {
	background-color: #${c.base01} !important;
	border-radius: 12px !important;
}

#description-inline-expander,
#description-inline-expander * {
	color: #${c.base05} !important;
}

#description-inline-expander *,
ytd-structured-description-content-renderer,
ytd-structured-description-content-renderer * {
	background-color: transparent !important;
	background-image: none !important;
}

/* description box */
ytd-text-inline-expander #expand {
	color: #${c.base0D} !important;
}

/* action buttons (reply / join / like / share / save / menu -- style the inner
   pill shape, keep the square wrapper transparent) */
ytd-button-renderer yt-button-shape,
ytd-menu-renderer yt-button-shape,
ytd-segmented-like-dislike-button-renderer yt-button-shape {
	background-color: transparent !important;
}

ytd-button-renderer .yt-spec-button-shape-next,
ytd-menu-renderer .yt-spec-button-shape-next,
ytd-segmented-like-dislike-button-renderer .yt-spec-button-shape-next {
	background-color: #${c.base02} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
	border-radius: 18px !important;
}

/* subscribe button */
ytd-subscribe-button-renderer .yt-spec-button-shape-next--filled {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}

/* channel pages */
ytd-browse[page-subtype="channels"],
#channel-header-container,
ytd-c4-tabbed-header-renderer,
ytd-channel-header-renderer,
ytd-tabbed-page-header {
	background-color: #${c.base00} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

#text-container.ytd-channel-name,
#title.ytd-channel-header-renderer,
ytd-channel-name,
#description.ytd-channel-header-renderer {
	color: #${c.base05} !important;
}

/* channel tabs (home / videos / shows / ...) */
#tabsContainer.ytd-c4-tabbed-header-renderer,
yt-tab-shape,
.yt-tab-group-shape__tab {
	background-color: #${c.base02} !important;
	color: #${c.base05} !important;
	border-color: #${c.base03} !important;
}

yt-tab-shape[active],
yt-tab-shape[aria-selected="true"],
.yt-tab-group-shape__tab--active .yt-tab-group-shape__tab-label {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}

/* channel community posts (background/border come from rotating hashed vars) */
ytd-post-renderer[uses-compact-lockup],
ytd-post-renderer,
ytd-backstage-post-renderer {
	background-color: #${c.base02} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

#content-text.ytd-post-renderer,
#author-text.ytd-post-renderer,
#content-text.ytd-backstage-post-renderer,
#author-text.ytd-backstage-post-renderer {
	color: #${c.base05} !important;
}

/* player control bar background should stay dark */
.html5-video-player {
	background-color: #000 !important;
}
		'';
	};
}
