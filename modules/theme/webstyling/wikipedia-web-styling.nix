{ ... }:
{
	# Zen per-site theme for Wikipedia: every *.wikipedia.org page, including the
	# www portal and the en.m mobile skin. Flat and Vesktop-like: base00 everywhere,
	# base01 for raised surfaces, base03 for header cells, selected items and
	# dividers, and colour only on links and state.
	#
	# The Codex design tokens are overridden on :root with !important. A user-sheet
	# !important beats both of the site's token sets (day, and night via
	# html.skin-theme-clientpref-night / -os under prefers-color-scheme: dark), so
	# the theme is the same whichever theme Wikipedia serves.
	#
	# References (consulted, nothing copied):
	# - Codex token names from wikimedia/design-codex (GPL-2.0-or-later). The names
	#   are the site's interface; every value here is our palette.
	# - catppuccin/userstyles styles/wikipedia (MIT), used only as a checklist of
	#   the components to cover.
	flake.modules.homeManager."wikipedia-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."wikipedia.org" = let
			c = config.lib.stylix.colors;
			hex = slot: "#${c.${slot}}";
			mix = a: pct: b: "color-mix(in srgb, ${a} ${toString pct}%, ${b})";
			# translucent wash of a palette slot (message boxes, diffs, selection)
			tint = slot: pct: mix (hex slot) pct "transparent";
			# base04 equals base02 in this scheme (~2:1 on base00): too dim for text;
			# 80% base05 keeps ~4:1 even on base03 header cells
			muted = mix (hex "base05") 80 (hex "base00");
			# base0D alone is ~4.1:1 on base00; lifting it toward base06 gives ~5.4:1
			link = mix (hex "base0D") 80 (hex "base06");
			linkHover = mix (hex "base0D") 60 (hex "base06");
			# the scheme has no violet slot, so blend blue and magenta, then lift (~5.5:1)
			visited = mix (mix (hex "base0D") 50 (hex "base0E")) 70 (hex "base06");
			visitedHover = mix visited 70 (hex "base06");
			newVisited = mix (hex "base08") 60 (hex "base0E");
			# hover/active states lighten their own hue instead of switching hue
			redHover = mix (hex "base08") 75 (hex "base06");
			# links to missing pages: base08 alone is ~4.4:1, lifted to ~5:1
			newLink = mix (hex "base08") 85 (hex "base06");
			# filled accent (primary buttons): base0D darkened so base07 labels clear 4.5:1
			accentFill = mix (hex "base0D") 90 (hex "base00");
			accentFillHover = mix (hex "base0D") 75 (hex "base00");
			# disabled text must still differ from the disabled surface
			disabledText = mix (hex "base05") 45 (hex "base00");
			# Wikipedia inverts these images itself in night mode, so we invert only
			# when it serves the day theme; otherwise they would be inverted twice
			notNight = "html:not(.skin-theme-clientpref-night):not(.skin-theme-clientpref-os)";
			# table cells with a literal inline background (party colours, yes/no
			# cells, topic-coloured infobox headers). Their lightness cannot be read
			# from CSS, so every one gets a base00 veil: the hue survives, dimmed, and
			# base05 text is readable on it (a white cell becomes ~4.7:1)
			inlineCells = ":is(.wikitable, .infobox, .navbox, .sidebar, .toccolours) :is(tr, th, td):is([style*=\"background\"], [bgcolor]):not([style*=\"var(--\"]):not([style*=\"transparent\"]):not([style*=\"none\"]):not([style*=\"inherit\"])";
			veil = tint "base00" 80;
			# links on base03 header cells need the lighter blue (~4.9:1)
			headerCells = ":is(.wikitable th, .navbox-title, .navbox-group, .navbox-abovebelow, .infobox-above, .infobox-header, .sidebar-title, .sidebar-heading, .mp-h2)";
		in ''
:root {
	color-scheme: dark !important;

	/* text */
	--color-base: ${hex "base05"} !important;
	--color-base--hover: ${hex "base06"} !important;
	--color-emphasized: ${hex "base05"} !important;
	--color-neutral: ${muted} !important;
	--color-subtle: ${muted} !important;
	--color-base--subtle: ${muted} !important;
	--color-notice: ${hex "base05"} !important;
	--color-placeholder: ${muted} !important;
	--color-disabled: ${disabledText} !important;
	--color-disabled-emphasized: ${disabledText} !important;
	--color-inverted: ${hex "base00"} !important;
	--color-inverted-fixed: ${hex "base07"} !important;

	/* links and state */
	--color-progressive: ${link} !important;
	--color-progressive--hover: ${linkHover} !important;
	--color-progressive--active: ${linkHover} !important;
	--color-progressive--focus: ${link} !important;
	--color-link: ${link} !important;
	--color-link--visited: ${visited} !important;
	--color-visited: ${visited} !important;
	--color-visited--hover: ${visitedHover} !important;
	--color-visited--active: ${visitedHover} !important;
	--color-destructive: ${newLink} !important;
	--color-destructive--hover: ${redHover} !important;
	--color-destructive--active: ${redHover} !important;
	--color-destructive--visited: ${newVisited} !important;
	--color-destructive--visited--hover: ${redHover} !important;
	--color-destructive--visited--active: ${redHover} !important;
	--color-error: ${hex "base08"} !important;
	--color-error--hover: ${redHover} !important;
	--color-error--active: ${redHover} !important;
	--color-warning: ${hex "base0A"} !important;
	--color-success: ${hex "base0B"} !important;
	--color-content-added: ${hex "base0D"} !important;
	--color-content-removed: ${hex "base0A"} !important;

	--color-icon-progressive: ${hex "base0D"} !important;
	--color-icon-error: ${hex "base08"} !important;
	--color-icon-warning: ${hex "base0A"} !important;
	--color-icon-success: ${hex "base0B"} !important;

	/* surfaces: flat base00, base01 raised, base03 interactive */
	--background-color-base: ${hex "base00"} !important;
	--background-color-base-fixed: ${hex "base00"} !important;
	--background-color-neutral: ${hex "base03"} !important;
	--background-color-neutral-subtle: ${hex "base01"} !important;
	--background-color-interactive: ${hex "base03"} !important;
	--background-color-interactive--hover: ${hex "base02"} !important;
	--background-color-interactive--active: ${hex "base02"} !important;
	--background-color-interactive-subtle: ${hex "base01"} !important;
	--background-color-interactive-subtle--hover: ${hex "base03"} !important;
	--background-color-interactive-subtle--active: ${hex "base02"} !important;
	--background-color-disabled: ${hex "base01"} !important;
	--background-color-disabled-subtle: ${hex "base01"} !important;
	--background-color-inverted: ${hex "base05"} !important;
	--background-color-progressive: ${accentFill} !important;
	--background-color-progressive--hover: ${accentFillHover} !important;
	--background-color-progressive--active: ${accentFillHover} !important;
	--background-color-progressive--focus: ${hex "base0D"} !important;
	--background-color-destructive: ${hex "base08"} !important;
	--background-color-destructive--focus: ${hex "base0D"} !important;
	--background-color-error: ${hex "base08"} !important;
	--background-color-input-binary--checked: ${hex "base0D"} !important;
	--background-color-backdrop-light: ${tint "base00" 65} !important;
	--background-color-backdrop-dark: ${tint "base00" 65} !important;

	/* message boxes: a tint of their own colour rather than one shared grey */
	--background-color-notice-subtle: ${hex "base01"} !important;
	--background-color-progressive-subtle: ${tint "base0D" 15} !important;
	--background-color-progressive-subtle--hover: ${tint "base0D" 25} !important;
	--background-color-progressive-subtle--active: ${tint "base0D" 30} !important;
	--background-color-destructive-subtle: ${tint "base08" 15} !important;
	--background-color-destructive-subtle--hover: ${tint "base08" 25} !important;
	--background-color-destructive-subtle--active: ${tint "base08" 30} !important;
	--background-color-error-subtle: ${tint "base08" 15} !important;
	--background-color-error-subtle--hover: ${tint "base08" 25} !important;
	--background-color-error-subtle--active: ${tint "base08" 30} !important;
	--background-color-warning-subtle: ${tint "base0A" 15} !important;
	--background-color-success-subtle: ${tint "base0B" 15} !important;
	--background-color-content-added: ${tint "base0D" 30} !important;
	--background-color-content-removed: ${tint "base0A" 25} !important;
	--background-color-target-text: ${tint "base09" 30} !important;

	/* borders: thin base03 dividers, the accent on focus/hover only */
	--border-color-base: ${hex "base03"} !important;
	--border-color-emphasized: ${hex "base02"} !important;
	--border-color-subtle: ${hex "base03"} !important;
	--border-color-muted: ${tint "base03" 60} !important;
	--border-color-divider: ${hex "base03"} !important;
	--border-color-interactive: ${hex "base02"} !important;
	--border-color-interactive--hover: ${hex "base0D"} !important;
	--border-color-interactive--active: ${hex "base0D"} !important;
	--border-color-disabled: ${hex "base03"} !important;
	--border-color-notice: ${hex "base02"} !important;
	--border-color-progressive: ${hex "base0D"} !important;
	--border-color-progressive--hover: ${linkHover} !important;
	--border-color-progressive--active: ${linkHover} !important;
	--border-color-progressive--focus: ${hex "base0D"} !important;
	--border-color-destructive: ${hex "base08"} !important;
	--border-color-destructive--hover: ${redHover} !important;
	--border-color-destructive--active: ${redHover} !important;
	--border-color-destructive--focus: ${hex "base0D"} !important;
	--border-color-error: ${hex "base08"} !important;
	--border-color-warning: ${hex "base0A"} !important;
	--border-color-success: ${hex "base0B"} !important;
	--border-color-content-added: ${hex "base0D"} !important;
	--border-color-content-removed: ${hex "base0A"} !important;
	--border-color-inverted: ${hex "base00"} !important;

	--box-shadow-color-base: ${hex "base03"} !important;
	--box-shadow-color-inverted: ${hex "base00"} !important;
	--box-shadow-color-progressive--focus: ${hex "base0D"} !important;
	--box-shadow-color-progressive-selected: ${hex "base0D"} !important;
	--box-shadow-color-progressive-selected--hover: ${linkHover} !important;
	--box-shadow-color-progressive-selected--active: ${linkHover} !important;
	--box-shadow-color-destructive--focus: ${hex "base0D"} !important;

	/* icon inversion for the dark background */
	--filter-invert-icon: invert(1) !important;
}

html,
body {
	background-color: ${hex "base00"} !important;
	color: ${hex "base05"} !important;
}

::selection {
	background-color: ${tint "base0D" 35} !important;
	color: ${hex "base06"} !important;
}

mark {
	background-color: ${tint "base0A" 35} !important;
	color: ${hex "base06"} !important;
}

/* chrome: header, page, title bar, sticky header, footer, all flat base00 */
.vector-header-container,
.mw-header,
.mw-page-container,
.mw-body,
.mw-body-header,
.mw-page-container-inner,
.vector-page-titlebar,
.vector-sticky-header,
.vector-column-start,
.vector-column-end,
.mw-footer-container,
footer,
.mw-footer,
#mw-panel,
#mw-head,
#mw-head-base,
#mw-page-base,
#content,
#siteNotice,
.vector-sitenotice-container {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
}

h1, h2, h3, h4, h5, h6,
.mw-headline,
.mw-page-title-main {
	color: ${hex "base05"} !important;
	border-color: ${hex "base03"} !important;
}

/* dropdowns and menus (tools, appearance, languages, user links) */
.vector-dropdown-content,
.vector-menu-content,
.vector-pinnable-element {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
}

/* tabs: muted at rest, the selected one in base text over an accent underline */
.vector-menu-tabs .mw-list-item a,
.vector-menu-tabs .vector-tab-noicon a {
	color: ${muted} !important;
}

/* full shorthand: draws the underline even where Vector sets no border */
.vector-menu-tabs .mw-list-item.selected a {
	color: ${hex "base05"} !important;
	border-bottom: 2px solid ${hex "base0D"} !important;
}

/* one focus ring everywhere */
:focus-visible {
	outline-color: ${hex "base0D"} !important;
}

/* sidebar table of contents: the active section is a pill, as in Vesktop */
.vector-toc .vector-toc-list-item-active > .vector-toc-link,
.vector-toc .vector-toc-level-1-active:not(.vector-toc-list-item-expanded) > .vector-toc-link {
	background-color: ${hex "base03"} !important;
	border-radius: 4px !important;
	color: ${hex "base05"} !important;
}

/* article links; tokens cover the chrome, TemplateStyles can hardcode colours */
.mw-parser-output a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button) {
	color: ${link} !important;
}

