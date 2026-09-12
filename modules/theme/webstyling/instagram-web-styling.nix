{ ... }:
{
	flake.modules.homeManager."instagram-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."instagram.com" = ''
:root {
	color-scheme: dark !important;
}

html,
body {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

h1, h2, h3, h4 {
	color: var(--stylix-text) !important;
}

a {
	color: var(--stylix-text) !important;
}

/* Instagram paints almost everything with inline styles, so catch the common
   near-white paint colours directly on the big containers. */
div[style*="rgb(245, 245, 245)"],
div[style*="rgb(250, 250, 250)"],
div[style*="rgb(255, 255, 255)"],
div[style*="rgb(250,250,250)"],
div[style*="rgb(255,255,255)"],
div[style*="#FAFAFA"],
div[style*="#fafafa"] {
	background-color: var(--stylix-bg) !important;
}

/* sidebar / rails / panels */
div[role="presentation"],
aside,
[role="navigation"],
[role="main"] {
	background-color: var(--stylix-bg) !important;
	color: var(--stylix-text) !important;
}

/* inputs (login/search/direct message) */
input,
textarea,
[class*="x2lah0s"],
[role="textbox"] {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

input::placeholder,
textarea::placeholder {
	color: var(--stylix-text-dim) !important;
}

/* black icons/text get restyled */
svg[stroke="#000"] {
	stroke: var(--stylix-text) !important;
}

svg[fill="#000"] {
	fill: var(--stylix-text) !important;
}

div[style*="color: rgb(0, 0, 0)"],
div[style*="color: rgb(38, 38, 38)"],
div[style*="color: #000"],
div[style*="color: #262626"] {
	color: var(--stylix-text) !important;
}
		'';
	};
}