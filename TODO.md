# TODO

Personal action items — not tracked as issues. Server items follow the
[server module pattern](README.md#creating-a-server-module-menticide): free local
port, dedicated user, Cloudflare tunnel ingress, README + Homepage updates.

**Effort score:** a 1–10 estimate combining build time and complexity.

- **1–3** — small, mechanical; a fragment edit or a config tweak.
- **4–6** — a focused feature or a multi-file change with some investigation.
- **7–8** — a substantial new subsystem, or one needing upstream research.
- **9–10** — open-ended: greenfield, hardware/OS-level, or no clear path yet.

Where an item is a *concept* rather than a defined implementation, a **Proposed
approach** line sketches how it could be built. The obvious "follow the existing
pattern" solutions (e.g. a new server module = the 5-step MENTICIDE recipe) are not
repeated as proposals.

## System

- [ ] **Agent notifications: decide the setup** — the `agent-notify` hooks are
      installed on both hosts and the desktop popups are verified (they appear in
      `~/.local/state/agent-notify/events.log`); what is left is deciding how
      notifications should work, then the phone side — **3/10** (reference:
      [`docs/notifications.md`](docs/notifications.md))
  - [ ] Decide what should notify and where: T3's native app push, the hooks, or
        both (the native push has fixed text and no machine name; the hooks carry
        host, worktree and branch); and whether approvals, completions and
        failures all matter, or only approvals
  - [ ] Choose the transport: ntfy.sh with a private topic (recommended; the topic
        is the credential, approval text transits a third party) or self-hosted
        on MENTICIDE (`modules/server/ntfy.nix`, optional, human-run `tailscale
        serve`)
  - [ ] Create the topic file on THEOCIDE, subscribe the phone app, copy the
        topic to MENTICIDE for `t3code`, and run test 6.2 (hooks under T3, Supervised
        thread, then MENTICIDE); quiet hours if wanted
  - *Note:* only Supervised threads prompt at all (Full access has nothing to
    approve), so approval pushes depend on the modes you actually run

- [ ] **Zen Browser userContent styling** — fix the Claude theme and style the
      remaining site in `userContent.css` — **3/10** (Google, YouTube, Reddit and
      Wikipedia are done; the existing `webstyling/*.nix` files are the template)
  - [ ] **Fix the Claude (claude.ai) styling**
        (`modules/theme/webstyling/claude-web-styling.nix`; it exists but is not
        in the flat Stylix pass the other sites got, and Claude re-injects its
        palette after hydration, so some surfaces still show Claude's own colors)
    - [ ] Collect manual screenshots of claude.ai (it is login-only, so
          `theme-shots` cannot reach the chat UI): new chat, an open conversation
          with code blocks, the sidebar and project list, settings, a modal and a
          menu, an artifact, and a streaming response. Mark each surface that still
          shows Claude's own colors or the wrong contrast
    - [ ] Fix the override layer: the `data-theme`/`data-mode` selectors Claude
          re-applies after hydration, the `hsl(var(--token))` triples, and the
          legacy `--claude-*` aliases, so every token resolves to a Stylix
          `baseXX` color (no hardcoded colors)
    - [ ] Fix the surface-level problems from the screenshots: message bubbles,
          input box and send button, code-block and inline-code colors,
          sidebar hover/active states, buttons, menus, modals, tooltips and
          scrollbars; use Stylix fonts and the flat radii of the Reddit/YouTube
          passes
    - [ ] Check light and dark scheme behavior (`zen.view.window.scheme`) and that
          nothing becomes unreadable (links, disabled text, selection)
    - [ ] Deliver the RAW/OLD/NEW comparison from
          [`docs/agents/theme-shots.md`](docs/agents/theme-shots.md), built from
          your screenshots because there is no logged-out page list for claude.ai
          (decide whether the login page should be added to
          `theme-shots-urls.txt`, which also needs its domains in the PAC)
  - [ ] Instagram (deferred: not in use)

- [ ] **`theme-shots-login` helper (optional)** — let site-styling threads see
      logged-in pages (feeds, subscriptions, settings) without you attaching
      manual screenshots — **5/10**
  - *Proposed approach:* a second excluded command next to `theme-shots`
    (`modules/scripts/theme-shots-login.sh`, packaged by `modules/theme/theme-shots.nix`)
    that runs headless Zen against ONE dedicated persistent profile
    (`~/.local/state/theme-shots-login/`), never your real profile. You log in once
    by hand in a visible window with a **throwaway test account per site** (no
    password manager, no 2FA tied to your phone), after which the helper reuses the
    saved session for RAW vs THEMED shots of the logged-in page list. Keep the
    PAC domain confinement and the settle/rejection checks from `theme-shots`.
  - *Why optional:* the logged-out pages and your own screenshots already cover
    most of the work, and an automated browser holding any session is a bigger
    trust surface than the throwaway-profile `theme-shots`.
  - [ ] Decide it is worth building (you chose manual screenshots on 2026-11-10;
        revisit only if logged-in pages keep being the bottleneck)
  - [ ] Security review (tier 2) before the first run: the session cookies persist
        on disk, shots of logged-in pages contain personal data that goes to the
        model provider, and a bot-detected throwaway account can be locked or
        banned (Google, Reddit and Instagram all do this)
  - [ ] Add the page list for the logged-in pages and a `docs/agents/theme-shots.md`
        section; delete the profile directory after each styling session

- [ ] **T3 Code keyring name: decide whether to follow `t3code`** — nixpkgs
      0.1.8 deliberately dropped `productName` (the desktop app is now named
      `t3code`, like the official builds), so the keyring key is looked up as
      `t3code`; the `jq` workaround in `modules/home-manager/ai-tools/t3code.nix`
      keeps the old `T3 Code (Beta)` key working. Keeping it costs nothing, so
      this is a decision, not a fix (registry row 17) — **3/10**
  - *Decision:* keep the workaround (default), or migrate once and follow
    upstream. No deadline; revisit if nixpkgs changes the naming again (the
    row-17 probe fires when `del(.productName)` leaves `unwrapped.nix`)
  - [ ] If migrating — **You**, THEOCIDE, no agent (it touches the secret): back up
        `~/.local/share/keyrings`, close T3 Code, copy the key from
        `application = T3 Code (Beta)` to `application = t3code` with
        `secret-tool` (never print it; a `t3code` entry may already exist from
        the 0.1.8 runs, decide whether to overwrite it)
  - [ ] **Agent**: one branch removes the `jq` step and its `# TODO-remove:`
        comment in `t3code.nix`, registry row 17 (both tables) and the
        `row-17` probe; `./rebuild.sh check THEOCIDE` and `build THEOCIDE`
  - [ ] **You**: merge, `./rebuild.sh switch THEOCIDE`, start T3 Code and
        confirm environments, projects and theme are back; if not, the old key
        is untouched, so restore the workaround

- [ ] **Game window control** — figure out the optimal way of controlling
      games on different windows (focus, moving between monitors/workspaces)
      and revise the Hyprland keybinds to do so — **6/10**
  - *Proposed approach:* games mostly land on `special:magic` already
    (`hyprland.nix:286-296`). Investigate `windowrulev2` rules per-game
    (Steam appid / class / title) for `workspace`/`monitor`/`fullscreen`/`pin`,
    then add a small "move active game" bind group. May need
    `focus-window.sh`/`pip-move.sh`-style helpers for cross-monitor moves.

- [ ] **Keybind audit** — revise all keybinds in general so that there are no
      conflicts and they are easy to remember — **4/10**
  - *Proposed approach:* the Lua `bind` list (`hyprland.nix:223-273`), xremap
    launchers (`keyboard/xremap.nix`) and the cheatsheet
    (`scripts/keybind-cheatsheet.sh`) are three sources of truth that can drift.
    Generate the cheatsheet from the parseable bind list so it can't go stale,
    and add a conflict check (duplicate chord detection) as a small script.

- [ ] **Picture-in-picture** — implement PiP properly within Hyprland and fix
      its keybinds, and ensure Zen has automatic picture-in-picture mode — **5/10**
  - *(partial today: `match.title = "^Picture-In-Picture$"` rule at
    `hyprland.nix:292-295` + `pip-move.sh` binds — but the rule's casing
    disagrees with `pip-move.sh:4,7` `"Picture-in-Picture"`, so investigate that
    mismatch first.)*
  - *Proposed approach:* fix the title-case mismatch so `pip-move.sh` actually
    targets the float rule; give the window a fixed size/position instead of
    relying on manual moves (the archived `hyprland-old.nix:333` did this);
    Zen-side enable `media.video-cast`/`pictureInPicture` and the
    Zen "picture-in-picture" toggle in `zen-browser.nix` prefs.

- [ ] **Zen "Little Arc"** — set up Zen with similar functionality to Little
      Arc from the Arc browser (summonable floating mini-browser window) — **6/10**
  - *Proposed approach:* no first-class Little Arc in Zen. Closest: a floating,
    sized, always-on-top Hyprland window rule for a Zen "mini" window (title/class
    based), plus a summon keybind that opens a small Zen window and a way to push
    the current tab into it. Alternatively a Zen mod/custom `userChrome` that
    adds a "open in mini window" action. This is the most speculative Zen item —
    worth prototyping the window-rule version first.

- [ ] **Zen cleanup** — clean up Zen Browser so that not all of the workspaces
      are declarative, and implement Firefox Sync for bookmarks and tabs — **3/10**
      (workspaces are force-set via `containersForce`/`spacesForce`/`pinsForce`
      at `zen-browser.nix:230-232`; drop the force flags and trim the lists)

- [ ] **CAD flow sheets** — check whether CADCraft or other open-source CAD
      software can adequately create flow sheets on Linux yet — **2/10**
      (research/evaluation only)

- [ ] **Screen time tracking** — set up screen time tracking using some open
      source method — **6/10** (nothing exists; greenfield)
  - *Proposed approach:* the Wayland-native answer is the compositor's own
    window-event stream. Options: (a) `hyprland` IPC event socket
    (`sockaddr`/`hyprctl -j activewindow`) polled by a small daemon into SQLite;
    (b) `ActivityWatch` (has a `aw-qt`/`aw-server` and a Hyprland watcher —
    check nixpkgs) as a turnkey alternative; (c) `wakatime`-style. Recommended:
    evaluate ActivityWatch first (least code), fall back to a custom
    Hyprland→SQLite poller if its Wayland support is poor.

- [ ] **Theme update** — revise the window shadows, specifically how focused
      vs unfocused windows are treated, and make that look better — **3/10**
      (shadows are a small block at `hyprland.nix:167-173`; iterate on
      `range`/`render_power`/`color` vs `color_inactive`)

- [ ] **Logitech device setup** — check out [OpenLogi](https://openlogi.org)
      (`github:AprilNEA/OpenLogi`) as the Logitech Options+ replacement: button
      remaps, DPI, SmartShift and per-app profiles for the mouse/keyboard from a
      local TOML config instead of Options+ (or Solaar / logiops) — **4/10**
      (it is in nixpkgs as `pkgs.openlogi` since 0.6.25, so the work is wiring,
      not packaging)
  - [ ] Decide what owns remapping: OpenLogi's evdev/uinput hook overlaps
        xremap, which already drives the keyboard layout
  - *Proposed approach:* nothing Logitech-specific exists in the tree today
    (OpenRGB only touches the mouse's lighting). `pkgs.openlogi` ships the GUI
    (`openlogi-gui`), the agent (`openlogi-agent`), `/lib/udev/rules.d/70-openlogi.rules`
    and a systemd **user** unit in `$out/share/systemd/user` — but no NixOS
    module, so a host fragment must add `services.udev.packages = [ pkgs.openlogi ]`
    for `/dev/hidraw*` access, `hardware.uinput` (as xremap already needs) and a
    user service/autostart for the agent, with `~/.config/openlogi/config.toml`
    declaratively seeded (schema is strict; device blocks are keyed by physical
    identity — receiver serial + slot, or the device's own serial). Pair new
    Bolt/Unifying devices once with Solaar first — OpenLogi's Bolt pairing is
    still in progress — and quit any other HID++ manager so the two don't fight
    over the receiver. Upstream flags it as pre-stable, so verify the MX
    mouse's SmartShift/DPI/thumb-wheel behaviours before dropping any other tool.

## Server (MENTICIDE)

- [ ] **Immich** — self-hosted photos and videos (replacement/supplement for
      current photo handling) — **6/10** (follow the MENTICIDE recipe; the real
      work is the ML/`external_media` and large-storage decisions, plus
      Postgres/Redis, which no current module runs)

- [ ] **RSS workflow** — finalize the feed list (`modules/system/rss-feeds.json`;
      `rss-sync` already syncs it with Miniflux) and reading workflow
      end-to-end: front-end apps + KOReader integration on top of the existing
      Miniflux setup — **6/10**
  - *Open:* the US NRC news feed is still missing from the list —
    `nrc.gov` returns 403 to non-browser clients, so copy the exact feed link
    from <https://www.nrc.gov/public-involve/rss> in a browser, add it to
    `rss-feeds.json` (`"category": "Nuclear"`), and check that Miniflux (on
    MENTICIDE) can actually fetch it before relying on it.
  - *Proposed approach:* the workflow is the work.
    Miniflux + ReactFlux already cover the server/browser side. For KOReader,
    point it at Miniflux's Fever API (Miniflux exposes `/fever/`) or generate
    per-feed EPUBs; then decide the desktop front-end (Glance reader widget vs a
    dedicated app). Define a "done" reading loop: subscribe → triage in
    Miniflux → long-form to KOReader.
  - **When finalizing, provision the two missing tunnel credentials on MENTICIDE.**
    Miniflux and ReactFlux are wired (`miniflux.nix:42-44`,
    `reactflux.nix:147-149`) but their credential files were never created, so
    both `cloudflared-tunnel-*.service` units fail at runtime with
    `status=243/CREDENTIALS … No such file or directory` (seen on the MENTICIDE
    2026-10-20 switch; not a build failure). Follow
    [README → Cloudflare Tunnels](README.md#cloudflare-tunnels) steps 2–3, i.e.
    on MENTICIDE:
    ```bash
    nix shell nixpkgs#cloudflared -c cloudflared tunnel login
    sudo cloudflared tunnel create miniflux
    sudo cloudflared tunnel create reactflux
    sudo mkdir -p /var/lib/cloudflared
    sudo mv ~/.cloudflared/<uuid>.json /var/lib/cloudflared/miniflux.json
    sudo mv ~/.cloudflared/<uuid>.json /var/lib/cloudflared/reactflux.json
    sudo chown root:root /var/lib/cloudflared/*.json
    sudo chmod 600 /var/lib/cloudflared/*.json
    sudo systemctl restart cloudflared-tunnel-*.service
    ```
    Also confirm each hostname has its DNS **CNAME** → `<uuid>.cfargotunnel.com`
    (README step 4). If the JSONs already exist, it is an ownership/permission
    problem (`root:root 0600`), not a missing tunnel.

- [ ] **Self-hosted Obsidian vault** — replace the GitHub sync with a vault
      hosted on MENTICIDE so it is available on every device, and migrate the
      current vault to it — **5/10** (a server module plus a one-time migration;
      the mobile clients and the backup path are the real work)
  - *Proposed approach:* **Obsidian Self-hosted LiveSync** (community plugin) on
    top of **CouchDB** (`services.couchdb` in nixpkgs): near-real-time sync with
    end-to-end encryption, and the plugin has desktop, Android and iOS clients,
    which Syncthing handles poorly on iOS. Follow the MENTICIDE recipe (loopback
    port — CouchDB defaults to 5984 — dedicated user, data under `/var/lib/couchdb`,
    admin credentials in a root-owned runtime file the human creates, never in
    the repo). Mobile clients need HTTPS, so expose it through a Cloudflare tunnel
    hostname (own login, and CORS set for `app://obsidian.md`,
    `capacitor://localhost` and `http://localhost`) or Tailscale Serve with a
    certificate (the logged-certificate trade-off is in the Secrets item below).
    Alternative if a server database is unwanted: Syncthing with a MENTICIDE
    relay (plain files, no server database, but weak on iOS).
  - [ ] Decide the sync method (LiveSync vs Syncthing) and whether the vault needs
        to be reachable off the tailnet; the answer fixes the exposure (tunnel vs
        Tailscale only)
  - [ ] Write the `modules/server/obsidian-livesync.nix` module (CouchDB, tunnel
        or Tailscale Serve, README + Homepage + Glance entries)
  - [ ] **Migrate the vault:** take a full copy of the current GitHub-synced vault
        first (keep the git history as a fallback), set up LiveSync from the
        desktop with that vault as the source, add the other devices one at a time
        (fetch from the server, never push an empty vault over it), confirm
        attachments and plugin settings arrive, then turn off the Obsidian Git
        plugin and archive the GitHub repo
  - [ ] **Periodic backups** of the vault, to Proton Drive or to GitHub (or
        both). CouchDB stores the notes as chunked, encrypted documents, so a dump
        of the database alone is not a readable backup. Options: (a) a systemd
        timer that exports the CouchDB database and also writes a plain-file copy
        of the vault (a headless LiveSync client, or restoring into a scratch
        vault), then (b) pushes the plain copy to a **private** GitHub repo, or (c)
        uploads an encrypted archive with `rclone` (it has a Proton Drive backend,
        still marked beta) or `restic`. Credentials live in runtime files the human
        creates; prune old copies and run one restore test before relying on it
  - [ ] Decide whether the vault backup is also copied off MENTICIDE (the machine
        holding the live data should not be the only home of its backup)

- [ ] **Pi-hole** — network-wide DNS ad blocking — **5/10**
  - *Decision to make:* Pi-hole is a *network* service, not a tunneled app, so
    it doesn't fit the Cloudflare pattern — it needs DHCP/DNS ownership on the
    LAN. Either (a) run Pi-hole on MENTICIDE as LAN DNS and point the router's
    DHCP at it, or (b) use `AdGuard Home`/blocky which integrate more cleanly
    with NixOS (`services.adguardhome`). Confirm whether MENTICIDE is always-on and
    on the same subnet before choosing; MENTICIDE already runs Tailscale, which
    helps remote clients but not LAN DNS.

- [ ] **Glance** — rework the Glance config (`modules/server/glance.nix`) into
      a dashboard I would actually use — **4/10**
      (the config is 401 lines of widgets already; this is curation + layout,
      not new plumbing)

- [ ] **Health data tracking** — set up a service that records and backs up
      Apple Health data, provides dashboards to analyze it, and tracks data
      from different wearable sources (Amazefit Helio strap, Apple Watch, etc.) — **8/10** (greenfield, multi-source ingest + dashboards)
  - [ ] Include data exported from Bevel
  - [ ] Include food data exported from MacroFactor
  - [ ] Include workout data exported from MacroFactor workouts
  - [ ] **Gym tracking: adopt OpenGym and migrate away from MacroFactor** —
        move workout logging to OpenGym without losing the data reaching Apple
        Health/Bevel
    - [ ] Check whether OpenGym writes workouts into Apple Health, so the data
          is available in Bevel
    - [ ] Check whether OpenGym has live events (e.g. Live Activities / lock
          screen or Watch session while a workout is running)
    - [ ] Check whether OpenGym's workout events track heart rate, and whether
          that heart rate is written into Apple Health/Bevel
    - [ ] **Replace MacroFactor for nutrition and recipe tracking** — must keep
          photo-based macro logging (take a picture of a meal to log macros),
          plus recipe tracking. Candidate: use Bevel alone for nutrition and
          keep the health data on MENTICIDE, synced from Apple Health. Decide
          this before cancelling MacroFactor, and export its history first;
          once migrated, the MacroFactor import items above go away
  - *Proposed approach:* two halves. **Ingest:** Apple Health exports as XML
    (Health app → "Export All Health Data"); parse to a DB. Bevel/MacroFactor
    export CSV/JSON — normalize all sources into one schema keyed by timestamp +
    source. **Store/dashboards:** Postgres (or SQLite) on MENTICIDE + Grafana
    (fits the Glance-style homelab) or a self-hosted app; wire a Grafana panel
    and link it into Glance/Homepage. Start with Apple Health only, add the
    wearable/MacroFactor imports incrementally.

- [ ] **Calibre server** — set up a proper Calibre server instance (content
      server on MENTICIDE) — **4/10** (nixpkgs ships `calibre-web`; follow the
      MENTICIDE recipe with the calibre library on disk)
  - [ ] Figure out a good comic reading workflow connecting Calibre to KOReader
    - *Proposed approach:* run `calibre-web` (not `calibre-server`) for the web
      UI + OPDS; expose an OPDS catalog that KOReader's OPDS browser can point
      at (either directly over Tailscale or via a tunnel hostname). Comics:
      convert CBZ/CBR into the library, and use KOReader's OPDS/`calibre-web`
      sync to pull them; verify KOReader renders CBZ directly.

- [ ] **Audiobook media server** — stand up a platform to host and stream
      audiobooks (podcast-style progress + resumable playback) on MENTICIDE — **6/10**
  - *Proposed approach:* the mature self-hosted options are
    **Audiobookshelf** (books + podcasts, mobile apps, progress sync, OPDS-ish)
    or **Jellyfin** with an audiobook library (but Jellyfin's audiobook UX is
    weaker: no chapter-level progress across devices). Audiobookshelf fits best
    and has the same shape as a normal server module (dedicated user, library on
    disk, tunnel hostname). Decide first whether this should *share* the Calibre
    library above or stay separate, and whether to merge with the `Calibre server`
    item into one "books" stack (e-reader + audio) exposed via a single OPDS
    entry point. `nixpkgs` ships `audiobookshelf`; follow the MENTICIDE recipe
    (port 8087 is the next free after the ABT sidecar's 8086).

- [ ] **Secrets: remaining steps after the repo went public** — the steps left
      from the secrets audit (`docs/secrets.md` section 4 and the private audit);
      `cqjro/nixos` became public on 2026-11-05 — **3/10**
  - [ ] Optional hardening for the public `*.cqjro.ca` hostnames (decided
        2026-11-05 to keep them in the repo: the tunnels are locally managed, so the
        names are in the modules, and every service has its own login; if they ever
        must stay private, use placeholders plus a local override or
        Cloudflare-managed tunnels)
    - [ ] Optional: put Cloudflare Access (Zero Trust, free tier) in front of the
          browser-only apps (not required before the flip): Cloudflare
          dashboard → Zero Trust → Access → Applications → Add an application →
          Self-hosted → hostname (`home.cqjro.ca` Glance, `status.cqjro.ca`
          Beszel, then Homepage) → Allow policy for your email, one-time PIN.
          Check each in a private browser window: it must ask for the PIN
          first
    - [ ] Apps with mobile or API clients (Miniflux + ReactFlux, Linkwarden,
          Actual) need a bypass rule or service token for those clients, so
          leave them on their own logins; `docs` (and possibly `budget`) are covered by the
          Tailscale item below
  - [ ] Decide what to do with the security-posture docs (`AGENTS.md`,
        `docs/agents/t3-claude.md` also say where credentials live). Tool-standard
        paths (`~/.ssh`, `~/.config/gh`) are public knowledge and the `/var/lib`
        paths are already in the modules, so the split above is the main fix
  - [ ] **Move `docs.cqjro.ca` (and possibly `budget.cqjro.ca`) off the
        internet onto Tailscale** — Paperless (`modules/server/paperless.nix`) and
        Actual Budget (`modules/server/actual-budget.nix`, with the ABT sidecar in
        `actual-budget-tweaks.nix`) are reachable from the internet through
        Cloudflare tunnels; make them tailnet-only — **4/10**
    - [ ] Publish each over Tailscale Serve from a root oneshot, like
          `t3code-tailscale-serve` in `modules/server/t3code.nix` (agents must not
          run `tailscale serve`/`set` themselves). Port 443 is taken by T3 Code, so
          give each app its own `--https=<port>`; budget goes through the sidecar
          (`127.0.0.1:8086`), not Actual's `5006`
    - [ ] Remove the cloudflared ingress block and the `<uuid>.cfargotunnel.com`
          CNAME for each app, then delete the now-unused tunnel and its
          credentials file; update the README tunnel/DNS tables, the Homepage and
          Glance links, and the hostname table
    - [ ] Decide `budget` separately: Actual's desktop/mobile sync clients and
          Paperless's mobile app then need Tailscale on every device that syncs;
          the browser UI still works from any tailnet device
    - [ ] Check the HTTPS-certificate trade-off: Tailscale HTTPS certificates are
          publicly logged, which would reveal the machine and tailnet name
          (Tailscale's docs; not rechecked here). Plain `http` over the tailnet
          avoids that (`tailscale serve --http=<port>`); never use Funnel, which
          is the internet-facing variant
    - [ ] Verify from a device off the tailnet that both hostnames no longer
          answer, and on-tailnet that they do