.mw-parser-output a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button):visited {
	color: ${visited} !important;
}

.mw-parser-output a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button):hover {
	color: ${linkHover} !important;
}

.mw-parser-output a.new,
a.new {
	color: ${newLink} !important;
}

a.new:hover {
	color: ${redHover} !important;
}

.mw-parser-output a.new:visited,
a.new:visited {
	color: ${newVisited} !important;
}

/* infoboxes, wikitables, sidebars: base01 surface, base03 headers and grid */
.infobox,
.wikitable,
table.metadata,
.sidebar,
.vertical-navbox,
.toccolours,
#toc,
.toc {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

:is(.wikitable, .infobox, .sidebar, .vertical-navbox, .toccolours, table.metadata) :is(th, td) {
	border-color: ${hex "base03"} !important;
}

.wikitable > * > tr > th:not([style*="background"]),
.wikitable > tr > th:not([style*="background"]),
.infobox-above:not([style*="background"]),
.infobox-header:not([style*="background"]),
.infobox-subheader:not([style*="background"]),
.sidebar-title:not([style*="background"]),
.sidebar-heading:not([style*="background"]) {
	background-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

${inlineCells} {
	background-image: linear-gradient(${veil}, ${veil}) !important;
	color: ${hex "base05"} !important;
}

/* scoped and :not()-chained like the article link rule above so it outranks it,
   including :visited */
.mw-parser-output ${headerCells} a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button),
.mw-parser-output ${headerCells} a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button):visited,
.mw-parser-output ${inlineCells} a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button),
.mw-parser-output ${inlineCells} a:not(.new):not([class*="cdx-button"]):not(.mw-ui-button):visited {
	color: ${linkHover} !important;
}

