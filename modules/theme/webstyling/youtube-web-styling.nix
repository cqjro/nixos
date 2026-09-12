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
	background-color: #${c.base01} !important;
	border-bottom-color: #${c.base03} !important;
}

#guide-inner-content,
#chips,
.app-header,
.app-drawer,
ytd-guide-renderer {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

ytd-video-primary-info-renderer h1.title,
#video-title,
.yt-lockup-metadata-view-model__title {
	color: #${c.base05} !important;
}

#content-text.ytd-comment-renderer,
#author-text.ytd-comment-renderer {
	color: #${c.base05} !important;
}

/* player control bar background should stay dark */
.html5-video-player {
	background-color: #000 !important;
}
		'';
	};
}