{ ... }:
{
	flake.modules.homeManager."youtube-web-styling" = { config, ... }:
	{
		zenWebStyling.siteStyles."youtube.com" = let
			c = config.lib.stylix.colors;
			# base04 equals base02 (~2:1 on base00), too dim to read: blend base05 toward base00
			muted = "color-mix(in srgb, #${c.base05} 70%, #${c.base00})";
			# translucent tints of the selection grey for hover / tonal fills
			tint = pct: "color-mix(in srgb, #${c.base02} ${pct}%, transparent)";
			# quiet 1px rule colour
			rule = "#${c.base03}";
			# Stylix fonts, as the Vesktop theme uses them
			sans = config.stylix.fonts.sansSerif.name;
			mono = config.stylix.fonts.monospace.name;
		in ''
/* YouTube re-declares its colour tokens on every [dark] element (masthead,
   guide, popups, the app shell), so a :root override is shadowed by the nearest
   ancestor: declare the palette on all of those scopes. */
:root,
html[dark],
[dark],
[darker-dark-theme],
ytd-app,
ytd-masthead,
ytd-popup-container,
tp-yt-iron-dropdown {
	color-scheme: dark !important;
	scrollbar-color: #${c.base03} transparent !important;

	/* current design tokens: --yt-sys-color-baseline--* */
	--yt-sys-color-baseline--base-background: #${c.base00} !important;
	--yt-sys-color-baseline--raised-background: #${c.base01} !important;
	--yt-sys-color-baseline--menu-background: #${c.base01} !important;
	--yt-sys-color-baseline--tonal-background: ${tint "45"} !important;
	--yt-sys-color-baseline--tonal-rim: ${rule} !important;
	--yt-sys-color-baseline--button-chip-background-hover: ${tint "55"} !important;
	--yt-sys-color-baseline--additive-background: ${tint "30"} !important;
	--yt-sys-color-baseline--mono-tonal-hover: ${tint "55"} !important;
	--yt-sys-color-baseline--suggested-action: color-mix(in srgb, #${c.base0D} 25%, #${c.base01}) !important;
	--yt-sys-color-baseline--inverted-background: #${c.base05} !important;

	--yt-sys-color-baseline--text-primary: #${c.base05} !important;
	--yt-sys-color-baseline--text-primary-inverse: #${c.base00} !important;
	--yt-sys-color-baseline--text-secondary: ${muted} !important;
	--yt-sys-color-baseline--text-secondary-inverse: ${muted} !important;
	--yt-sys-color-baseline--text-disabled: #${c.base04} !important;
	--yt-sys-color-baseline--text-error: #${c.base08} !important;

	--yt-sys-color-baseline--call-to-action: #${c.base0D} !important;
	--yt-sys-color-baseline--call-to-action-hover: #${c.base0D} !important;
	--yt-sys-color-baseline--call-to-action-inverse: #${c.base0D} !important;
	--yt-sys-color-baseline--overlay-call-to-action: #${c.base0D} !important;
	--yt-sys-color-baseline--themed-blue: #${c.base0D} !important;
	--yt-sys-color-baseline--light-blue: #${c.base0D} !important;
	--yt-sys-color-baseline--dark-blue: #${c.base0D} !important;
	--yt-sys-color-baseline--themed-green: #${c.base0B} !important;
	--yt-sys-color-baseline--light-green: #${c.base0B} !important;
	--yt-sys-color-baseline--wordmark-text: #${c.base05} !important;
	--yt-sys-color-baseline--red-indicator: #${c.base08} !important;
	--yt-sys-color-baseline--error-indicator: #${c.base08} !important;
	--yt-sys-color-baseline--error-text: #${c.base08} !important;

	--yt-sys-color-baseline--outline: ${rule} !important;
	--yt-sys-color-baseline--outline-opaque: #${c.base03} !important;
	--yt-sys-color-baseline--outline-inverse: ${rule} !important;

	--yt-sys-color-baseline--overlay-background-solid: #${c.base00} !important;
	--yt-sys-color-baseline--overlay-background-light: color-mix(in srgb, #${c.base01} 60%, transparent) !important;
	--yt-sys-color-baseline--overlay-background-heavy: #${c.base00} !important;
	--yt-sys-color-baseline--overlay-text-primary: #${c.base05} !important;
	--yt-sys-color-baseline--overlay-text-secondary: ${muted} !important;
	--yt-sys-color-baseline--overlay-button-primary: #${c.base05} !important;

	/* --yt-spec-* tokens most surfaces still consume */
	--yt-spec-base-background: #${c.base00} !important;
	--yt-spec-raised-background: #${c.base01} !important;
	--yt-spec-menu-background: #${c.base01} !important;
	--yt-spec-inverted-background: #${c.base05} !important;
	--yt-spec-general-background-a: #${c.base00} !important;
	--yt-spec-general-background-b: #${c.base01} !important;
	--yt-spec-general-background-c: #${c.base01} !important;
	--yt-spec-text-primary: #${c.base05} !important;
	--yt-spec-text-primary-inverse: #${c.base00} !important;
	--yt-spec-text-secondary: ${muted} !important;
	--yt-spec-text-secondary-inverse: ${muted} !important;
	--yt-spec-text-disabled: #${c.base04} !important;
	--yt-spec-text-invert: #${c.base00} !important;
	--yt-spec-wordmark-text: #${c.base05} !important;
	--yt-spec-call-to-action: #${c.base0D} !important;
	--yt-spec-call-to-action-inverse: #${c.base0D} !important;
	--yt-spec-brand-link-solid: #${c.base0D} !important;
	--yt-spec-brand-link-text: #${c.base0D} !important;
	--yt-spec-themed-blue: #${c.base0D} !important;
	--yt-spec-light-blue: #${c.base0D} !important;
	--yt-spec-dark-blue: #${c.base0D} !important;
	--yt-spec-themed-green: #${c.base0B} !important;
	--yt-spec-light-green: #${c.base0B} !important;
	--yt-spec-error-indicator: #${c.base08} !important;
	--yt-spec-icon-active-other: #${c.base05} !important;
	--yt-spec-icon-inactive: ${muted} !important;
	--yt-spec-icon-disabled: #${c.base04} !important;
	--yt-spec-brand-icon-active: #${c.base0D} !important;
	--yt-spec-brand-icon-inactive: ${muted} !important;
	--yt-spec-brand-button-background: #${c.base0D} !important;
	--yt-spec-brand-subscribe-button-background: #${c.base0D} !important;
	--yt-spec-brand-subscribe-button-text: #${c.base07} !important;
	--yt-spec-filled-button-text: #${c.base07} !important;
	--yt-spec-mono-filled-hover: #${c.base05} !important;
	--yt-spec-mono-tonal-hover: ${tint "55"} !important;
	--yt-spec-button-chip-background-hover: ${tint "55"} !important;
	--yt-spec-badge-chip-background: ${tint "45"} !important;
	--yt-spec-additive-background: ${tint "30"} !important;
	--yt-spec-touch-response: ${tint "30"} !important;
	--yt-spec-suggested-action: color-mix(in srgb, #${c.base0D} 25%, #${c.base01}) !important;
	--yt-spec-outline: ${rule} !important;
	--yt-spec-10-percent-layer: ${rule} !important;
	--yt-spec-15-percent-layer: ${rule} !important;
	--yt-spec-20-percent-layer: ${tint "45"} !important;
	--yt-spec-30-percent-layer: ${tint "50"} !important;
	--yt-spec-60-percent-layer: color-mix(in srgb, #${c.base03} 60%, transparent) !important;
	--yt-spec-tooltip-background: #${c.base01} !important;
	--yt-spec-tooltip-text: #${c.base05} !important;
	--yt-spec-snackbar-background: #${c.base01} !important;

	/* legacy greyscales: light end is text, dark end is the surface ladder */
	--yt-spec-white-1: #${c.base05} !important;
	--yt-spec-white-2: ${muted} !important;
	--yt-spec-white-3: ${muted} !important;
	--yt-spec-grey-1: #${c.base05} !important;
	--yt-spec-grey-2: ${muted} !important;
	--yt-spec-grey-3: ${muted} !important;
	--yt-spec-grey-4: #${c.base04} !important;
	--yt-spec-grey-5: #${c.base03} !important;
	--yt-spec-black-1: #${c.base00} !important;
	--yt-spec-black-2: #${c.base01} !important;
	--yt-spec-black-3: #${c.base03} !important;
	--yt-spec-black-4: #${c.base03} !important;

	/* brand red paints the player progress bar, live badges and watched bars */
	--yt-spec-static-brand-red: #${c.base0D} !important;
}

/* ---- page-wide base (zero specificity via :where, so every rule below wins) ----
   Most YouTube text takes its colour from hashed per-build variables the tokens
   above cannot reach, so set primary text, quiet borders and the Stylix font on
   text elements directly. The player (#movie_player) keeps its own chrome; icons
   are SVG (no icon fonts), so the font list stays on text elements only. */
:where(ytd-app, ytd-popup-container, tp-yt-iron-dropdown) :where(h1, h2, h3, h4, h5, h6, p, span, a, div, label, yt-formatted-string, yt-attributed-string, yt-icon, tp-yt-paper-item, tp-yt-paper-button, button):where(:not(#movie_player, #movie_player *, .yt-core-attributed-string__link, .yt-core-attributed-string__link *)) {
	color: #${c.base05} !important;
}

:where(ytd-app, ytd-popup-container, tp-yt-iron-dropdown) :where(h1, h2, h3, h4, h5, h6, p, span, a, div, label, yt-formatted-string, yt-attributed-string, tp-yt-paper-item, tp-yt-paper-button, button, input, textarea):where(:not(#movie_player, #movie_player *)) {
	font-family: "${sans}", sans-serif !important;
}

/* the monospace font is wider than YouTube's sans: tighten it a little so
   labels and titles truncate less */
:where(ytd-app, ytd-popup-container, tp-yt-iron-dropdown) :where(h1, h2, h3, h4, p, span, a, yt-formatted-string, yt-attributed-string):where(:not(#movie_player, #movie_player *)) {
	letter-spacing: -0.02em !important;
}

ytd-guide-entry-renderer .title,
ytd-guide-entry-renderer yt-formatted-string {
	font-size: 13px !important;
}

:where(ytd-app) :where(code, pre, kbd, samp) {
	font-family: "${mono}", monospace !important;
}

:where(ytd-app, ytd-popup-container, tp-yt-iron-dropdown) :where(*):where(:not(#movie_player, #movie_player *)) {
	border-color: ${rule} !important;
	box-shadow: none !important;
}

/* page headings one step brighter */
ytd-app :is(h1, h2),
ytd-app :is(h1, h2) :is(span, a, yt-formatted-string) {
	color: #${c.base06} !important;
}

/* secondary text: views, dates, channel bylines, snippets, header metadata */
[class*="ContentMetadataViewModel" i] :is(span, a, div),
[class*="content-metadata-view-model" i] :is(span, a, div),
#metadata-line,
#metadata-line *,
ytd-video-meta-block :is(span, a, yt-formatted-string),
ytd-video-renderer #channel-info :is(a, yt-formatted-string, span),
ytd-channel-renderer #metadata :is(span, yt-formatted-string),
#description-text,
.metadata-snippet-text,
.metadata-snippet-text *,
#subscribers,
#video-count,
#owner-sub-count,
ytd-background-promo-renderer #body,
ytd-background-promo-renderer #body * {
	color: ${muted} !important;
}

/* links that are links (not titles/channel names): accent. YouTube marks them
   with ytAttributedStringLinkCallToActionColor (camelCase) or the older
   kebab classes */
a.ytAttributedStringLinkCallToActionColor,
a.ytAttributedStringLinkCallToActionColor *,
ytd-app a[href*="support.google.com"],
ytd-app a[href*="support.google.com"] *,
.yt-core-attributed-string__link--call-to-action-color,
.yt-core-attributed-string__link--call-to-action-color *,
a.yt-core-attributed-string__link:not(.yt-core-attributed-string--link-inherit-color),
a.yt-core-attributed-string__link:not(.yt-core-attributed-string--link-inherit-color) *,
ytd-background-promo-renderer a,
ytd-background-promo-renderer a *,
yt-description-preview-view-model a,
yt-description-preview-view-model a * {
	color: #${c.base0D} !important;
}

/* ads mark their whole title/description as call-to-action links: keep them
   on the body colour, not the accent */
:is(ytd-ad-slot-renderer, ytd-in-feed-ad-layout-renderer, ytd-search-pyv-renderer, ytd-promoted-sparkles-web-renderer) a[class],
:is(ytd-ad-slot-renderer, ytd-in-feed-ad-layout-renderer, ytd-search-pyv-renderer, ytd-promoted-sparkles-web-renderer) a[class] * {
	color: #${c.base05} !important;
}

/* keyboard focus */
ytd-app :is(a, button, input, [role="button"], [role="tab"]):not(#guide-button *):focus-visible {
	outline: 2px solid color-mix(in srgb, #${c.base0D} 70%, transparent) !important;
	outline-offset: 2px !important;
}

::selection {
	background-color: color-mix(in srgb, #${c.base0D} 35%, transparent) !important;
	color: #${c.base07} !important;
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
#container.ytd-masthead,
#background.ytd-masthead {
	background: #${c.base00} !important;
	border-bottom-color: ${rule} !important;
}

/* text colour no longer comes from the --yt-spec-* tokens on most components
   (hashed per-build vars): paint the text of each region directly, leaving
   links and buttons to the call-to-action token */
ytd-masthead yt-icon:not(#logo-icon):not([class*="ButtonShapeNextCallToAction"] *),
ytd-topbar-logo-renderer #logo-icon {
	color: #${c.base05} !important;
}

ytd-guide-renderer :is(yt-formatted-string, span, h3, yt-icon, .title):not([class*="ButtonShape"] *):not([class*="button-shape"] *),
ytd-mini-guide-renderer :is(span, yt-icon, .title) {
	color: #${c.base05} !important;
}

#footer.ytd-guide-renderer a,
#guide-links-primary a,
#guide-links-secondary a,
ytd-guide-renderer #copyright,
ytd-guide-renderer #footer :is(a, span, div) {
	color: ${muted} !important;
}

/* video lockups (home grid, watch sidebar): title primary, metadata muted */
yt-lockup-view-model h3,
yt-lockup-view-model h3 *,
[class*="ytLockupMetadataViewModelHeading"],
[class*="ytLockupMetadataViewModelHeading"] *,
ytd-compact-video-renderer #video-title,
ytd-rich-grid-media #video-title {
	color: #${c.base05} !important;
}

yt-lockup-view-model [class*="ytContentMetadataViewModel"],
yt-lockup-view-model [class*="ytContentMetadataViewModel"] span,
yt-lockup-view-model [class*="content-metadata-view-model"] span,
ytd-compact-video-renderer #metadata-line span,
ytd-compact-video-renderer ytd-channel-name #text {
	color: ${muted} !important;
}

/* search box, its button and the voice button */
#container.ytd-searchbox,
.ytSearchboxComponentInputBox,
.ytSearchboxComponentInputBoxDark,
.ytSearchboxComponentInputBoxLight,
.ytSearchboxComponentInputBoxDark[expanded],
.ytSearchboxComponentInputBoxLight[expanded] {
	background-color: #${c.base01} !important;
	border-color: ${rule} !important;
	box-shadow: none !important;
}

.ytSearchboxComponentSearchButton,
.ytSearchboxComponentSearchButtonDark,
#search-icon-legacy,
#voice-search-button button,
#voice-search-button .yt-spec-button-shape-next,
#voice-search-button [class*="ButtonShapeNext"]:is(a, button) {
	background-color: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	color: #${c.base05} !important;
	backdrop-filter: none !important;
}

.ytSearchboxComponentSearchButton *,
#voice-search-button yt-touch-feedback-shape * {
	background-color: transparent !important;
}

.ytSearchboxComponentInput,
#search-input,
#search-input input,
input#search {
	background: transparent !important;
	color: #${c.base05} !important;
}

.ytSearchboxComponentInput::placeholder,
#search-input input::placeholder,
input#search::placeholder {
	color: ${muted} !important;
}

/* search suggestions dropdown */
.ytSearchboxComponentSuggestionsContainer,
.ytSearchboxComponentSuggestionsContainerDark,
.sbdd_b,
.gstl_50.sbdd_a {
	background-color: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	color: #${c.base05} !important;
}

.ytSuggestionComponentHighlighted,
.ytSuggestionComponentSuggestion:hover,
.sbsb_d {
	background-color: ${tint "45"} !important;
}

.ytSuggestionComponentText,
.ytSuggestionComponentText b {
	color: #${c.base05} !important;
}

/* guide (left sidebar): page colour with a quiet right border, like the
   Vesktop channel column (a base01 fill was tried: the drawer is fixed, so a
   full-page capture shows it ending after one viewport) */
#guide-inner-content,
#guide-content,
tp-yt-app-drawer #contentContainer,
ytd-mini-guide-renderer,
ytd-guide-renderer {
	background-color: #${c.base00} !important;
}

tp-yt-app-drawer #contentContainer,
ytd-mini-guide-renderer {
	border-right: 1px solid ${rule} !important;
}

#chips,
#chips-wrapper,
.app-header,
.app-drawer {
	background-color: #${c.base00} !important;
	border-color: ${rule} !important;
}

ytd-guide-section-renderer,
ytd-guide-signin-promo-renderer {
	border-color: ${rule} !important;
}

tp-yt-paper-item.ytd-guide-entry-renderer,
#endpoint.ytd-guide-entry-renderer {
	background-color: transparent !important;
}

/* one tinted layer only: the link and its paper-item both paint by default */
ytd-guide-entry-renderer[active] tp-yt-paper-item,
ytd-mini-guide-entry-renderer[active] {
	background-color: ${tint "22"} !important;
	border-radius: 10px !important;
}

ytd-guide-entry-renderer #endpoint,
ytd-guide-entry-renderer #endpoint:hover {
	background-color: transparent !important;
}

ytd-guide-entry-renderer:not([active]):hover tp-yt-paper-item {
	background-color: ${tint "15"} !important;
	border-radius: 10px !important;
}

/* chip row (rotating hashed vars -- target the class shapes directly) */
.ytChipShapeChip,
.ytChipShapeInactive,
yt-chip-cloud-chip-renderer:not([selected]) #chip-container {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border: 1px solid ${rule} !important;
}

.ytChipShapeActive,
yt-chip-cloud-chip-renderer[selected] #chip-container {
	background-color: color-mix(in srgb, #${c.base0D} 20%, #${c.base01}) !important;
	color: #${c.base06} !important;
	border: 1px solid #${c.base0D} !important;
}

/* only the chip itself draws the outline; its inner label must not repeat it */
.ytChipShapeActive *,
yt-chip-cloud-chip-renderer[selected] #chip-container * {
	background-color: transparent !important;
	color: #${c.base06} !important;
	border: 0 !important;
	outline: 0 !important;
}