/* navboxes: base00 frame, alternating base01 rows, base03 title */
.navbox,
.navbox-inner,
.navbox-subgroup,
.navbox-list,
.navbox-odd {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.navbox-even {
	background-color: ${hex "base01"} !important;
}

.navbox-title:not([style*="background"]),
.navbox th.navbox-title:not([style*="background"]) {
	background-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.navbox-abovebelow:not([style*="background"]),
.navbox-group:not([style*="background"]),
.navbox-subgroup .navbox-title:not([style*="background"]) {
	background-color: ${mix (hex "base03") 60 (hex "base00")} !important;
	color: ${hex "base05"} !important;
}

.navbox-list {
	border-color: ${hex "base00"} !important;
}

/* hatnotes ("Main article: ...", disambiguation): plain muted text, no box */
.hatnote,
.dablink,
.rellink {
	background-color: transparent !important;
	color: ${muted} !important;
}

/* message boxes (ambox and friends): flat base01, left bar keeps the meaning */
.ambox,
.tmbox,
.ombox,
.cmbox,
.fmbox,
.imbox,
.mbox-small,
.side-box {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

/* core message boxes (pre-Codex markup on special and edit pages), categories */
.mw-message-box,
.messagebox,
.warningbox,
.errorbox,
.successbox,
#catlinks,
.catlinks {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.mw-message-box-error,
.errorbox { background-color: ${tint "base08" 15} !important; border-color: ${hex "base08"} !important; }
.mw-message-box-warning,
.warningbox { background-color: ${tint "base0A" 15} !important; border-color: ${hex "base0A"} !important; }
.mw-message-box-success,
.successbox { background-color: ${tint "base0B" 15} !important; border-color: ${hex "base0B"} !important; }

.ambox { border-left-color: ${hex "base0D"} !important; }
.ambox-speedy,
.ambox-delete { border-left-color: ${hex "base08"} !important; }
.ambox-speedy { background-color: ${tint "base08" 15} !important; }
.ambox-content { border-left-color: ${hex "base09"} !important; }
.ambox-style { border-left-color: ${hex "base0A"} !important; }
.ambox-move { border-left-color: ${hex "base0E"} !important; }
.ambox-protection { border-left-color: ${hex "base02"} !important; }

/* quotes and pull-quote boxes */
blockquote,
.quotebox,
.templatequote {
	background-color: transparent !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

/* thumbnails: frame flat; transparent diagrams get a soft light backdrop so
   their black lines stay visible (not inverted ones, not maths) */
figure[typeof~="mw:File/Thumb"],
figure[typeof~="mw:File/Frame"],
.thumbinner,
.gallerybox .thumb,
figcaption,
.thumbcaption,
.gallerytext {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
	color: ${muted} !important;
}

/* content images only: navbox and ambox icons stay on the dark page */
:is(figure, .thumb, .gallerybox, .infobox) img.mw-file-element:not(.skin-invert):not(.skin-invert *) {
	background-color: ${hex "base05"} !important;
}

/* inverted images and maths: only when Wikipedia serves its day theme */
${notNight} :is(.skin-invert, .skin-invert-image img),
${notNight} img.mwe-math-fallback-image-inline,
${notNight} img.mwe-math-fallback-image-display,
${notNight} .mw-logo-wordmark,
${notNight} .mw-logo-tagline {
	filter: invert(1) hue-rotate(180deg) !important;
}

${notNight} .skin-invert-image img,
${notNight} img.skin-invert {
	background-color: transparent !important;
}

/* reference and citation targets (clicked footnote) */
ol.references li:target,
sup.reference:target,
cite:target,
span.citation:target,
.mw-cite-targeted-backlink {
	background-color: ${tint "base0D" 20} !important;
	color: ${hex "base05"} !important;
}

/* code: flat base01 block, thin base03 border */
pre,
code,
kbd,
samp,
tt,
.mw-code,
.mw-highlight,
.mw-highlight pre {
	background-color: ${hex "base01"} !important;
	color: ${hex "base05"} !important;
	border-color: ${hex "base03"} !important;
}

.mw-highlight :is(.c, .c1, .cm, .ch, .cp, .cpf, .cs, .sd) {
	color: ${muted} !important;
	font-style: italic;
}

.mw-highlight :is(.k, .kc, .kd, .kn, .kp, .kr, .kt, .ow) { color: ${hex "base0E"} !important; }
.mw-highlight :is(.s, .s1, .s2, .sa, .sb, .sc, .dl, .se, .sh, .si, .sr, .ss, .sx) { color: ${hex "base0B"} !important; }
.mw-highlight :is(.m, .mb, .mf, .mh, .mi, .mo, .il) { color: ${hex "base09"} !important; }
.mw-highlight :is(.nf, .fm, .nc, .nn, .nd) { color: ${link} !important; }
.mw-highlight :is(.nb, .bp, .o) { color: ${hex "base0C"} !important; }
.mw-highlight :is(.nt) { color: ${hex "base08"} !important; }
.mw-highlight :is(.na, .nv, .vc, .vg, .vi) { color: ${hex "base0A"} !important; }
.mw-highlight :is(.err) { color: ${hex "base08"} !important; border: none !important; }
.mw-highlight .hll { background-color: ${tint "base0A" 20} !important; }

/* form controls (search, edit summary, legacy forms); not checkboxes/radios */
input:not([type="checkbox"]):not([type="radio"]):not([type="image"]):not([type="submit"]):not([type="button"]):not([type="reset"]),
textarea,
select {
	background-color: ${hex "base01"} !important;
	color: ${hex "base05"} !important;
	border-color: ${hex "base03"} !important;
}

/* legacy submit buttons: flat base03, like a Vesktop secondary button */
input:is([type="submit"], [type="button"], [type="reset"]) {
	background-color: ${hex "base03"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

input:focus,
textarea:focus,
select:focus {
	border-color: ${hex "base0D"} !important;
}

input::placeholder,
textarea::placeholder {
	color: ${muted} !important;
}

/* search suggestions: Codex typeahead (tokens) plus the legacy jQuery box */
.cdx-menu,
.suggestions,
.suggestions-results,
.suggestions-special,
.mw-rcfilters-ui-filterWrapperWidget {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.suggestions-result-current,
.suggestions-special.suggestions-result-current,
.cdx-menu-item--highlighted {
	background-color: ${hex "base03"} !important;
}

/* Special:Search results */
.mw-search-profile-tabs,
.search-types {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
}

.mw-search-result-data,
.searchresult {
	color: ${muted} !important;
}

/* page previews and reference previews (hover cards) */
.mwe-popups,
.mwe-popups-container {
	background-color: ${hex "base01"} !important;
	color: ${hex "base05"} !important;
	border-color: ${hex "base03"} !important;
}

.mwe-popups .mwe-popups-extract::after {
	background-image: linear-gradient(to right, transparent, ${hex "base01"} 50%) !important;
}

/* language picker (ULS) */
.uls-menu,
.uls-search,
.uls-lcd,
.uls-filtersuggestion,
.uls-language-list {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

/* edit page: source editor, WikiEditor toolbar, CodeMirror, options */
#wpTextbox1,
.wikiEditor-ui,
.wikiEditor-ui-view,
.wikiEditor-ui-toolbar,
.wikiEditor-ui-toolbar .tabs,
.wikiEditor-ui-toolbar .sections,
.editOptions,
.mw-editTools,
#editpage-copywarn,
.cm-editor,
.cm-content {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.cm-gutters {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
	color: ${muted} !important;
}

.cm-cursor {
	border-left-color: ${hex "base05"} !important;
}

/* VisualEditor / OOUI widgets that predate the tokens */
.oo-ui-toolbar-bar,
.oo-ui-popupWidget-popup,
.oo-ui-menuSelectWidget,
.oo-ui-dialog-content > .oo-ui-window-body,
.oo-ui-textInputWidget .oo-ui-inputWidget-input {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.oo-ui-buttonElement-framed:not(.oo-ui-flaggedElement-primary) > .oo-ui-buttonElement-button {
	background-color: ${hex "base03"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

/* diffs: Codex semantics (added blue, removed yellow) */
td.diff-context {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

td.diff-addedline,
td.diff-deletedline {
	background-color: ${hex "base00"} !important;
	color: ${hex "base05"} !important;
}

td.diff-empty {
	background-color: ${hex "base00"} !important;
}

td.diff-marker {
	color: ${muted} !important;
}

td.diff-addedline { border-color: ${hex "base0D"} !important; }
td.diff-deletedline { border-color: ${hex "base0A"} !important; }

.diff-addedline .diffchange,
.mw-diff-inline-added ins,
.mw-diff-inline-changed ins,
ins.diffchange {
	background-color: ${tint "base0D" 30} !important;
	color: ${hex "base06"} !important;
}

.diff-deletedline .diffchange,
.mw-diff-inline-deleted del,
.mw-diff-inline-changed del,
del.diffchange {
	background-color: ${tint "base0A" 25} !important;
	color: ${hex "base06"} !important;
}

.diff-title,
.diff-otitle,
.diff-ntitle,
.diff-lineno {
	background-color: transparent !important;
	color: ${hex "base05"} !important;
}

/* history / recent changes: byte deltas are dark green/red upstream */
.mw-plusminus-pos { color: ${hex "base0B"} !important; }
.mw-plusminus-neg { color: ${redHover} !important; }
.mw-plusminus-null { color: ${muted} !important; }

#pagehistory li.selected,
.mw-changeslist-line.mw-changeslist-line-watched {
	background-color: ${tint "base0D" 15} !important;
	outline-color: ${hex "base03"} !important;
}

.mw-changeslist-legend,
.mw-tag-marker {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
}

/* main page section headings */
.mp-h2,
#mp-upper h2,
#mp-lower h2 {
	background-color: ${hex "base03"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

/* mobile skin (en.m.wikipedia.org, Minerva): the same flat surfaces */
.minerva-header,
.header-container,
#mw-mf-page-center,
.pre-content,
.minerva-footer,
.page-actions-menu,
.minerva-search-form,
#mw-mf-page-left,
.navigation-drawer {
	background-color: ${hex "base00"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.minerva-section-collapsible-toggle,
.section-heading {
	border-color: ${hex "base03"} !important;
}

/* www.wikipedia.org portal */
.search-container .search-input,
#searchInput,
.lang-list-button,
.suggestions-dropdown {
	background-color: ${hex "base01"} !important;
	border-color: ${hex "base03"} !important;
	color: ${hex "base05"} !important;
}

.suggestion-link.active {
	background-color: ${hex "base03"} !important;
}

.pure-button-primary-progressive {
	background-color: ${accentFill} !important;
	border-color: ${accentFill} !important;
	color: ${hex "base07"} !important;
}

.central-featured-lang a,
.lang-list-content a {
	color: ${link} !important;
}
		'';
	};
}
