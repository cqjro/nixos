# Host rename (2026-11-15): what changed, what the human must do, risks

`GOD-KILLER` → `THEOCIDE`, `REDRUM` → `MENTICIDE`, `LittleNix` → `REGICIDE`
(see [host-names.md](host-names.md) for the meanings). The machines are the
same; only names changed. Git history, old PR text and `modules/_archive/` keep
the old names on purpose.

## Changed in the repository

- `modules/hosts/<OLD>/` → `modules/hosts/<NEW>/` (`git mv`, history kept); the
  `nixosConfigurations` attributes, `networking.hostName`, and every fragment
  (`THEOCIDE`, `THEOCIDE-hardware`, `THEOCIDE-monitors`, …).
- Flake input `nixpkgs-redrum` → `nixpkgs-menticide` (same rev; `flake.lock`
  renamed by hand, no re-lock). `nix flake metadata` shows no input change.
- Docs, skills, reviewer agents, PR template, `claude-guard.sh` and
  `secret-guard-test.sh` fixtures, `host-scopes.json`, `upstream-probes.json`
  (slug `menticide-t2-pin`), README/AGENTS.
- **Transition shim** in `rebuild.sh` (`this_host`, `legacy_name`) and
  `docs/schedules/bin/schedule-precheck`: a machine still called by its old
  hostname is treated as its new host, so the first `./rebuild.sh switch
  THEOCIDE` works before the hostname has changed. Delete the `case` arms once
  all three machines have switched.

## Outside the repository: what the human must do

Everything here changes **only after that machine switches**. Do the machines
one at a time, MENTICIDE last (it is headless; a mistake needs physical access).

### Every machine

- After the switch the kernel hostname changes immediately but running
  sessions keep the old `$HOSTNAME`, and Xwayland apps can lose their
  `~/.Xauthority` cookie (keyed by hostname). **Log out and back in** (or
  reboot) after switching.
- Router/DHCP lease names and any `*.local` (mDNS) name change with the
  hostname; static DHCP reservations keyed by MAC are unaffected.

### MENTICIDE (headless server)

