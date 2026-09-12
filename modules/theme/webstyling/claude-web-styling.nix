{ ... }:
{
	flake.modules.homeManager."claude-web-styling" = { config, ... }:
	let
		styling = let
			c = config.lib.stylix.colors;
		in ''
:root {
	color-scheme: dark !important;
	/* Claude (Claude.ai) dark design tokens */
	--dark-background: #${c.base00} !important;
	--dark-surface: #${c.base01} !important;
	--dark-panel-background: #${c.base01} !important;
	--dark-panel-background-secondary: #${c.base02} !important;
	--dark-input-background: #${c.base00} !important;
	--dark-secondary-button-background: #${c.base02} !important;
	--dark-primary-button-background: #${c.base0D} !important;
	--dark-text: #${c.base05} !important;
	--dark-text-secondary: #${c.base04} !important;
	--dark-text-tertiary: #${c.base04} !important;
	--dark-link: #${c.base0D} !important;
	--dark-accent: #${c.base0D} !important;
	--dark-border: #${c.base03} !important;
	--dark-header-background: #${c.base01} !important;
	--dark-conversation-branch-line: #${c.base03} !important;
	--dark-codeblock-background: #${c.base01} !important;
	--dark-codeblock-inline-background: #${c.base02} !important;
	--dark-composer-background: #${c.base01} !important;
	--dark-composer-border: #${c.base03} !important;
	--dark-error: #${c.base08} !important;
	--dark-warning: #${c.base09} !important;
	--dark-success: #${c.base0B} !important;
}

html,
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

input,
textarea,
select {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

code,
pre {
	background-color: #${c.base01} !important;
	color: #${c.base06} !important;
}

.scrollbar-dark {
	scrollbar-color: #${c.base03} #${c.base00} !important;
}
		'';
	in {
		zenWebStyling.siteStyles."claude.ai" = styling;
		zenWebStyling.siteStyles."claude.com" = styling;
	};
}