.ytChipShapeInactive:hover {
	background-color: ${tint "55"} !important;
}

/* buttons: YouTube ships both the kebab (yt-spec-button-shape-next--x) and
   the camelCase (ytSpecButtonShapeNextX) class sets, so match both */
/* outline buttons (sign in, view tickets ...) */
.yt-spec-button-shape-next--outline,
.ytSpecButtonShapeNextOutline {
	border-color: ${rule} !important;
}

.yt-spec-button-shape-next--call-to-action:is(.yt-spec-button-shape-next--outline, .yt-spec-button-shape-next--text),
.ytSpecButtonShapeNextCallToAction:is(.ytSpecButtonShapeNextOutline, .ytSpecButtonShapeNextText),
:is(.yt-spec-button-shape-next--call-to-action, .ytSpecButtonShapeNextCallToAction) :is(yt-icon, span, div) {
	color: #${c.base0D} !important;
}

:is(.yt-spec-button-shape-next--call-to-action, .ytSpecButtonShapeNextCallToAction):is(.yt-spec-button-shape-next--outline, .ytSpecButtonShapeNextOutline):hover {
	background-color: color-mix(in srgb, #${c.base0D} 15%, transparent) !important;
}

/* tonal action pills (like / share / save / more / voice) */
.yt-spec-button-shape-next--tonal,
.ytSpecButtonShapeNextTonal {
	background-color: ${tint "30"} !important;
	color: #${c.base05} !important;
	backdrop-filter: none !important;
}

:is(.yt-spec-button-shape-next--tonal, .ytSpecButtonShapeNextTonal):hover {
	background-color: ${tint "55"} !important;
}

/* the like | dislike divider */
:is(.yt-spec-button-shape-next--tonal, .ytSpecButtonShapeNextTonal)::after,
.ytSegmentedLikeDislikeButtonViewModelSegmentedButtonsWrapper ::after {
	background-color: ${rule} !important;
}

.ytSegmentedLikeDislikeButtonViewModelSegmentedButtonsWrapper,
ytd-segmented-like-dislike-button-renderer #segmented-buttons-wrapper {
	background: transparent !important;
}

