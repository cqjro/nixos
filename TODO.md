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

- [ ] **Upstream-fixes watchdog** — build a monitor (background process or
      agent) that tracks the "Pending upstream fixes" registry rows in
      `README.md` / `AGENTS.md`, periodically re-checks each upstream
      issue/PR, and prompts me (or an agent) when a fix has landed so the
      workaround can be removed and verified — **7/10**
  - *Proposed approach:* parse the registry table (its `Blocked on` column is
    already structured, e.g. `NixOS/nixos-hardware#2027`), then for each row
    poll the GitHub API (`gh`/`nix search` for nixpkgs-landed cases). Run it as a
    systemd user timer writing to a status file, and surface landed fixes as a
    `notify-send` + a line in `Rebuild warnings`-style log. A cheaper v1: a
    script that, on the next rebuild, greps the registry, checks each linked
    issue state, and prints a "remove workaround #N" reminder.

- [ ] **Rebuild warnings catcher** — build a system that captures the warnings
      emitted during `./rebuild.sh` runs (currently streamed through `bat`
      and discarded), documents them somewhere durable, and queues them for
      agents to investigate and solve later — **4/10**
  - *Proposed approach:* `rebuild.sh:74` already `tee`s the full output to
    `./.log/nixos-switch.log` — so warnings are *persisted* today, just never
    extracted. Add a post-build step that greps that log for
    `warning|deprecated|insecure|trace:` and appends a deduplicated section to a
    durable file (e.g. `.log/warnings.md` or a `WARNINGS.md` queue). Because
    `.log/` is likely gitignored, confirm the durable target before wiring it.

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

- [ ] **DWSIM** — check whether DWSIM can be downloaded on NixOS declaratively
      yet — **2/10** (research only; check nixpkgs/NUR and wine/AppImage viability)

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

- [ ] **Secrets audit** — do a configuration audit for better implementing
      secrets (e.g. replace hand-written files under `/var/lib` and gitignored
      tokens with something declarative like sops-nix or age) — **7/10**
  - *Proposed approach:* migrate incrementally, not in one sweep. Add either
    `sops-nix` or `agenix` as a flake input (neither exists today), create a
    host key, and start with the highest-value single secret (e.g. the
    Cloudflare tunnel creds / miniflux `admin.env`); document the pattern in the
    server-module recipe, then convert the remaining `/var/lib` secrets one
    module at a time, verifying each host rebuilds. Age-based (agenix) fits the
    current "one file per host" style more cleanly than committing sops blobs.

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

- [ ] **NixOS MCP server** — give the AI clients (OpenCode, Claude Code) real
      NixOS package/option data over MCP instead of guessed attribute names — **3/10**
  - *Proposed approach:* `pkgs.mcp-nixos` (upstream
    [`utensils/mcp-nixos`](https://github.com/utensils/mcp-nixos)) is already in
    nixpkgs and exposes package / option / Home Manager / flake search over
    STDIO — add it to a `home-manager/ai-tools/` fragment and register it as an
    MCP server in OpenCode's config (`programs.opencode`, currently only the
    package is enabled) and in Claude Code's own settings file. The lighter
    [`DanielRamosAcosta/nixos-mcp`](https://github.com/DanielRamosAcosta/nixos-mcp)
    (TypeScript, options-only, needs Node 24) is the alternative if the
    Python/FastMCP dependency set is unwanted. Verify with one real package-name
    query before wiring it into every client.

## Server (REDRUM)

- [ ] **Immich** — self-hosted photos and videos (replacement/supplement for
      current photo handling) — **6/10** (follow the REDRUM recipe; the real
      work is the ML/`external_media` and large-storage decisions, plus
      Postgres/Redis, which no current module runs)

- [ ] **RSS workflow** — finalize the feed list (`modules/system/rss-sources.nix`)
      and reading workflow end-to-end: front-end apps + KOReader integration
      on top of the existing Miniflux setup — **6/10**
  - *Proposed approach:* feed list is a small edit; the workflow is the work.
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

- [ ] **T3 Code** — finish setting up T3 Code end-to-end: the server module
      (`modules/server/t3code.nix`, port 8086) and the desktop client
      (`modules/home-manager/ai-tools/t3code.nix`, GOD-KILLER) are wired, but
      the Cloudflare side is still a placeholder — **3/10**
      (mechanical: the module + README steps already exist)
  - [ ] Create the `t3code` tunnel on REDRUM and replace
        `TODO-REPLACE-WITH-T3CODE-TUNNEL-UUID` in `modules/server/t3code.nix`
  - [ ] Provision `/var/lib/cloudflared/t3code.json` (`root:root` 0600) and the
        `t3.cqjro.ca` → `<uuid>.cfargotunnel.com` CNAME
  - [ ] Restart the tunnel unit, run `t3 serve` once to print the headless
        pairing details, then pair the desktop client and link an agent
  - *Proposed approach:* follow README → REDRUM server setup steps 2–6 for the
    tunnel/credentials/DNS, confirm the origin is up on REDRUM
    (`curl -s http://127.0.0.1:8086`), then point the GOD-KILLER client at
    `https://t3.cqjro.ca` and record the pairing flow in the README's
    "log in once" notes.
