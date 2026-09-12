{ ... }:
{
	flake.modules.homeManager."brave-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."search.brave.com" = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;

	/* Brave Search (SvelteKit) design tokens: --color-search-* / --color-serp-* */
	--color-search-background-page: #${c.base00} !important;
	--color-page-background: #${c.base00} !important;
	--color-search-background-container: #${c.base01} !important;
	--color-serp-snippet-background: #${c.base01} !important;
	--color-serp-header-background: #${c.base01} !important;
	--color-serp-bar-bg: #${c.base01} !important;
	--color-search-background-search-bar: #${c.base01} !important;
	--color-search-background-highlight: #${c.base02} !important;
	--color-search-background-interactive-normal: #${c.base02} !important;
	--color-search-background-interactive-pale: #${c.base01} !important;
	--color-search-background-enrichment-cards: #${c.base01} !important;
	--color-search-background-suggest-highlight: #${c.base02} !important;
	--color-container-background: #${c.base01} !important;
	--color-container-highlight: #${c.base02} !important;

	--color-text-primary: #${c.base05} !important;
	--color-text-secondary: #${c.base04} !important;
	--color-text-tertiary: #${c.base04} !important;
	--color-text-interactive: #${c.base0D} !important;
	--color-text-disabled: #${c.base03} !important;
	--color-search-links-link: #${c.base0D} !important;
	--color-link-default: #${c.base0D} !important;
	--color-link-visited: #${c.base0E} !important;
	--color-serp-breadcrumbs: #${c.base04} !important;

	--color-search-primary-40: #${c.base0D} !important;
	--color-search-primary-50: #${c.base0E} !important;
	--color-search-blue-40: #${c.base0D} !important;

	--color-divider-subtle: #${c.base03} !important;
	--color-divider-strong: #${c.base03} !important;
	--color-divider-faint: color-mix(in srgb, #${c.base03} 45%, transparent) !important;
	--color-divider-interactive: #${c.base0D} !important;
	--color-search-divider-subtle: #${c.base03} !important;
	--color-serp-divider-subtle-container: #${c.base03} !important;

	--color-icon-default: #${c.base05} !important;
	--color-icon-secondary: #${c.base04} !important;
	--color-icon-disabled: #${c.base03} !important;
	--color-icon-interactive: #${c.base0D} !important;
	--color-search-icon-interactive: #${c.base0D} !important;

	--color-button-background: #${c.base02} !important;
	--color-button-disabled: #${c.base03} !important;

	--color-systemfeedback-error-background: #${c.base02} !important;
	--color-systemfeedback-error-text: #${c.base08} !important;
	--color-systemfeedback-success-background: #${c.base02} !important;
	--color-systemfeedback-success-text: #${c.base0B} !important;
	--color-systemfeedback-warning-background: #${c.base02} !important;
	--color-systemfeedback-warning-text: #${c.base09} !important;
}

html,
body {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

h1, h2, h3, h4 {
	color: #${c.base05} !important;
}

a {
	color: #${c.base0D} !important;
}

/* search box */
#searchbox,
#searchform,
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

/* AI answer boxes */
#llm-snippet,
#chatllm-conversation,
#rh,
.inline-qa,
.inline-qa-card,
.ai-description-content {
	background-color: #${c.base02} !important;
	border-color: #${c.base03} !important;
	color: #${c.base05} !important;
}

mark,
::selection {
	background-color: #${c.base0D} !important;
	color: #${c.base00} !important;
}
		'';
	};
}