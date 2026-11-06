# AGENTS.md

Shared guidance for any AI agent working on this repository (Claude Code reads
it through `CLAUDE.md`; other agents read it directly). The
[README.md](./README.md) is the human-oriented overview — keep the two in sync
(see [Documentation Maintenance](#documentation-maintenance)).

## Project at a glance

Personal NixOS flake (`flake-parts` + `import-tree`) that configures three
machines (`GOD-KILLER`, `LittleNix`, `REDRUM`) from a pool of small, self-contained
module fragments, all themed from one base16 palette via Stylix.

## How the agent docs are organised

This file loads into every thread, so it holds only what every task needs.
Read the others **when the task calls for them**:

| File | Read when |
| --- | --- |
| `AGENTS.md` (this file) | always — the single source of truth for every agent |
| `CLAUDE.md` | loaded by Claude Code; imports this file and adds Claude-only notes (subagents, skills, T3 tools). Never put shared rules there |
| [`docs/agents/workflow.md`](docs/agents/workflow.md) | branching, PRs, testing, merging, cross-machine handoff, generation tracking, model choice, the path to close and settling a thread |
| [`docs/agents/review.md`](docs/agents/review.md) | reviewing a branch (tiers 0–3) |
| [`docs/agents/module-recipes.md`](docs/agents/module-recipes.md) | creating a REDRUM server module, theming the ABT sidecar, archiving a module |
| [`docs/agents/security.md`](docs/agents/security.md) | permissions, sandbox, the `claude-guard` hook, the security smoke test, adding a hook |
| [`docs/agents/t3-claude.md`](docs/agents/t3-claude.md) | pushes, pairing, T3 on REDRUM |
| [`docs/agents/secrets.md`](docs/agents/secrets.md) | any task involving a secret, token, key, env file, `request_secret`, or the T2 firmware paths |
| [`docs/agents/upstream-registry.md`](docs/agents/upstream-registry.md) | any rebuild conversation, or adding/removing a workaround |
| [`docs/agents/notifications.md`](docs/agents/notifications.md) | adding or changing approval/completion notifications (`agent-notify`, ntfy) |
| [`docs/schedules/README.md`](docs/schedules/README.md) | scheduled threads: upstream/warning checks, the unswitched-changes notifier, worker briefs. Schedules never write to `~/.nixos` (private clone under `~/.local/state/nixos-schedules`) |
| [`docs/agents/gotchas.md`](docs/agents/gotchas.md) | the area you touch appears in the [Gotchas](#gotchas) index |

## Quick commands

```bash
./rebuild.sh check [HOST...]      # tier-0 checks: syntax, tracked secrets/firmware, whitespace, registry sync, eval
./rebuild.sh eval HOST            # evaluate only (drvPath); how REDRUM checks GOD-KILLER
./rebuild.sh build HOST           # unprivileged build + closure diff (agent-safe, no root, no commit)
./rebuild.sh test HOST            # activate without recording a generation (sudo via GUI askpass); reboot/revert undoes it
./rebuild.sh dry HOST             # dry-activate: what a switch would restart
./rebuild.sh revert               # re-activate the recorded generation after a test
./rebuild.sh switch HOST [-m MSG] # master only: commit a dirty tree with MSG, then switch (records a generation)
./rebuild.sh push                 # push the current branch (never forced; master only from a terminal)
./rebuild.sh generations          # generations with the commit/PR each was built from
./rebuild.sh                      # interactive: host -> diff -> build -> commit -> switch (master) / test (branch) -> push
config-sync                       # zsh alias -> modules/scripts/config-sync.sh (manual stash/pull/pop of ~/.nixos; rarely needed)
nix develop .#youtube-sync        # devshell for the youtube-sync helper
```

- All three hosts evaluate **purely**: the Apple T2 Wi-Fi/Bluetooth firmware
  for REDRUM and LittleNix comes from the Nix store
  (`modules/system/t2-firmware.nix`, `pkgs.requireFile` pinned by hash), so
  evaluation needs no files and no `--impure`; only a *build* of a T2 host needs
  the firmware imported into that machine's store: the human places it in
  `/var/lib/firmware-src/<HOST>/brcm` and runs `nix run .#t2-firmware-import --
  HOST` (`docs/firmware.md`). If a build reports the firmware missing, stop and
  tell the human which machine and host — do not work around it.
- `rebuild.sh` works on the checkout it lives in (worktree-safe). Always run
  `./rebuild.sh` from the checkout, never the `rebuild` zsh alias (a frozen
  store copy).
- No formatter/linter is enforced (alejandra is commented out in `rebuild.sh`).
  Match the existing style: **tab indentation**, Nix strings with double quotes,
  existing naming conventions.
- There are no automated tests; verification is `./rebuild.sh check` + a
  successful `./rebuild.sh build`.

## Repository structure

```
flake.nix          # inputs + flake-parts/import-tree scaffolding (the "dendritic" core)
rebuild.sh         # staged rebuild: check/eval/build/test/dry/switch/push/generations + interactive flow
start.sh           # login script: ssh-agent only (no auto-pull; switch fast-forwards master)
CLAUDE.md          # Claude Code entry point: @AGENTS.md + Claude-only notes
.claude/           # agents/ (reviewer subagents), skills/ (start-todo, ship-pr, merge-pr)
.github/           # pull_request_template.md
docs/agents/       # on-demand agent reference (see the table above)
modules/
  essentials/      # shared system services (networking, users, audio, nvidia, config-revision, …)
  hosts/           # host.nix (assembles nixosConfigurations) + one dir per machine
  home-manager/    # user config: ai-tools/, apps/, desktop/, keyboard/, languages/, terminal/
  scripts/         # helper shell/python scripts
  server/          # REDRUM services (actual-budget, linkwarden, tailscale, …)
  system/          # games, minecraft, waydroid, ios-sideloading, tether, vpn, manifest, rss-sources, t2-firmware, …
  theme/           # stylix scheme + openrgb + webstyling/ + discord-theme
  _archive/        # retired modules — prefer archiving here over deleting
```

Full documentation lives in the README (`Machines`, `Repository Layout`,
`Key Features`, etc.) — do not duplicate that detail here.

## The module pattern (how to add a feature)

Every `.nix` file under `modules/` is auto-imported by `import-tree`. A file
declares fragments under the flake-parts namespace:

```nix
{ inputs, ... }:
{
  flake.modules.nixos."my-feature" = { pkgs, ... }: { ... };       # NixOS side
  flake.modules.homeManager."my-feature" = { config, lib, ... }: { ... };  # user side
}
```

Hosts then opt in **explicitly**:

- System level: add `inputs.self.modules.nixos."my-feature"` to the host's module
  list in `modules/hosts/host.nix`.
- User level: add `input-name` (`my-feature`) to the `imports` list inside each
  host's `machine.nix` (`with inputs.self.modules.homeManager`).

Other conventions:

- Fragment names are exact strings and often contain hyphens — quote them
  (`inputs.self.modules.nixos."GOD-KILLER-hardware"`).
- Per-host overrides for a shared module are implemented as **module options**
  consumed elsewhere. Example: `hyprland.monitors` / `hyprland.bindel` are
  defined in `home-manager/desktop/hyprland.nix` and set per host in
  `hosts/<HOST>/home.nix` / `monitors.nix`.
- Feature toggles live in `system/manifest.nix`
  (`manifest.enableMillennium`, `manifest.enableSpicetify`) and gate
  `mkIf` blocks in consumer modules (see `home-manager/apps/spicetify.nix`).
- Shared **data** fragments also live NixOS-side and are consumed user-side via
  `osConfig`. Example: `rss-sources.feeds` (in `modules/system/rss-sources.nix`)
  feeds the glance rss widget through `config.rss-sources.feeds` and
  `nom` via `osConfig.rss-sources.feeds`. The list is data in
  `modules/system/rss-feeds.json` (read with `builtins.fromJSON`), not Nix
  source: `modules/scripts/rss-sync.py` (the `rss-sync` command, GOD-KILLER)
  edits it to mirror Miniflux, and `rss-feeds.synced.json` is its snapshot of
  URLs both sides agreed on — hand-edit the master list freely, but do not
  hand-edit or delete the snapshot (without it a deletion in Miniflux looks
  like a feed that was never pushed). The same module renders the list as OPML
  (`rss-sources.opml`, `/etc/rss-sources.opml`). The Miniflux API token lives in
  `~/.config/rss-sync/api-token` (`Read`-denied); agents run only
  `rss-sync status` and leave `push`/`pull --write`/`prune --yes` to the human.
- Theming is always derived from Stylix colors (`config.lib.stylix.colors.baseXX`)
  or `config.stylix.*` — never hardcode new colors in modules, extend the scheme
  in `modules/theme/stylix.nix` instead.
- Prefer **relative paths** over absolute ones (e.g. `${../../scripts/pip-move.sh}` in
  `home-manager/desktop/hyprland.nix`). The latest commits moved paths to relative.
- Star imports from the fragment's `{ pkgs, ... }` arguments rather than
  introducing deps at the top level, matching surrounding files.

**NUR packages removed.** All Nix User Repository (NUR) inputs, modules, and NUR-sourced packages have been removed from this configuration. NUR packages can be removed at any time and may require finding new sources or packaging them differently.

Recipes (read the one you need, in [`docs/agents/module-recipes.md`](docs/agents/module-recipes.md)):

- **Creating a server module (REDRUM)** — free `127.0.0.1` port, dedicated
  user, secrets under `/var/lib/<app>`, tunnel UUID committed (an identifier;
  the credentials JSON is the secret), README + Homepage updates.
- **Theming the Actual Budget Tweaks sidecar** — the base16 → ABT token map and
  the browser-shim seed.
- **Archiving a module** — never delete: move to `modules/_archive/` with a
  header, a "To reintegrate" block, detached references and commented-out
  flake inputs.

## Change workflow

GitHub (`cqjro/nixos`, `master`) is the hub between machines; full procedure in
[`docs/agents/workflow.md`](docs/agents/workflow.md).

- **One item, one branch, one PR.** Each TODO item gets its own T3 thread and
  worktree on `todo/<slug>` (`fix/`, `auto/`, `workflow/` for other work),
  based on `origin/master`. Never edit `master` or the main `~/.nixos`
  checkout directly; it stays clean for switching.
- **Verify, then review.** `./rebuild.sh check HOST...` and `./rebuild.sh
  build HOST` for each affected host this machine may build, then the review
  tiers ([`docs/agents/review.md`](docs/agents/review.md); the `ship-pr` skill
  runs them). Empty output with exit 0 from `build` is success.
- **Which machine builds what.** GOD-KILLER may build GOD-KILLER and REDRUM.
  REDRUM may build REDRUM only and runs **eval-only** checks
  (`./rebuild.sh eval GOD-KILLER`) for GOD-KILLER changes. Remote hosts are
  never switched or test-activated by agents (a remote activation needs a
  terminal for the sudo password).
- **Test without recording.** `./rebuild.sh test HOST` (local only,
  human-approved) activates a branch build without a generation; `./rebuild.sh
  revert` or a reboot undoes it. On REDRUM prefer `dry` for lockout-surface
  changes.
- **PRs.** Commit and push (`./rebuild.sh push`) only when asked; open the PR
  with `gh pr create` and `.github/pull_request_template.md`, then T3's
  `link_pull_request`. Squash-merge with `gh pr merge <N> --squash
  --delete-branch` only when the human asks — in Supervised or Accept edits
  approving the card is the approval; in Auto it is the human's explicit message
  ("merge N"). A scheduled worker never merges.
- **Generations.** Only merged `master` is switched (`switch` refuses other
  branches). Each generation records its commit via
  `system.configurationRevision` (`modules/essentials/config-revision.nix`) and
  a `git-<sha>` boot label; `./rebuild.sh generations` maps generation → commit
  → PR. There is no post-switch metadata commit; commit subjects are plain
  descriptions (squash merges add `(#N)`).
- **Model per task** follows the TODO.md effort score (Haiku for triage and
  tier-1 review, Sonnet for 1–6, Opus to plan 7–10) — table in
  [`docs/agents/workflow.md`](docs/agents/workflow.md#model-and-effort-per-task).

## Path to close (end of every reply)

Every thread should move toward being settled. End **every** reply to the
human with a `Path to close` block — format and settle checklist in
[`docs/agents/workflow.md`](docs/agents/workflow.md#path-to-close):

- One ordered list of the remaining steps, from both sides, each tagged
  **Agent** or **You**, in the order they unblock each other, ending with the
  step that closes the thread (e.g. "PR merged and REDRUM switched").
- Work handed to another thread or agent goes under **Delegated**, with a
  `t3-thread://` link or task id; it no longer blocks this thread.
- When no steps remain, or every remaining step is delegated, recommend
  settling (T3 *settle*, or *snooze* until a named event) instead of a list.
  Settle only when the human agrees.

## Using mcp-nixos

`modules/home-manager/ai-tools/mcp-servers.nix` provides mcp-nixos to Claude
Code as the `hm` plugin: tools `mcp__plugin_hm_nixos__nix` and
`mcp__plugin_hm_nixos__nix_versions` (allow-listed, no prompt). They are
**deferred**: load them first with `ToolSearch`
(`select:mcp__plugin_hm_nixos__nix,mcp__plugin_hm_nixos__nix_versions`) or the
call fails input validation. GOD-KILLER only for now (REDRUM's `t3code` user has
no home-manager).

- **Before using an option or package**, confirm it instead of guessing:
  `{"action":"info","query":"services.foo.enable","type":"option"}`,
  `{"action":"info","query":"<pkg>"}`, home-manager options with
  `"source":"home-manager"`.
- **REDRUM's pinned nixpkgs is not in the remote index** (it tracks unstable and
  stable only). Read the pinned source directly:
  `{"action":"flake-inputs","type":"ls","query":"nixpkgs-redrum:nixos/modules/services"}`,
  then `"type":"read"`. Same for stylix, home-manager or nixos-hardware
  behaviour at the locked rev.
- **Before a heavy build**, `{"action":"cache","query":"<pkg>"}` shows whether
  it substitutes from cache.nixos.org or builds from source — pick the machine
  accordingly (GOD-KILLER for source builds).
- **Version history / upstream registry checks**: `nix_versions` finds the
  nixpkgs commit that shipped a version (useful for the T2 pin and rows that
  wait on a nixpkgs fix).
- **Built output**: `{"action":"store","type":"read","query":"/nix/store/…"}`
  inspects generated configs/units under `./result`.
- Limits: it cannot evaluate this flake — use `./rebuild.sh eval` for that; it
  ignores `version`/`system` outside `cache`.

## Agent safety essentials

Permissions, sandbox and the `claude-guard` hook are one managed policy for both
hosts (`flake.modules.nixos."claude-code-policy"` in
`modules/home-manager/ai-tools/claude-code.nix`, installed as
`/etc/claude-code/managed-settings.json`); details, the mode table and the
smoke test in [`docs/agents/security.md`](docs/agents/security.md). Pushes,
pairing and T3 on REDRUM: [`docs/agents/t3-claude.md`](docs/agents/t3-claude.md).

- TODO/worktree threads and scheduled workers run **Auto** (default since
  2026-11-05); policy, secrets or networking work runs **Supervised**. In Auto a
  classifier, not a person, answers `ask` rules (a model judgment, not a lock;
  `master` relies on branch protection). Full access refuses every `ask` rule, so
  avoid it. Details: [security.md](docs/agents/security.md#t3-runtime-modes).
- Secrets (`~/.ssh`, `~/.config/gh`, `~/.t3/userdata/secrets`, `*.env`,
  `token.json`, `client_secret.json`) are never read, printed or committed;
  the T2 firmware is never committed, read, printed or attached (`docs/firmware.md`).
  Never ask the human to paste a secret in chat, and never accept one: a secret a
  T3 tool needs goes through `request_secret`; one the repo or a service needs is
  pointed at a runtime path, with the human creating the file
  ([`docs/agents/secrets.md`](docs/agents/secrets.md)).
- Allowed without a prompt: `git add`/`commit` on a branch, `gh pr create`,
  `gh issue create`, `./rebuild.sh check|eval|build|generations`, `nix
  eval|build`. Human-approved: `switch`, `test`, `dry`, `revert`, `push`,
  `git push`, commits on `master`, `gh pr merge|comment|update-branch`, `gh api`
  and `sudo`. No passwordless sudo for `nixos-rebuild`; never run
  `tailscale serve`/`set` (the guard blocks it).
- Hooks only run from the managed policy (`allowManagedHooksOnly`): a new hook
  is a NixOS fragment setting `claude-code-policy.hooks.<Event>`
  ([security.md](docs/agents/security.md#adding-hooks-merge-point)), never
  home-manager `programs.claude-code.settings.hooks`, a project
  `.claude/settings.json` or a skill: those are silently ignored.
- Pushes go over HTTPS through the `gh` credential helper (no SSH agent in T3
  threads).
- Bash runs in a sandbox that hides `/home` outside the worktree; reads outside
  the project prompt (`blockReadsOutsideWorkingDirectories`). A "blocked …
  `/add-dir`" result means re-issue the call after the human grants access.
  The agent cannot see the approval UI.

## Pending upstream fixes

Workarounds that exist **only** because of a bug or gap upstream live in the
registry at [`docs/agents/upstream-registry.md`](docs/agents/upstream-registry.md)
(mirrored in the README's table). They are deliberate, temporary reductions in
scope — never "clean one up" without confirming the upstream fix.

**Rule: stay on the latest nixpkgs and pin the broken app, not the system.**
When a bump to the latest `nixos-unstable` breaks one package, do not hold
`nixpkgs` back. Remove the dead usage if it is unused; otherwise take that one
package from the last known-good rev through its own pinned input (e.g.
`inputs.nixpkgs-opencode`), and register it as a workaround (`# TODO-remove:`,
a row in both tables, a probe entry) so the weekly check unpins it once
upstream is fixed.

**Standing instruction: in every rebuild conversation, read the registry and
re-check each entry for an upstream fix before doing anything else** (look at
the linked issue/PR or upstream commit log; do not assume from elapsed time).
Report landed fixes explicitly and remove the workaround in its own branch;
otherwise report status briefly and move on. Adding a workaround requires a
`# TODO-remove:` comment at the site, the same row in both tables and an entry
in `docs/schedules/upstream-probes.json` (`./rebuild.sh check` compares the row
numbers; without the probe entry the weekly schedule stops on a mismatch).

## Gotchas

One line each; the detail is in [`docs/agents/gotchas.md`](docs/agents/gotchas.md).
Read the matching entry before touching that area.

- **Waydroid** — userdata is `~/.local/share/waydroid`; black screen on
  GOD-KILLER while the display is on NVIDIA; software rendering on NVIDIA is
  not viable.
- **Xodus Nexus** — pinned AppImage; backend self-installs; needs the `keyring`
  fragments.
- **Secrets and firmware are gitignored** and must never be committed; the T2
  firmware is proprietary, lives outside the repo and is never read or attached.
- **YouTube playlist sync** is quota-bound (RSS first, hourly timer).
- **REDRUM is built from pinned nixpkgs** (`cac0c1ef`); security-relevant
  packages (cloudflared, tailscale, t3code) are overridden explicitly.
- **Do not add `nix flake check` to `rebuild.sh`.**
- **The `rebuild` zsh alias is a frozen store copy** — use `./rebuild.sh`.
- **Flakes only see tracked files** — `rebuild.sh` stages with `git add --all`.
- **`system.stateVersion` differs per host** — leave it alone.
- **`stylix.enableReleaseChecks = false`** in every host `home.nix`.
- **REDRUM does not import `essentials/users.nix`** — mirror user changes in
  `hosts/REDRUM/machine.nix`; do not import the shared module there.
- **pnpm `packageManager` pins** and **non-reproducible pnpm FOD hashes** in
  `actual-budget-tweaks.nix` / `reactflux.nix`.
- **`rebuild.sh` output is in `.log/` when piped; `gh` and `git push` must be
  plain commands** (chained or piped, they run sandboxed and fail to
  authenticate); sandbox `/dev/null` placeholders in `git status` (use
  `--no-track`, stage by path); `gh auth status` needs `[allow-secret-pattern]`
  to paste.

## Documentation Maintenance

These files describe the repo and all agents rely on them for context. Keep
them accurate:

- **Update `README.md`** when: adding/removing a host, changing the module layout
  or pattern, adding a notable feature/theme, or changing the install/rebuild
  workflow.
- **Update `AGENTS.md`** when: conventions change (fragment naming, options,
  paths), the quick commands become stale, or the workflow changes. Keep it
  short — long reference material goes in `docs/agents/`, with a pointer here.
  New gotchas go in `docs/agents/gotchas.md` plus a one-line index entry above.
- **`CLAUDE.md`** holds only Claude-specific notes; anything every agent needs
  belongs in `AGENTS.md`.
- When you make a change that affects any of these, update the documentation
  **in the same change**. README = human overview, AGENTS.md + `docs/agents/`
  = agent operational guidance.
- **`TODO.md`** is the wishlist of planned config updates (see the README's
  "Planned Updates" section). When you implement an item from it, **remove
  the item (and its sub-items) from `TODO.md` in the same change** — do not
  check it off, do not leave it behind "for reference".
