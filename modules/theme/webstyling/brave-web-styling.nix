{ ... }:
{
	flake.modules.homeManager."brave-web-styling" = { ... }:
	{
		zenWebStyling.siteStyles."search.brave.com" = ''
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
	color: var(--stylix-brand) !important;
}

/* header / top bar */
header,
.sidebar,
.nav,
[class*="header"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
}

/* search box */
input,
textarea,
select,
[class*="search-input"],
[class*="SearchBar"] {
	background-color: var(--stylix-surface) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

button,
[type="button"] {
	background-color: var(--stylix-hover) !important;
	color: var(--stylix-text) !important;
	border-color: var(--stylix-border) !important;
}

/* result cards */
.result,
.snippet,
.card,
[class*="result"] {
	background-color: var(--stylix-surface) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

.result-header .title,
[class*="result"] [class*="title"],
.snippet-title {
	color: var(--stylix-text) !important;
}

/* summary box on top */
[class*="summary"],
[class*="answer"] {
	background-color: var(--stylix-hover) !important;
	border-color: var(--stylix-border) !important;
	color: var(--stylix-text) !important;
}

/* footer */
footer {
	background-color: var(--stylix-surface) !important;
	border-top-color: var(--stylix-border) !important;
	color: var(--stylix-text-dim) !important;
}

mark,
::selection {
	background-color: var(--stylix-brand) !important;
	color: var(--stylix-bg) !important;
}
		'';
	};
}