| Item | What happens | Action |
| --- | --- | --- |
| Tailscale | The node keeps its identity and key. Its name follows the OS hostname unless it was renamed by hand in the admin console, so the MagicDNS name becomes `menticide.<tailnet>.ts.net`. HTTPS certs are re-issued for the new name on first use. | Check the machine's name in the Tailscale admin console; rename there if it did not follow. |
| `ssh redrum` | The alias in `~/.ssh/config` (not readable by agents) and `known_hosts` entries still use the old name. The host key is unchanged. | Add `Host menticide` (same `HostName`/`User`), keep the old alias for a while, accept the new name once. Update `nix copy --to ssh-ng://menticide` in your shell history/aliases. |
| T3 Code | `t3code-tailscale-serve.service` republishes under the new name. The desktop and phone environments saved the old `https://redrum.<tailnet>.ts.net` URL; the environment label `REDRUM` is stored in T3, not in this repo. | Re-pair (`sudo -u t3code -H t3 pair --label theocide`) or edit the environment URL, then rename the label in T3. `repositoryIdentity` is the git remote, so projects and threads are unaffected. |
| ntfy (if enabled) | `base-url` must equal the published `https://menticide.<tailnet>.ts.net:8443`; subscribers and `~/.config/agent-notify` (not readable by agents) point at the old URL. | Re-run `tailscale serve` if you published it by hand, then update the URL in `~/.config/agent-notify` and the phone app. Until you do, agent notifications fail silently. |
| Cloudflare tunnel | Identified by the committed UUID and credentials, not the hostname. `*.cqjro.ca` routes are unaffected. | None (the tunnel's display name in the dashboard may still say redrum; cosmetic). |
| Beszel / Homepage / Glance | The Beszel hub keys the agent by key and address; its display name is typed into the hub. Homepage's title is now `MENTICIDE`. | Rename the system in the Beszel UI. |
| Firmware staging dir | `t2-firmware.stagingDir` defaults to `/var/lib/firmware-src/<host>/brcm`, so it is now `/var/lib/firmware-src/MENTICIDE/brcm`; `tmpfiles` creates the empty dir. The store path (`brcm-firmware`, pinned by hash) is host-independent and stays valid. | Safe to leave as is. To tidy: `sudo mv /var/lib/firmware-src/REDRUM /var/lib/firmware-src/MENTICIDE` **and re-run** `nix run .#t2-firmware-import -- MENTICIDE`, because the GC root symlink points into the old path and a dangling root lets `nix-collect-garbage` delete the firmware. |
| Schedules / agents | The `t3code` clone at `/var/lib/t3code/nixos` and its scheduled threads are path-based. The schedule prompts in T3 mention `GOD-KILLER` in a comment only. | None required; edit the "Unswitched changes" prompt text in T3 when convenient. |

### THEOCIDE (desktop)

- Tailscale name becomes `theocide.<tailnet>.ts.net`; if you published the
  desktop T3 backend with `tailscale serve`, the URL phones use changes
  (README, "Reaching THEOCIDE from other devices").
- The T3 desktop app's environment label and any linked-environment entries
  that say `GOD-KILLER` are T3 settings; rename them in T3.
- Stylix, Hyprland, Steam, Waydroid, OpenRGB and `~/.local/share` data do not
  depend on the hostname. Waydroid and Steam keep working.
- GRUB's entry text and `os-prober` do not include the hostname.

### REGICIDE (T2 laptop)

- Same Tailscale/SSH/Xauthority notes as above; no server services.
- `/var/lib/firmware-src/REGICIDE` is the new staging dir (same note as
  MENTICIDE: leave it, or move it and re-run the importer).

## Tailnet URLs: what changes and how to keep them stable

The repository contains no real tailnet URL (only `<tailnet>` placeholders), so
nothing in Nix depends on the old MagicDNS names. The names matter only to
clients, bookmarks and your own config files.

**Unchanged by a hostname change:** the tailnet name (`<tailnet>.ts.net`), the
100.x / fd7a: addresses, the node key and login, ACLs written by user or tag,
every Cloudflare route (`*.cqjro.ca`, identified by tunnel UUID), and anything
that reaches a machine by its tailnet or LAN IP.

**Changes when the Tailscale node name changes:** the MagicDNS name
(`redrum.<tailnet>.ts.net` → `menticide.<tailnet>.ts.net`, `god-killer` →
`theocide`), the `tailscale serve` HTTPS URLs and their certificates, and any
ACL or grant that names a machine. The node name follows the OS hostname
unless it was renamed by hand in the admin console (Tailscale's behaviour,
not verified here: check the machine's name after the first switch).

Everything that stores the old name then has to be updated: T3 environments on
the desktop app and phone (add the new URL and re-pair; label rename is a T3
setting), `~/.config/agent-notify/server` and the ntfy phone subscription,
`~/.ssh/config`, bookmarks, and anything else typed with the old name. Re-run
the serve publishers after the switch to be safe: `sudo systemctl restart
t3code-tailscale-serve` on MENTICIDE, and your own `sudo tailscale serve --bg
--https=443 http://127.0.0.1:3773` (and the `:8443` ntfy one) where you
published by hand; check `tailscale serve status`.

**Decoupling the two renames.** The OS hostname and the Tailscale node name are
separate. Before switching a machine, rename it in the Tailscale admin console
to its *old* name (a manual name stops following the hostname). The switch then
changes nothing on the tailnet, and no URL moves. When you are ready, rename
the node in the admin console to the new name, which is the moment the URLs
change, and do the client updates above once. Agents never run `tailscale set`
(guard-blocked), so this is yours to do.

## Rollout order

1. Merge the PR. On a machine still called by its old name, `./rebuild.sh
   switch THEOCIDE` works (the shim); `sudo nixos-rebuild switch --flake
   .#THEOCIDE` from `~/.nixos` is the fallback.
2. THEOCIDE first (physically accessible), log out/in, verify
   `hostnamectl`, Tailscale, T3.
3. REGICIDE, then MENTICIDE last: `./rebuild.sh dry MENTICIDE` first, then
   `ssh redrum` → `./rebuild.sh switch MENTICIDE`. Keep a second terminal or
   the IP address ready, because the old SSH alias may stop resolving.
   Do not use the frozen `rebuild` zsh alias for the first switch (a store
   copy without the shim); use `./rebuild.sh` from the merged `~/.nixos`.
   For MENTICIDE connect with `ssh cairo@<tailnet or LAN IP>`, not the alias,
   and skip `test` there: use `dry`, then `switch`, with a second session open.
4. Fix the outside items above, then remove the shim in `rebuild.sh` and
   `schedule-precheck`.

## Risks, ranked

1. **Lock-out of MENTICIDE by name**: SSH alias, Tailscale MagicDNS name and T3
   URL all change at once. Mitigation: switch it last, know its tailnet IP
   (stable) or LAN IP, and use `--target cairo@<ip>`.
2. **Silent notification loss** (ntfy URL / `agent-notify` config) until updated.
3. **Stale T3 environment URLs** and labels (re-pair).
4. **GC of the firmware** if the staging dir is moved without re-running the
   importer.
5. **Old-name hostnames in scripts you keep outside the repo** (shell aliases,
   `~/.ssh/config`, bookmarks, Beszel/Homepage entries): grep your dotfiles.
6. Eval/build correctness: the rename is mechanical; `./rebuild.sh check` and
   `build` on THEOCIDE/MENTICIDE are the proof, and the closure should differ
   only in names (hostname, tmpfiles dir, generation label).
