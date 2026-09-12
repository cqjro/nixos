{ ... }:
{
	flake.modules.homeManager."github-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."github.com" = ''
:root,
[data-color-mode],
[data-color-mode="light"],
[data-color-mode="dark"] {
	/* Primer design tokens (new) */
	--bgColor-default: var(--stylix-bg) !important;
	--bgColor-muted: var(--stylix-surface) !important;
	--bgColor-inset: var(--stylix-surface) !important;
	--bgColor-neutral-muted: var(--stylix-hover) !important;
	--bgColor-neutral-subtle: var(--stylix-surface) !important;
	--bgColor-emphasis: var(--stylix-hover) !important;
	--bgColor-success-emphasis: var(--stylix-success) !important;
	--bgColor-danger-emphasis: var(--stylix-danger) !important;
	--bgColor-accent-emphasis: var(--stylix-brand) !important;
	--fgColor-default: var(--stylix-text) !important;
	--fgColor-muted: var(--stylix-text-dim) !important;
	--fgColor-subtle: var(--stylix-text-dim) !important;
	--fgColor-onEmphasis: var(--stylix-bg) !important;
	--fgColor-accent: var(--stylix-brand) !important;
	--fgColor-link: var(--stylix-brand) !important;
	--fgColor-success: var(--stylix-success) !important;
	--fgColor-danger: var(--stylix-danger) !important;
	--fgColor-completion-icon: var(--stylix-text-dim) !important;
	--borderColor-default: var(--stylix-border) !important;
	--borderColor-muted: var(--stylix-border) !important;
	--borderColor-neutral-muted: var(--stylix-border) !important;
	--borderColor-success-emphasis: var(--stylix-success) !important;
	--borderColor-danger-emphasis: var(--stylix-danger) !important;

	/* Primer legacy tokens */
	--color-canvas-default: var(--stylix-bg) !important;
	--color-canvas-subtle: var(--stylix-surface) !important;
	--color-canvas-inset: var(--stylix-surface) !important;
	--color-canvas-overlay: var(--stylix-surface) !important;
	--color-canvas-mobile: var(--stylix-bg) !important;
	--color-fg-default: var(--stylix-text) !important;
	--color-fg-muted: var(--stylix-text-dim) !important;
	--color-fg-subtle: var(--stylix-text-dim) !important;
	--color-fg-on-emphasis: var(--stylix-bg) !important;
	--color-accent-fg: var(--stylix-brand) !important;
	--color-link-fg: var(--stylix-brand) !important;
	--color-link-hover: var(--stylix-text) !important;
	--color-success-fg: var(--stylix-success) !important;
	--color-danger-fg: var(--stylix-danger) !important;
	--color-attention-fg: var(--stylix-warning) !important;
	--color-border-default: var(--stylix-border) !important;
	--color-border-muted: var(--stylix-border) !important;
	--color-neutral-muted: var(--stylix-hover) !important;
	--color-neutral-subtle: var(--stylix-surface) !important;
	--color-header-bg: var(--stylix-surface) !important;
	--color-header-fg: var(--stylix-text) !important;
	--color-header-border: var(--stylix-border) !important;
	--color-btn-bg: var(--stylix-surface) !important;
	--color-btn-hover-bg: var(--stylix-hover) !important;
	--color-btn-active-bg: var(--stylix-hover) !important;
	--color-btn-fg: var(--stylix-text) !important;
	--color-btn-border: var(--stylix-border) !important;
	--color-btn-primary-bg: var(--stylix-brand) !important;
	--color-btn-primary-hover-bg: var(--stylix-secondary) !important;
	--color-btn-primary-fg: var(--stylix-bg) !important;
	--color-btn-danger-bg: var(--stylix-danger) !important;
	--color-btn-danger-fg: var(--stylix-bg) !important;
	--color-input-bg: var(--stylix-bg) !important;
	--color-input-border: var(--stylix-border) !important;
	--color-input-fg: var(--stylix-text) !important;
	--color-diff-blob-addition-line-bg: var(--stylix-success) !important;
	--color-diff-blob-addition-num-text: var(--stylix-success) !important;
	--color-diff-blob-deletion-line-bg: var(--stylix-danger) !important;
}

body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

.Header {
	background-color: var(--stylix-surface) !important;
	border-bottom-color: var(--stylix-border) !important;
}

.UnderlineNav-item[aria-current="page"],
.UnderlineNav-item.selected {
	border-bottom-color: var(--stylix-brand) !important;
}

.Box {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

.Box-row {
	border-color: var(--stylix-border) !important;
}

.avatar {
	border-color: var(--stylix-border) !important;
}

.markdown-body pre code,
.highlight pre {
	background-color: var(--stylix-surface) !important;
}

.commit {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}
		'';
	};
}