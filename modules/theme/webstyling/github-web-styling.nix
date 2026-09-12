{ ... }:
{
	flake.modules.homeManager."github-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."github.com" = let
			c = config.lib.stylix.colors;
		in ''
:root,
[data-color-mode],
[data-color-mode="light"],
[data-color-mode="dark"] {
	/* Primer design tokens (new) */
	--bgColor-default: #${c.base00} !important;
	--bgColor-muted: #${c.base01} !important;
	--bgColor-inset: #${c.base01} !important;
	--bgColor-neutral-muted: #${c.base02} !important;
	--bgColor-neutral-subtle: #${c.base01} !important;
	--bgColor-emphasis: #${c.base02} !important;
	--bgColor-success-emphasis: #${c.base0B} !important;
	--bgColor-danger-emphasis: #${c.base08} !important;
	--bgColor-accent-emphasis: #${c.base0D} !important;
	--fgColor-default: #${c.base05} !important;
	--fgColor-muted: #${c.base04} !important;
	--fgColor-subtle: #${c.base04} !important;
	--fgColor-onEmphasis: #${c.base00} !important;
	--fgColor-accent: #${c.base0D} !important;
	--fgColor-link: #${c.base0D} !important;
	--fgColor-success: #${c.base0B} !important;
	--fgColor-danger: #${c.base08} !important;
	--fgColor-completion-icon: #${c.base04} !important;
	--borderColor-default: #${c.base03} !important;
	--borderColor-muted: #${c.base03} !important;
	--borderColor-neutral-muted: #${c.base03} !important;
	--borderColor-success-emphasis: #${c.base0B} !important;
	--borderColor-danger-emphasis: #${c.base08} !important;

	/* Button component tokens (Primer react components) */
	--button-default-bgColor-rest: #${c.base01} !important;
	--button-default-bgColor-hover: #${c.base02} !important;
	--button-default-bgColor-active: #${c.base02} !important;
	--button-default-fgColor-rest: #${c.base05} !important;
	--button-default-fgColor-hover: #${c.base05} !important;
	--button-default-fgColor-active: #${c.base06} !important;
	--button-default-borderColor-rest: #${c.base03} !important;
	--button-default-borderColor-hover: #${c.base02} !important;
	--button-default-shadow-resting: 0 1px 0 0 #${c.base00} !important;
	--button-default-shadow-hover: 0 1px 0 0 #${c.base00} !important;
	--button-default-shadow-active: inset 0 0 0 1px #${c.base02} !important;

	--button-primary-bgColor-rest: #${c.base0D} !important;
	--button-primary-bgColor-hover: #${c.base0E} !important;
	--button-primary-bgColor-active: #${c.base0E} !important;
	--button-primary-fgColor-rest: #${c.base00} !important;
	--button-primary-shadow-resting: 0 1px 0 0 #${c.base08} !important;

	--button-danger-bgColor-rest: #${c.base01} !important;
	--button-danger-bgColor-hover: #${c.base08} !important;
	--button-danger-fgColor-rest: #${c.base08} !important;
	--button-danger-fgColor-hover: #${c.base00} !important;
	--button-danger-borderColor-rest: #${c.base03} !important;
	--button-danger-shadow-resting: 0 1px 0 0 #${c.base03} !important;

	--button-invisible-bgColor-rest: transparent !important;
	--button-invisible-bgColor-hover: #${c.base02} !important;
	--button-invisible-fgColor-rest: #${c.base0D} !important;
	--button-invisible-fgColor-hover: #${c.base05} !important;

	/* Primer legacy tokens */
	--color-canvas-default: #${c.base00} !important;
	--color-canvas-subtle: #${c.base01} !important;
	--color-canvas-inset: #${c.base01} !important;
	--color-canvas-overlay: #${c.base01} !important;
	--color-canvas-mobile: #${c.base00} !important;
	--color-fg-default: #${c.base05} !important;
	--color-fg-muted: #${c.base04} !important;
	--color-fg-subtle: #${c.base04} !important;
	--color-fg-on-emphasis: #${c.base00} !important;
	--color-accent-fg: #${c.base0D} !important;
	--color-link-fg: #${c.base0D} !important;
	--color-link-hover: #${c.base05} !important;
	--color-success-fg: #${c.base0B} !important;
	--color-danger-fg: #${c.base08} !important;
	--color-attention-fg: #${c.base09} !important;
	--color-border-default: #${c.base03} !important;
	--color-border-muted: #${c.base03} !important;
	--color-neutral-muted: #${c.base02} !important;
	--color-neutral-subtle: #${c.base01} !important;
	--color-header-bg: #${c.base00} !important;
	--color-header-fg: #${c.base05} !important;
	--color-header-border: #${c.base03} !important;
	--color-btn-bg: #${c.base01} !important;
	--color-btn-hover-bg: #${c.base02} !important;
	--color-btn-active-bg: #${c.base02} !important;
	--color-btn-fg: #${c.base05} !important;
	--color-btn-border: #${c.base03} !important;
	--color-btn-primary-bg: #${c.base0D} !important;
	--color-btn-primary-hover-bg: #${c.base0E} !important;
	--color-btn-primary-fg: #${c.base00} !important;
	--color-btn-danger-bg: #${c.base08} !important;
	--color-btn-danger-fg: #${c.base00} !important;
	--color-input-bg: #${c.base00} !important;
	--color-input-border: #${c.base03} !important;
	--color-input-fg: #${c.base05} !important;
	--color-diff-blob-addition-line-bg: #${c.base0B} !important;
	--color-diff-blob-addition-num-text: #${c.base0B} !important;
	--color-diff-blob-deletion-line-bg: #${c.base08} !important;
}

body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

.Header {
	background-color: #${c.base01} !important;
	border-bottom-color: #${c.base03} !important;
}

.UnderlineNav-item[aria-current="page"],
.UnderlineNav-item.selected {
	border-bottom-color: #${c.base0D} !important;
}

.Box {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}

.Box-row {
	border-color: #${c.base03} !important;
}

.avatar {
	border-color: #${c.base03} !important;
}

.markdown-body pre code,
.highlight pre {
	background-color: #${c.base01} !important;
}

.commit {
	background-color: #${c.base01} !important;
	border-color: #${c.base03} !important;
}
		'';
	};
}
