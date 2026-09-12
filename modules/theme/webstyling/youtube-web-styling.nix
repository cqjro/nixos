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

	/* YouTube design tokens (--yt-spec-*) */
	--yt-spec-base-background: #${c.base01} !important;
	--yt-spec-raised-background: #${c.base00} !important;
	--yt-spec-menu-background: #${c.base01} !important;
	--yt-spec-inverted-background: #${c.base00} !important;
	--yt-spec-brand-background-primary: #${c.base00} !important;
	--yt-spec-brand-background-secondary: #${c.base01} !important;
	--yt-spec-brand-background-solid: #${c.base02} !important;
	--yt-spec-brand-link-solid: #${c.base0D} !important;
	--yt-spec-text-primary: #${c.base05} !important;
	--yt-spec-text-primary-inverse: #${c.base05} !important;
	--yt-spec-text-secondary: #${c.base04} !important;
	--yt-spec-text-secondary-inverse: #${c.base04} !important;
	--yt-spec-text-invert: #${c.base00} !important;
	--yt-spec-wordmark-text: #${c.base05} !important;
	--yt-spec-call-to-action: #${c.base0D} !important;
	--yt-spec-icon-active-other: #${c.base05} !important;
	--yt-spec-icon-inactive: #${c.base04} !important;
	--yt-spec-icon-disabled: #${c.base03} !important;
	--yt-spec-icon-on-other: #${c.base05} !important;
	--yt-spec-general-background-a: #${c.base00} !important;
	--yt-spec-general-background-b: #${c.base01} !important;
	--yt-spec-general-background-c: #${c.base02} !important;
	--yt-spec-10-percent-layer: #${c.base02} !important;
	--yt-spec-15-percent-layer: #${c.base02} !important;
	--yt-spec-30-percent-layer: #${c.base02} !important;
	--yt-spec-40-percent-layer: #${c.base02} !important;
	--yt-spec-60-percent-layer: #${c.base03} !important;
	--yt-spec-error-background: #${c.base08} !important;
	--yt-spec-error-text: #${c.base05} !important;
	--yt-spec-filled-button-text: #${c.base00} !important;
	--yt-spec-brand-button-text: #${c.base00} !important;
	--yt-spec-badge-chip-background: #${c.base01} !important;
	--yt-spec-badge-chip-text-primary: #${c.base05} !important;
	--yt-spec-adaptive-chip-background: #${c.base02} !important;
	--yt-spec-adaptive-chip-text: #${c.base05} !important;
	--yt-spec-additive-chip-background: #${c.base0D} !important;
	--yt-spec-additive-chip-text: #${c.base00} !important;
	--yt-spec-static-endpoint-background-hover: #${c.base02} !important;
	--yt-spec-tooltip-background: #${c.base02} !important;
	--yt-spec-tooltip-text: #${c.base05} !important;
	--yt-spec-era-control-slate-icon-color: #${c.base05} !important;

	/* deprecated tokens that some surfaces still use */
	--yt-spec-base-background-drop: #${c.base00} !important;
	--yt-spec-themed-blue: #${c.base0D} !important;
	--yt-spec-brand-icon-active: #${c.base05} !important;
	--yt-spec-brand-icon-inactive: #${c.base04} !important;
	--yt-spec-brand-subscribe-button-background: #${c.base0D} !important;
	--yt-spec-brand-subscribe-button-text: #${c.base00} !important;
	--yt-spec-brand-subscribe-button-hover-background: #${c.base0E} !important;
	--yt-spec-brand-button-background: #${c.base0D} !important;
}

body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

#masthead-container {
	background-color: #${c.base01} !important;
	border-bottom-color: #${c.base03} !important;
}

#guide-inner-content,
#chips,
.app-header,
.app-drawer {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

ytd-video-primary-info-renderer h1.title {
	color: #${c.base05} !important;
}

ytd-comments #comments ytd-comment-thread-renderer,
ytd-comment-renderer #body {
	color: #${c.base05} !important;
}

/* player control bar background should stay dark */
.html5-video-player {
	background-color: #000 !important;
}
		'';
	};
}