.yt-spec-button-shape-next__icon,
.yt-spec-button-shape-next yt-icon,
yt-icon-button button {
	color: currentColor !important;
	fill: currentColor !important;
}

/* filled mono buttons (subscribe, join, check it out): the primary action, as an
   accent outline like Sign in (no solid fill) */
.yt-spec-button-shape-next--mono.yt-spec-button-shape-next--filled,
.ytSpecButtonShapeNextMono.ytSpecButtonShapeNextFilled,
ytd-subscribe-button-renderer :is(.yt-spec-button-shape-next--filled, .ytSpecButtonShapeNextFilled) {
	background-color: transparent !important;
	color: #${c.base0D} !important;
	border: 1px solid #${c.base0D} !important;
	backdrop-filter: none !important;
}

:is(.yt-spec-button-shape-next--mono.yt-spec-button-shape-next--filled, .ytSpecButtonShapeNextMono.ytSpecButtonShapeNextFilled):hover {
	background-color: color-mix(in srgb, #${c.base0D} 15%, transparent) !important;
}

:is(.yt-spec-button-shape-next--mono.yt-spec-button-shape-next--filled, .ytSpecButtonShapeNextMono.ytSpecButtonShapeNextFilled) :is(span, div, yt-icon, yt-formatted-string) {
	color: #${c.base0D} !important;
}

/* no gradient fills on any button shape */
.yt-spec-button-shape-next,
[class*="ytSpecButtonShapeNext"] {
	background-image: none !important;
}

/* "Did you know" meal-bar promo and the expandable summary / chapters bars:
   raised surface with a quiet border (they otherwise take a neutral or a
   thumbnail-derived tint) */
ytd-mealbar-promo-renderer,
ytd-mealbar-promo-renderer #dismissible,
ytd-popup-container tp-yt-paper-toast,
ytd-expandable-metadata-renderer,
ytd-expandable-metadata-renderer #header,
ytd-expandable-metadata-renderer #collapsed-title {
	background: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	border-radius: 12px !important;
}

