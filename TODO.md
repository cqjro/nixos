# TODO

Personal action items — not tracked as issues. Server items follow the
[server module pattern](README.md#creating-a-server-module-redrum): free local
port, dedicated user, Cloudflare tunnel ingress, README + Homepage updates.

**Effort score:** a 1–10 estimate combining build time and complexity.

- **1–3** — small, mechanical; a fragment edit or a config tweak.
- **4–6** — a focused feature or a multi-file change with some investigation.
- **7–8** — a substantial new subsystem, or one needing upstream research.
- **9–10** — open-ended: greenfield, hardware/OS-level, or no clear path yet.

Where an item is a *concept* rather than a defined implementation, a **Proposed
approach** line sketches how it could be built. The obvious "follow the existing
pattern" solutions (e.g. a new server module = the 5-step REDRUM recipe) are not
repeated as proposals.

## System

- [ ] **Finish the repo move** — `cqjro/nixos` has been **public since
      2026-11-05** (history verified: no firmware paths, no tripwire strings, only
      noreply identities, gitleaks clean, trufflehog findings all false
      positives). `master` is protected by a ruleset (pull request required, no
      force pushes, no deletion, empty bypass list), and the account-level
      interaction limit (collaborators only, 6 months) is set. GOD-KILLER and
      REDRUM are switched on the new repo. These owner-only steps are left —
      **1/10** (detail in [`docs/firmware.md`](docs/firmware.md)). Delete this
      item when all are done
  - [ ] **Interaction limit renewal:** it lapses about **2027-05-05**; renew it
        (account Settings → Moderation options → Interaction limits) in early
        April. The worker briefs never fetch comments (`--json title,body`), which
        covers worker reads during a gap; strangers can still comment, and you
        still see it
  - [ ] **Confirm secret scanning and push protection** are on (repo Settings →
        Code security); optionally disable Actions (the repo has no workflows)
  - [ ] **schedules:** all three tasks are live, with workers launching in `auto`.
        Still to do: REDRUM bootstrap via `unswitched-changes.md`
  - [ ] Optional: Claude re-login (secrets 4.4)
  - [ ] Delete the six test labels from the early test run if unwanted
  - [ ] **Cleanup now that it is public:** delete `~/.nixos.pre-rewrite` (and
        `~/nixos-archive-private` once no longer needed; keep `~/private-backup`);
        optionally archive `nixos-archive` on GitHub; token expiry reminders (the
        GOD-KILLER token was made 2026-11-03, 30-90 days; the REDRUM `t3code`
        token expires 2027-02-02)
  - [ ] LittleNix is parked (`docs/firmware.md` "LittleNix (parked)"): its files
        stay in the private archive repo; extract them only if you want to
        build or reinstall it
  - *Why a new repo:* GitHub cannot be made to forget the old commits, so the
    old repo stays private as the archive and the public one never contains them.

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
        on REDRUM (`modules/server/ntfy.nix`, optional, human-run `tailscale
        serve`)
  - [ ] Create the topic file on GOD-KILLER, subscribe the phone app, copy the
        topic to REDRUM for `t3code`, and run test 6.2 (hooks under T3, Supervised
        thread, then REDRUM); quiet hours if wanted
  - [ ] Add `Read(~/.config/agent-notify/**)` to the deny list in `claude-code.nix`
  - *Note:* only Supervised threads prompt at all (Full access has nothing to
    approve), so approval pushes depend on the modes you actually run

- [ ] **Waydroid Android TV** — turn this PC into a pseudo Android TV — **7/10**
      (an archived `modules/_archive/waydroid.nix` already exists to
      reintegrate; the kiosk session/autologin is the hard half)
  - [ ] Configure Waydroid (Android TV image / launcher) as a NixOS + home-manager module
  - [ ] Make it bootable: boot straight into the Android TV session, kiosk-style,
        similar to <https://youtu.be/nROKp0BpFek?si=b9QBhJqReF9XOLH3>
        (dedicated session + autologin, Android TV as the default target)
  - *Proposed approach:* reintegrate the archived module first (needs a manual
    image fetch — Waydroid can't ship the system/vendor images declaratively);
    then a dedicated session via `services.xserver.displayManager`/UWSM with a
    Waydroid launcher as the autologin session, mirroring the hyprland session
    wiring, plus a `kiosk`-style `waydroid session` + `waydroid show-full-ui`
    autostart. Frees a second screen from desktop duty.

- [ ] **Zen Browser userContent styling** — fix `userContent.css` site theming — **3/10**
      (per-site CSS already proven; 10 existing `webstyling/*.nix` files are the template)
  - [ ] Google
  - [ ] YouTube
  - [ ] Reddit
  - [ ] Instagram

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

## Server (REDRUM)

- [ ] **Immich** — self-hosted photos and videos (replacement/supplement for
      current photo handling) — **6/10** (follow the REDRUM recipe; the real
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
    REDRUM) can actually fetch it before relying on it.
  - *Proposed approach:* the workflow is the work.
    Miniflux + ReactFlux already cover the server/browser side. For KOReader,
    point it at Miniflux's Fever API (Miniflux exposes `/fever/`) or generate
    per-feed EPUBs; then decide the desktop front-end (Glance reader widget vs a
    dedicated app). Define a "done" reading loop: subscribe → triage in
    Miniflux → long-form to KOReader.
  - **When finalizing, provision the two missing tunnel credentials on REDRUM.**
    Miniflux and ReactFlux are wired (`miniflux.nix:42-44`,
    `reactflux.nix:147-149`) but their credential files were never created, so
    both `cloudflared-tunnel-*.service` units fail at runtime with
    `status=243/CREDENTIALS … No such file or directory` (seen on the REDRUM
    2026-10-20 switch; not a build failure). Follow
    [README → Cloudflare Tunnels](README.md#cloudflare-tunnels) steps 2–3, i.e.
    on REDRUM:
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

- [ ] **Pi-hole** — network-wide DNS ad blocking — **5/10**
  - *Decision to make:* Pi-hole is a *network* service, not a tunneled app, so
    it doesn't fit the Cloudflare pattern — it needs DHCP/DNS ownership on the
    LAN. Either (a) run Pi-hole on REDRUM as LAN DNS and point the router's
    DHCP at it, or (b) use `AdGuard Home`/blocky which integrate more cleanly
    with NixOS (`services.adguardhome`). Confirm whether REDRUM is always-on and
    on the same subnet before choosing; REDRUM already runs Tailscale, which
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
  - *Proposed approach:* two halves. **Ingest:** Apple Health exports as XML
    (Health app → "Export All Health Data"); parse to a DB. Bevel/MacroFactor
    export CSV/JSON — normalize all sources into one schema keyed by timestamp +
    source. **Store/dashboards:** Postgres (or SQLite) on REDRUM + Grafana
    (fits the Glance-style homelab) or a self-hosted app; wire a Grafana panel
    and link it into Glance/Homepage. Start with Apple Health only, add the
    wearable/MacroFactor imports incrementally.

- [ ] **Calibre server** — set up a proper Calibre server instance (content
      server on REDRUM) — **4/10** (nixpkgs ships `calibre-web`; follow the
      REDRUM recipe with the calibre library on disk)
  - [ ] Figure out a good comic reading workflow connecting Calibre to KOReader
    - *Proposed approach:* run `calibre-web` (not `calibre-server`) for the web
      UI + OPDS; expose an OPDS catalog that KOReader's OPDS browser can point
      at (either directly over Tailscale or via a tunnel hostname). Comics:
      convert CBZ/CBR into the library, and use KOReader's OPDS/`calibre-web`
      sync to pull them; verify KOReader renders CBZ directly.

- [ ] **Audiobook media server** — stand up a platform to host and stream
      audiobooks (podcast-style progress + resumable playback) on REDRUM — **6/10**
  - *Proposed approach:* the mature self-hosted options are
    **Audiobookshelf** (books + podcasts, mobile apps, progress sync, OPDS-ish)
    or **Jellyfin** with an audiobook library (but Jellyfin's audiobook UX is
    weaker: no chapter-level progress across devices). Audiobookshelf fits best
    and has the same shape as a normal server module (dedicated user, library on
    disk, tunnel hostname). Decide first whether this should *share* the Calibre
    library above or stay separate, and whether to merge with the `Calibre server`
    item into one "books" stack (e-reader + audio) exposed via a single OPDS
    entry point. `nixpkgs` ships `audiobookshelf`; follow the REDRUM recipe
    (port 8087 is the next free after the ABT sidecar's 8086).

- [ ] **T3 Code on REDRUM** — the REDRUM server (`modules/server/t3code.nix`,
      port 8088) is published over Tailscale Serve (no Cloudflare tunnel); finish
      the setup — **3/10**
  - [ ] Switch REDRUM, then log in Claude Code and `gh` as the `t3code` user
        (`sudo -u t3code -H claude`, `sudo -u t3code -H gh auth login`; README →
        "T3 Code on REDRUM")
  - [ ] Pair GOD-KILLER and the phone and confirm threads from both machines
        show up in one client (2026-11-06: REDRUM has its own `t3code`-owned
        clone and a tested build; GOD-KILLER's T3 terminal gives a real tty with
        working `sudo -v`; still to confirm: the shared project view and a phone
        token with terminal scope)

- [ ] **Secrets: remaining steps after the repo went public** — the steps left
      from the secrets audit (`docs/secrets.md` section 4 and the private audit);
      `cqjro/nixos` became public on 2026-11-05 — **3/10**
  - [ ] REDRUM's `t3code` user needs its own fine-grained token (limited to
        `cqjro/nixos`, Contents + Pull requests) when REDRUM is re-cloned:
        `sudo -u t3code -H bash -c 'read -rs T; printf %s "$T" | gh auth login --with-token'`
        (`docs/secrets.md` 4.1; GOD-KILLER's broad login is already replaced and
        revoked). The Claude re-login (4.4) is optional
  - [ ] Hostnames (`*.cqjro.ca`): they are in the modules because the tunnels
        are locally managed (`hostname → port` ingress rules), and they are
        **not** in certificate logs today (only the wildcard is), so a public repo
        is their first publication. **Decided 2026-11-05: keep them in the repo.**
        Every service has its own login, so Cloudflare Access (below) is optional
        hardening, not a condition of the flip. Alternative if the names ever must
        stay private: placeholders in the repo plus a local override (`--impure`),
        or Cloudflare-managed tunnels
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
