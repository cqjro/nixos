{ ... }:
{
	flake.modules.homeManager."youtube-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."youtube.com" = ''
:root,
html[dark] {
	color-scheme: dark !important;

	/* YouTube design tokens (--yt-spec-*) */
	--yt-spec-base-background: var(--stylix-surface) !important;
	--yt-spec-raised-background: var(--stylix-bg) !important;
	--yt-spec-menu-background: var(--stylix-surface) !important;
	--yt-spec-inverted-background: var(--stylix-bg) !important;
	--yt-spec-brand-background-primary: var(--stylix-bg) !important;
	--yt-spec-brand-background-secondary: var(--stylix-surface) !important;
	--yt-spec-brand-background-solid: var(--stylix-hover) !important;
	--yt-spec-brand-link-solid: var(--stylix-brand) !important;
	--yt-spec-text-primary: var(--stylix-text) !important;
	--yt-spec-text-primary-inverse: var(--stylix-text) !important;
	--yt-spec-text-secondary: var(--stylix-text-dim) !important;
	--yt-spec-text-secondary-inverse: var(--stylix-text-dim) !important;
	--yt-spec-text-invert: var(--stylix-bg) !important;
	--yt-spec-wordmark-text: var(--stylix-text) !important;
	--yt-spec-call-to-action: var(--stylix-brand) !important;
	--yt-spec-icon-active-other: var(--stylix-text) !important;
	--yt-spec-icon-inactive: var(--stylix-text-dim) !important;
	--yt-spec-icon-disabled: var(--stylix-border) !important;
	--yt-spec-icon-on-other: var(--stylix-text) !important;
	--yt-spec-general-background-a: var(--stylix-bg) !important;
	--yt-spec-general-background-b: var(--stylix-surface) !important;
	--yt-spec-general-background-c: var(--stylix-hover) !important;
	--yt-spec-10-percent-layer: var(--stylix-hover) !important;
	--yt-spec-15-percent-layer: var(--stylix-hover) !important;
	--yt-spec-30-percent-layer: var(--stylix-hover) !important;
	--yt-spec-40-percent-layer: var(--stylix-hover) !important;
	--yt-spec-60-percent-layer: var(--stylix-border) !important;
	--yt-spec-error-background: var(--stylix-danger) !important;
	--yt-spec-error-text: var(--stylix-text) !important;
	--yt-spec-filled-button-text: var(--stylix-bg) !important;
	--yt-spec-brand-button-text: var(--stylix-bg) !important;
	--yt-spec-badge-chip-background: var(--stylix-surface) !important;
	--yt-spec-badge-chip-text-primary: var(--stylix-text) !important;
	--yt-spec-adaptive-chip-background: var(--stylix-hover) !important;
	--yt-spec-adaptive-chip-text: var(--stylix-text) !important;
	--yt-spec-additive-chip-background: var(--stylix-brand) !important;
	--yt-spec-additive-chip-text: var(--stylix-bg) !important;
	--yt-spec-static-endpoint-background-hover: var(--stylix-hover) !important;
	--yt-spec-tooltip-background: var(--stylix-hover) !important;
	--yt-spec-tooltip-text: var(--stylix-text) !important;
	--yt-spec-era-control-slate-icon-color: var(--stylix-text) !important;

	/* deprecated tokens that some surfaces still use */
	--yt-spec-base-background-drop: var(--stylix-bg) !important;
	--yt-spec-themed-blue: var(--stylix-brand) !important;
	--yt-spec-brand-icon-active: var(--stylix-text) !important;
	--yt-spec-brand-icon-inactive: var(--stylix-text-dim) !important;
	--yt-spec-brand-subscribe-button-background: var(--stylix-brand) !important;
	--yt-spec-brand-subscribe-button-text: var(--stylix-bg) !important;
	--yt-spec-brand-subscribe-button-hover-background: var(--stylix-secondary) !important;
	--yt-spec-brand-button-background: var(--stylix-brand) !important;
}

body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

#masthead-container {
	background-color: var(--stylix-surface) !important;
	border-bottom-color: var(--stylix-border) !important;
}

#guide-inner-content,
#chips,
.app-header,
.app-drawer {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

ytd-video-primary-info-renderer h1.title {
	color: var(--stylix-text) !important;
}

ytd-comments #comments ytd-comment-thread-renderer,
ytd-comment-renderer #body {
	color: var(--stylix-text) !important;
}

/* player control bar background should stay dark */
.html5-video-player {
	background-color: #000 !important;
}
		'';
	};
}