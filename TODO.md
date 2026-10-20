# TODO

Personal action items — not tracked as issues. Server items follow the
[server module pattern](README.md#creating-a-server-module-redrum): free local
port, dedicated user, Cloudflare tunnel ingress, README + Homepage updates.

## System

- [ ] **Waydroid Android TV** — turn this PC into a pseudo Android TV
  - [ ] Configure Waydroid (Android TV image / launcher) as a NixOS + home-manager module
  - [ ] Make it bootable: boot straight into the Android TV session, kiosk-style,
        similar to <https://youtu.be/nROKp0BpFek?si=b9QBhJqReF9XOLH3>
        (dedicated session + autologin, Android TV as the default target)

- [ ] **Zen Browser userContent styling** — fix `userContent.css` site theming
  - [ ] Google
  - [ ] YouTube
  - [ ] Reddit
  - [ ] Instagram

- [ ] **Upstream-fixes watchdog** — build a monitor (background process or
      agent) that tracks the "Pending upstream fixes" registry rows in
      `README.md` / `AGENTS.md`, periodically re-checks each upstream
      issue/PR, and prompts me (or an agent) when a fix has landed so the
      workaround can be removed and verified
- [ ] **Rebuild warnings catcher** — build a system that captures the warnings
      emitted during `./rebuild.sh` runs (currently streamed through `bat`
      and discarded), documents them somewhere durable, and queues them for
      agents to investigate and solve later

## Server (REDRUM)

- [ ] **Immich** — self-hosted photos and videos (replacement/supplement for
      current photo handling)
- [ ] **RSS workflow** — finalize the feed list (`modules/system/rss-sources.nix`)
      and reading workflow end-to-end: front-end apps + KOReader integration
      on top of the existing Miniflux setup
- [ ] **Pi-hole** — network-wide DNS ad blocking
- [ ] **Glance** — rework the Glance config (`modules/server/glance.nix`) into
      a dashboard I would actually use