ytd-expandable-metadata-renderer #header,
ytd-expandable-metadata-renderer #collapsed-title {
	border: 0 !important;
}

ytd-mealbar-promo-renderer *:not(button, a, [class*="ButtonShape"], [class*="ButtonShape"] *, #dismissible) {
	background-color: transparent !important;
}

ytd-mealbar-promo-renderer :is(#message-title, h2, h3),
ytd-mealbar-promo-renderer :is(#message-title, h2, h3) * {
	color: #${c.base06} !important;
}

/* empty-state / promo headings (history, signed-out pages) */
ytd-background-promo-renderer #title,
ytd-background-promo-renderer #title *,
ytd-background-promo-renderer [id*="title" i],
ytd-background-promo-renderer [class*="title" i],
ytd-browse[page-subtype="history"] #primary :is(h1, h2, h3, #title, [class*="title" i]),
ytd-browse[page-subtype="history"] #primary :is(h1, h2, h3, #title, [class*="title" i]) *,
[class*="EmptyStateViewModelTitle" i],
[class*="EmptyStateViewModelTitle" i] * {
	color: #${c.base06} !important;
}

/* call-to-action outline buttons in the masthead / guide promo (sign in) */
ytd-masthead #buttons ytd-button-renderer :is(a, button, span, div, yt-icon),
ytd-guide-signin-promo-renderer :is(a, button, span, div, yt-icon) {
	color: #${c.base0D} !important;
}

ytd-masthead #buttons ytd-button-renderer :is(a, button)[class*="utline" i],
ytd-guide-signin-promo-renderer :is(a, button)[class*="utline" i] {
	border-color: ${rule} !important;
}

ytd-guide-signin-promo-renderer > :is(div, yt-formatted-string):not(:has(a, button)),
ytd-guide-signin-promo-renderer #description {
	color: #${c.base05} !important;
}

