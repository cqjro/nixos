// Sidecar-only browser shim for Actual Budget Tweaks (ABT).
//
// ABT is injected by the sidecar (docker/server.js) as:
//   <script src="/abt/browser-shim.js"></script>   <- this file, runs first
//   ... ABT bundle ...
// This file is served by the sidecar as /abt/browser-shim.js instead of the
// upstream one (see modules/server/actual-budget-tweaks.nix). It is the upstream
// shim (docker/browser-shim.js, pinned rev) verbatim, plus a Stylix theming seed
// appended in the IIFE below, so all upstream behaviour (window.browser polyfill,
// user-link pinning, Yahoo relay) is preserved.
//
// How the styling reaches Actual:
//   1. Seed localStorage["local:user-themes"] with a "user:stylix" palette built
//      from the base16 palette Stylix generates at build time (__ABT_STYLIX_KEYS__).
//   2. Seed localStorage["local:catppuccin-palette"] = "user:stylix" so ABT's
//      theme init paints that palette on first load.
//   3. Run *after* the upstream shim (not immediately) so its user-link pin wins.
//   4. Only seed the selection when it has never been set. Switching theme in
//      ABT's own Theme Customizer (Native / built-in / community / another user
//      theme) is then remembered and the shim never overrides it again.
//   5. ABT's settings-sync copies "user-themes" and "catppuccin-palette" into the
//      open budget, so the choice follows the budget across browsers/devices.
//
// To get Actual's default look back: open ABT settings -> Theme Customizer ->
// pick "Native". To drop the Stylix seed entirely, set
// services.abt-sidecar.stylixTheme = false and rebuild.
// Minimal window.browser polyfill so WXT code works
(function () {
	if (window.browser?.runtime?.id) {
		return;
	}

	const LOCAL_PREFIX = "local:";
	const changeListeners = [];

	function readLocalStorage(key) {
		try {
			const raw = localStorage.getItem(key);
			return raw === null ? undefined : JSON.parse(raw);
		} catch {
			return undefined;
		}
	}

	function writeLocalStorage(key, value) {
		try {
			localStorage.setItem(key, JSON.stringify(value));
		} catch {
			// ignore
		}
	}

	function relayUrl(url) {
		try {
			const target = new URL(url);
			const match =
				target.hostname === "query2.finance.yahoo.com" &&
				target.pathname.match(/^\/v8\/finance\/chart\/(.+)$/);
			return match ? `/abt-api/yahoo-chart/${match[1]}${target.search}` : null;
		} catch {
			return null;
		}
	}

	// pin user-link to server location
	writeLocalStorage(LOCAL_PREFIX + "user-link", location.origin + "/");

	window.browser = {
		runtime: {
			id: "abt-sidecar-mvp",
			getURL: (path) => "/abt" + (path.startsWith("/") ? path : "/" + path),
			// Templated in by server.js from the repo's package.json at request
			getManifest: () => ({ version: "__ABT_VERSION__" }),
			onMessage: { addListener() {}, removeListener() {} },
			onInstalled: { addListener() {} },
			// Yahoo's chart API never sends CORS headers, so it goes straight to the
			// sidecar relay; a direct attempt would only fail and log a console error.
			sendMessage: async (message) => {
				if (message?.type !== "fetch") {
					return undefined;
				}
				try {
					const res = await fetch(relayUrl(message.url) ?? message.url);
					if (!res.ok) {
						return { ok: false, status: res.status };
					}
					const text = await res.text();
					const data = message.responseType === "json" ? JSON.parse(text) : text;
					return { ok: true, data };
				} catch {
					return { ok: false, status: 0 };
				}
			},
		},
		storage: {
			local: {
				get: async (keys) => {
					const list =
						typeof keys === "string"
							? [keys]
							: Array.isArray(keys)
								? keys
								: Object.keys(keys || {});
					const out = {};
					for (const k of list) {
						const v = readLocalStorage(k);
						if (v !== undefined) {
							out[k] = v;
						}
					}
					return out;
				},
				set: async (items) => {
					const changes = {};
					for (const [k, v] of Object.entries(items)) {
						changes[k] = { newValue: v };
						writeLocalStorage(k, v);
					}
					for (const cb of changeListeners) {
						try {
							cb(changes, "local");
						} catch {
							// ignore listener errors
						}
					}
				},
				remove: async (keys) => {
					const changes = {};
					for (const key of typeof keys === "string" ? [keys] : keys) {
						if (localStorage.getItem(key) === null) {
							continue;
						}
						changes[key] = { oldValue: readLocalStorage(key), newValue: undefined };
						localStorage.removeItem(key);
					}
					for (const cb of changeListeners) {
						try {
							cb(changes, "local");
						} catch {
							// ignore listener errors
						}
					}
				},
				// Only clear our own "local:"-prefixed keys — this origin's
				// localStorage also holds Actual's own app state.
				clear: async () => {
					const changes = {};
					for (const key of Object.keys(localStorage)) {
						if (!key.startsWith(LOCAL_PREFIX)) {
							continue;
						}
						changes[key] = { newValue: undefined };
						localStorage.removeItem(key);
					}
					for (const cb of changeListeners) {
						try {
							cb(changes, "local");
						} catch {
							// ignore listener errors
						}
					}
				},
			},
			onChanged: {
				addListener: (cb) => changeListeners.push(cb),
				removeListener: (cb) => {
					const i = changeListeners.indexOf(cb);
					if (i >= 0) {
						changeListeners.splice(i, 1);
					}
				},
			},
		},
		tabs: {
			query: async () => [],
			create: async ({ url }) => {
				window.location.href = url;
			},
		},
	};
})();

// Stylix theming seed (sidecar-only addition; see the header comment).
(function () {
	var keys = __ABT_STYLIX_KEYS__;
	var themeId = "user:stylix";
	var name = "__ABT_STYLIX_NAME__";

	try {
		var themes = JSON.parse(localStorage.getItem("local:user-themes") || "null") || {};
		themes[themeId] = { id: themeId, name: name, mode: "dark", type: "palette", keys: keys };
		localStorage.setItem("local:user-themes", JSON.stringify(themes));

		// Done last so the upstream shim's user-link pin (which ran just above)
		// is not clobbered by ours.
		if (!localStorage.getItem("local:catppuccin-palette")) {
			localStorage.setItem("local:catppuccin-palette", JSON.stringify(themeId));
		}
	} catch (e) {
		// localStorage can throw in private mode; leave ABT on its default theme.
	}

	// Scoped contrast fix for the budget month-summary flow panel. ABT derives
	// .flow__body's background from
	//   --color-budgetHeaderCurrentMonth = color-mix(mantle, surface0 30%)
	// which, with this palette (mantle = base01 #221d2b, surface0 = base02
	// #524763), lands at a lighter ~#2e2235. The panel's "subdued" labels
	// (--color-pageTextSubdued = base03 #373142) then sit darker than their own
	// background and become unreadable. Pin *only this element's* background to
	// mantle (base01, #221d2b) — the shared token is untouched, so the budget
	// header and every other surface keep their current colours.
	// TODO-remove: delete this block once the palette's mantle/surface0 pair no
	// longer inverts against pageTextSubdued.
	try {
		var flowStyle = document.createElement("style");
		flowStyle.textContent =
			".flow__body.svelte-n5tsx9 { background-color: var(--ctp-mantle) !important; }";
		(document.head || document.documentElement).appendChild(flowStyle);
	} catch (e) {
		// no-op
	}
})();