/* brand red (logo, guide product icons) -> the palette red; the white
   wordmark and play glyph -> the text colour. The selectors match YouTube's
   own fill attributes by substring (its reds are ff0033 / ff0000 / ff0302) */
yt-icon :is([fill*="ff00" i], [fill*="ff03" i], [fill="red" i]) {
	fill: #${c.base08} !important;
}

/* guide product icons ("More from YouTube"): palette red (rule above) with the
   glyph in the bright text colour; gradient-filled ones (Labs) also get the red */
ytd-guide-entry-renderer yt-icon [fill^="url" i] {
	fill: #${c.base08} !important;
}

ytd-guide-entry-renderer yt-icon :is([fill="white" i], [fill*="fff" i]) {
	fill: #${c.base06} !important;
}

ytd-topbar-logo-renderer yt-icon :is([fill="white" i], [fill*="fff" i]),
ytd-topbar-logo-renderer yt-icon path:not([fill]) {
	fill: #${c.base05} !important;
}

/* thumbnail badges ("New", duration, "4K") */
:is(yt-thumbnail-view-model, ytd-thumbnail, yt-lockup-view-model) :is(.badge-shape, .yt-badge-shape, [class*="ytBadgeShape"], [class*="badge-shape-wiz"]) {
	background-color: color-mix(in srgb, #${c.base00} 82%, transparent) !important;
	color: #${c.base05} !important;
}

/* home "try searching" nudge: the bordered inner card is the only surface */
ytd-feed-nudge-renderer,
ytd-feed-nudge-renderer :not(#dismissible) {
	background: transparent !important;
}

ytd-feed-nudge-renderer #dismissible,
ytd-background-promo-renderer,
#dismissible.ytd-background-promo-renderer {
	background-color: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	color: #${c.base05} !important;
}

ytd-feed-nudge-renderer yt-formatted-string:not(#title, #subtitle) {
	color: #${c.base05} !important;
}

ytd-feed-nudge-renderer #subtitle,
ytd-feed-nudge-renderer #subtitle * {
	color: ${muted} !important;
}

/* video titles / lockups */
/* page headings one step brighter than body text for hierarchy */
ytd-video-primary-info-renderer h1.title,
ytd-watch-metadata h1,
ytd-watch-metadata #title h1 yt-formatted-string,
ytd-feed-nudge-renderer #title,
ytd-feed-nudge-renderer #title *,
ytd-comments-header-renderer #count,
ytd-comments-header-renderer #count * {
	color: #${c.base06} !important;
}

#video-title,
.yt-lockup-metadata-view-model__title,
.yt-lockup-metadata-view-model-wiz__title,
.ytLockupMetadataViewModelTitle {
	color: #${c.base05} !important;
}

.yt-content-metadata-view-model__metadata-text,
.yt-content-metadata-view-model-wiz__metadata-text,
.ytContentMetadataViewModelMetadataText,
#metadata-line span,
#owner-sub-count,
ytd-channel-name #text {
	color: ${muted} !important;
}

ytd-watch-metadata ytd-channel-name #text,
ytd-video-owner-renderer ytd-channel-name a {
	color: #${c.base05} !important;
}

/* watched-progress bars under thumbnails */
ytd-thumbnail-overlay-resume-playback-renderer #progress,
.ytThumbnailOverlayProgressBarHostWatchedProgressBarSegment,
.ytThumbnailOverlayProgressBarHostWatchedProgressBarSegmentModern {
	background: #${c.base0D} !important;
}

/* thumbnail duration / badge pills */
.yt-badge-shape--thumbnail-default,
.badge-shape-wiz--thumbnail-default,
ytd-thumbnail-overlay-time-status-renderer {
	background-color: color-mix(in srgb, #${c.base00} 80%, transparent) !important;
	color: #${c.base05} !important;
}

/* ambient "cinematics" reflection layer behind the player: element-scoped
   --yt-saturated-* tokens; remove it and flatten the watch surfaces */
#cinematics-container,
#cinematics,
ytd-watch-flexy #cinematics-container {
	display: none !important;
}

ytd-watch-flexy,
ytd-watch-flexy #player-container,
ytd-watch-flexy #player-container-inner {
	background-color: #${c.base00} !important;
	background-image: none !important;
}

ytd-watch-flexy[theater] #player-container,
ytd-watch-flexy[theater] #full-bleed-container {
	background: #${c.base00} !important;
}

#below.ytd-watch-flexy,
ytd-watch-metadata,
ytd-video-primary-info-renderer {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

/* description box: one raised surface, children transparent */
ytd-watch-metadata #description,
#description.ytd-watch-metadata,
#description-inner,
#description-inline-expander,
ytd-structured-description-content-renderer {
	background: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	border-radius: 12px !important;
}

ytd-watch-metadata #description *,
#description-inline-expander *,
ytd-structured-description-content-renderer * {
	background-color: transparent !important;
	background-image: none !important;
	border-color: ${rule} !important;
}

#description-inner,
#description-inline-expander,
ytd-structured-description-content-renderer {
	border: 0 !important;
}

/* description text primary; links (hashtags, urls) keep the accent token */
ytd-watch-metadata #description,
ytd-watch-metadata #description :is(span, div, yt-formatted-string):not(a, a *) {
	color: #${c.base05} !important;
}

ytd-watch-metadata #description #expand,
ytd-watch-metadata #description #collapse,
ytd-watch-metadata #description a,
ytd-watch-metadata #description a * {
	color: #${c.base0D} !important;
}

/* merch / ticket shelves under the description */
ytd-merch-shelf-renderer,
ytd-ticket-shelf-renderer {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

ytd-ticket-shelf-renderer *,
ytd-merch-shelf-renderer * {
	border-color: ${rule} !important;
}

/* primary event (a link styled as text) and the event table's plain text */
ytd-ticket-shelf-renderer :is(#title, #primary-event) :is(span, div, yt-formatted-string, a),
ytd-ticket-shelf-renderer #rest-events :is(span, div, yt-formatted-string):not(a, a *, [class*="link" i], [class*="link" i] *) {
	color: #${c.base05} !important;
}

/* vendor links ("Bandsintown", "View tickets") and VIEW TICKETS keep the accent */
ytd-ticket-shelf-renderer #primary-event #view-tickets-link,
ytd-ticket-shelf-renderer #primary-event #view-tickets-link *,
ytd-ticket-shelf-renderer #rest-events :is(a, [class*="link" i]),
ytd-ticket-shelf-renderer #rest-events :is(a, [class*="link" i]) * {
	color: #${c.base0D} !important;
}

/* the calendar date block (white day cell by default) */
ytd-ticket-shelf-renderer :is([id*="calendar" i], [class*="calendar" i]) {
	background-color: #${c.base01} !important;
	border: 0 !important;
	border-radius: 4px !important;
	overflow: hidden !important;
}

ytd-ticket-shelf-renderer :is([id*="calendar" i], [class*="calendar" i]) * {
	background-color: transparent !important;
	color: #${c.base05} !important;
}

/* comments */
ytd-comments,
ytd-comments-header-renderer,
ytd-comment-thread-renderer,
ytd-comment-view-model {
	background-color: #${c.base00} !important;
	color: #${c.base05} !important;
}

ytd-comments-header-renderer :is(span, yt-formatted-string, yt-icon, #label):not(#count, #count *),
ytd-comments-header-renderer yt-sort-filter-sub-menu-renderer * {
	color: #${c.base05} !important;
}

#content-text.ytd-comment-renderer,
#content-text.ytd-comment-view-model,
ytd-comment-view-model #content-text,
#author-text.ytd-comment-renderer,
ytd-comment-view-model #author-text {
	color: #${c.base05} !important;
}

ytd-comment-simplebox-renderer #placeholder-area,
#contenteditable-root.yt-formatted-string {
	color: ${muted} !important;
	border-color: ${rule} !important;
}

/* menus, popups, dialogs */
ytd-multi-page-menu-renderer,
ytd-multi-page-menu-renderer > #menu,
ytd-account-settings-menu-renderer,
ytd-menu-popup-renderer,
tp-yt-paper-listbox,
yt-sheet-view-model,
yt-list-view-model,
tp-yt-paper-dialog,
ytd-unified-share-panel-renderer,
ytd-add-to-playlist-renderer,
yt-contextual-sheet-layout {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
	border: 1px solid ${rule} !important;
	box-shadow: none !important;
}

ytd-menu-service-item-renderer:hover,
tp-yt-paper-item:hover,
yt-list-item-view-model:hover {
	background-color: ${tint "45"} !important;
}

tp-yt-paper-tooltip #tooltip,
.ytp-tooltip-text {
	background-color: #${c.base01} !important;
	color: #${c.base05} !important;
}

/* channel pages */
ytd-browse[page-subtype="channels"],
#channel-header-container,
ytd-c4-tabbed-header-renderer,
ytd-channel-header-renderer,
ytd-tabbed-page-header,
#header.ytd-item-section-renderer {
	background-color: #${c.base00} !important;
	border-color: ${rule} !important;
	color: #${c.base05} !important;
}

#text-container.ytd-channel-name,
#title.ytd-channel-header-renderer,
#description.ytd-channel-header-renderer {
	color: #${c.base05} !important;
}

/* channel tabs: underline-style, accent on the active one */
#tabsContainer.ytd-c4-tabbed-header-renderer,
yt-tab-group-shape,
yt-tab-shape,
yt-tab-shape *,
.yt-tab-group-shape__tab,
tp-yt-paper-tab,
tp-yt-paper-tab * {
	background-color: transparent !important;
	color: ${muted} !important;
	border-color: ${rule} !important;
}

yt-tab-shape:is([aria-selected="true"], [class*="elected" i]),
yt-tab-shape:is([aria-selected="true"], [class*="elected" i]) *,
[class*="TabShapeTabSelected" i],
[class*="TabShapeTabSelected" i] *,
.yt-tab-group-shape__tab--active .yt-tab-group-shape__tab-label,
.yt-tab-shape-wiz__tab--tab-selected,
.yt-tab-shape-wiz__tab--tab-selected *,
tp-yt-paper-tab.iron-selected,
tp-yt-paper-tab.iron-selected * {
	color: #${c.base06} !important;
}

yt-tab-shape:hover,
yt-tab-shape:hover *,
tp-yt-paper-tab:hover * {
	color: #${c.base05} !important;
}

/* YouTube's underline is a separate element painted from a hashed variable
   (measured as YouTube's own near-white, f1f1f1): clear every non-tab element inside the tab and draw the
   underline as an inset accent line on the selected tab instead */
yt-tab-group-shape *:not(yt-tab-shape, [class*="ytTabShapeTab"]),
yt-tab-group-shape *::before,
yt-tab-group-shape *::after {
	background-color: transparent !important;
}

[class*="TabShapeTabSelected" i],
.yt-tab-shape-wiz__tab--tab-selected {
	box-shadow: inset 0 -3px 0 #${c.base0D} !important;
}

/* the active-tab underline (an element with a background, not a border) */
yt-tab-shape :is([class*="tab-bar--tab-bar-selected" i], [class*="TabBarSelected" i]),
.yt-tab-group-shape__tab-bar,
.yt-tab-shape-wiz__tab-bar--tab-bar-selected,
tp-yt-paper-tabs #selectionBar,
#tabsContainer tp-yt-paper-tabs #selectionBar {
	background-color: #${c.base0D} !important;
	border-color: #${c.base0D} !important;
}

/* community posts */
ytd-post-renderer,
ytd-backstage-post-renderer {
	background-color: #${c.base01} !important;
	border: 1px solid ${rule} !important;
	color: #${c.base05} !important;
}

#content-text.ytd-post-renderer,
#author-text.ytd-post-renderer,
#content-text.ytd-backstage-post-renderer,
#author-text.ytd-backstage-post-renderer {
	color: #${c.base05} !important;
}

/* player: letterbox, control pills, progress */
.html5-video-player {
	background-color: #${c.base00} !important;
}

.ytp-large-play-button-bg {
	fill: color-mix(in srgb, #${c.base00} 80%, transparent) !important;
}

.ytp-play-progress,
.ytp-swatch-background-color,
.ytp-scrubber-button,
.ytp-settings-button.ytp-hd-quality-badge::after {
	background-color: #${c.base0D} !important;
}

/* autoplay toggle in the control bar */
.ytp-autonav-toggle-button {
	background-color: color-mix(in srgb, #${c.base03} 85%, transparent) !important;
}

.ytp-autonav-toggle-button[aria-checked="true"] {
	background-color: color-mix(in srgb, #${c.base0D} 70%, transparent) !important;
}

.ytp-autonav-toggle-button::after {
	background-color: #${c.base05} !important;
}

.ytp-load-progress,
.ytp-hover-progress {
	background-color: color-mix(in srgb, #${c.base05} 35%, transparent) !important;
}

.ytp-popup,
.ytp-settings-menu,
.ytp-panel-menu {
	background-color: color-mix(in srgb, #${c.base01} 92%, transparent) !important;
	color: #${c.base05} !important;
}

.ytp-menuitem:hover,
.ytp-menuitem[aria-checked="true"] {
	background-color: ${tint "45"} !important;
}

.ytp-menuitem-toggle-checkbox::after,
.ytp-menuitem[aria-checked="true"] .ytp-menuitem-toggle-checkbox {
	background-color: #${c.base0D} !important;
}
		'';
	};
}
