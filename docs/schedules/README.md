# Scheduled threads

How the recurring T3 Code threads for this repo work, what they cost, and how a
finding turns into an issue, a branch, and a PR. Nothing here is live until the
prompts are approved (see [Rollout](#rollout)): the two scheduled tasks that
exist today still run their original prompts.

| File | What it is |
| --- | --- |
| [`upstream-check.md`](./upstream-check.md) | Prompt + `schedule_task` JSON: "Upstream Issues Check" (registry polling) |
| [`build-flags.md`](./build-flags.md) | Prompt + `schedule_task` JSON: "Build Flags" (eval warnings and failures) |
| [`worker-briefs.md`](./worker-briefs.md) | The `t3_thread_launch` calls and briefs for the PR-opening worker threads |
| [`bin/schedule-precheck`](./bin/schedule-precheck) | The deterministic pre-step (no LLM): probes, state, issue bookkeeping |
| [`upstream-probes.json`](./upstream-probes.json) | Structured mirror of the "Pending upstream fixes" registry + known-noise ignore list |

## The shape of a run

```
T3 scheduler (fixed_time, fresh thread per run)
  └─ cheap dispatcher prompt
       1. schedule-precheck <upstream|buildflags>           ← deterministic, no LLM
            • polls GitHub / evaluates origin/master in a throw-away worktree
            • files or updates ONE GitHub issue per finding (labelled, deduped)
            • prints a JSON report: changed? actionable?
       2. changed = false  → one line, stop                  ← the common case
       3. changed = true   → short summary of the report
       4. actionable ≠ []  → t3_thread_launch ONE worker (worktree, auto/<slug>, from origin/master)
            └─ worker: verify → edit → build → gh pr create "Fixes #N" → watch the PR
                 └─ human reviews, squash-merges, then switches the host
```

Why this shape:

- **Quota.** A weekly dispatcher turn is small; the only fixed cost is the
  project instructions (`AGENTS.md`) that every thread loads, which thread 1 is
  slimming. The expensive work (research, edits, builds) happens only in a
  worker, only for a finding that survived the script, on a model chosen for it.
- **Dedupe lives in GitHub, not in the model.** The script finds an existing
  issue by a hidden marker (`<!-- sched-key: … -->`) and never trusts the
  model's memory.
- **Untrusted text stays out.** Issue bodies are built only from fields the
  script collected (state, counts, blob SHAs, normalised warning text). Upstream
  issue titles/comments are never copied into issues or worker briefs, so an
  upstream comment cannot instruct the agent. Workers are told to re-read the
  upstream source themselves.
- **No schedule ever touches `master` or the main checkout.** The old "Build
  Flags" edited the root checkout. The new one evaluates a detached worktree of
  `origin/master` that the script creates and removes, and fixes go through a
  worker's `auto/…` branch and a PR.

## The pre-step script

`bin/schedule-precheck` (Python 3, stdlib only; needs `gh`, `git`, `nix`).

```
schedule-precheck upstream   [--skip-nix] [--detect-only] [--max-new N] [--dry-run]
schedule-precheck buildflags [--tree master|working] [--host H]… [--detect-only] [--max-new N] [--dry-run]
schedule-precheck mark-launched KEY THREAD_ID
schedule-precheck health SCHEDULE MESSAGE…
```

- **`upstream`** reads `upstream-probes.json` (one entry per registry row) and
  runs each probe: `issue` (state/comments/updatedAt via `gh issue view`),
  `file` (blob SHA, plus `mustContain`/`mustNotContain` against the raw file),
  `tree-match`, `path-exists`, `nix-dry-build` (is `nixos-unstable#mcp-nixos`
  substitutable from the cache?). A probe returns a *fix signal*, never proof.
  Statuses: `baseline` (first sight), `blocked` (unchanged), `changed`,
  `fix-candidate`, `error`. It warns when the row numbers in the registry table
  (found in `docs/agents/upstream-registry.md`, then `README.md`) and the probe file
  disagree. `./rebuild.sh check` already compares the registry with the README mirror;
  this is the equivalent check for the probe file.
- **`buildflags`** fetches `origin/master`, adds a detached worktree, runs
  `nix eval --impure --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
  for every `modules/hosts/*` directory, and parses stderr into
  `evaluation warning` / `warning` / `trace` / `error` blocks (multi-line
  warnings are joined). Messages are normalised (store hashes, line numbers,
  whitespace) and hashed into a stable key, so the same warning on three hosts
  is one finding. Evaluating `origin/master` instead of the checkout means a
  half-edited tree can never produce a false report, and only merged work is
  judged. `ignore` entries in the probe file silence known noise with a reason.
- **State** is `$NIXOS_SCHEDULE_STATE`, default `<repo>/.log/schedules/`
  (gitignored through `*.log`): `upstream-state.json`, `buildflags-state.json`,
  `heartbeat.json`. Losing it is harmless (the next run re-baselines; issues are
  the durable record).
- **`--detect-only`** files and updates issues but reports nothing actionable.
  For a host that must not launch workers (see [Placement](#placement)).
- **Safety of running it.** One allow rule (`Bash(docs/schedules/bin/schedule-precheck *)`)
  covers every `gh` and `nix` call inside it, so an unattended run needs no
  `gh issue *` rules. That is only as safe as the script itself, which the agent
  can edit like `rebuild.sh`; review diffs to it.

### Verified vs untested

Run on GOD-KILLER on 2026-11-01 in this worktree: all `upstream` probes against
live GitHub (`--dry-run`), `buildflags` on all three hosts at `origin/master`
(15 s / 11 s / 7 s eval; the temporary worktree is removed afterwards), warning
parsing against real multi-line warnings, the `--detect-only`/`--max-new`/`--skip-nix`
paths, and the `health` verb in dry-run. **Not run: any real issue write**
(`gh issue create/comment/close`, `gh label create`, `mark-launched`). Those are
outward-facing on a private repo and I did not do them without approval; the first
real run should be watched. Also untested: the shebang
(`nix shell nixpkgs#python3`) from inside a T3 scheduled thread's environment,
and every `t3_thread_launch` call below.

## Dedupe model

| Rule | Detail |
| --- | --- |
| One issue per finding | Key `upstream-fix:row-N`, `rebuild-warning:<hash>`, `eval-failure:<host>:<hash>`; stored as a hidden marker in the body. |
| Labels | `scheduled` (all), plus `upstream-fix`, `rebuild-warning`, `eval-failure`, `worker-launched`, `schedule-health`. The script creates missing labels. |
| Updated in place | A changed probe on an open issue becomes a comment, once per fingerprint. A finding that stops reproducing is closed with a comment. |
| Never reopened | A closed issue is a human's final answer: the schedule reports it as `suppressed` and does nothing. Reopen it yourself to make it live again. |
| Cap on new issues | `--max-new 3` per run. Eval failures are exempt (they are rare and important). Warnings over the cap go to one `rebuild-warning:digest` issue, and are promoted to their own issue on later runs, three at a time. |
| One worker per run | The dispatcher launches at most one worker; it handles up to three of the listed issues in one PR. The `worker-launched` label stops the next run launching a duplicate. |
| First run | The first `buildflags` run files a backlog (seven distinct warnings today across the three hosts: three issues plus a digest). Run it with `--dry-run` first if you want to see it. |

## Placement

Each T3 server has its own scheduler, and a scheduled task runs on the server
that owns it. `schedule_task` called from a GOD-KILLER thread creates a
GOD-KILLER task. REDRUM tasks must be created from a client connected to
REDRUM's server.

| Schedule | Now | Target | Why |
| --- | --- | --- | --- |
| Upstream Issues Check | GOD-KILLER | REDRUM, `--detect-only` | Only needs `gh` and a read-only checkout; REDRUM is always on, GOD-KILLER often is not. |
| Build Flags | GOD-KILLER | REDRUM, `--detect-only` | Nix evaluation does not depend on the machine, so REDRUM can evaluate all three hosts (REDRUM 7 s, GOD-KILLER 15 s). It is eval only, never a GOD-KILLER build. |
| Worker launches | GOD-KILLER | GOD-KILLER | Workers need builds for GOD-KILLER modules, which REDRUM must not do. The same prompts run on GOD-KILLER without `--detect-only` and pick up whatever REDRUM filed, because `actionable` is computed from live issue state, not local state. |

REDRUM prerequisites before moving detection there (none exist yet): a repo
checkout readable by the `t3code` user (thread 4 / REDRUM docs), `gh` login for
that user with a fine-grained token limited to `cqjro/nixos` (issues + PRs,
thread 5), `nix` flakes enabled, and the firmware module (thread 2) so LittleNix
and REDRUM evaluate without the absolute `/home/cairo` path. Until then, keep
both on GOD-KILLER.

A missed run (GOD-KILLER off at Saturday noon): whether T3's scheduler catches
up on boot is **unknown and untested**. Observe it: leave GOD-KILLER off over
one scheduled time and see whether a thread appears at next start. The design
copes either way, since each run is idempotent and `daysSinceLastSuccess` shows
the gap, but the only real fix for "never fires" is moving detection to REDRUM.

## Model and effort

`schedule_task` and `update_scheduled_task` have **no model or effort field**.
A task inherits the creating thread's provider/model/runtime settings or the
project default (stated in the tool description; I could not find another
setting). So the plan is:

| Run | Wanted | How |
| --- | --- | --- |
| Dispatcher (scheduled thread) | Haiku, low (docs/agents/workflow.md: "Triage, scheduled checks") | Not settable by tool. Check whether T3's scheduled-task editor has a model picker (**please look**); otherwise it runs on the project default, which is fine because the dispatcher does almost nothing. |
| Worker, upstream removal | Sonnet 5.5, medium (effort 1–3 row) | Set explicitly in `t3_thread_launch.modelSelection`. Mechanical removal, effort score 1–3. |
| Worker, warning/eval fix | Sonnet 5.5, medium; high if the dispatcher marks it non-trivial | Same. Escalate to Opus 5.5 only after two failed rounds, per thread 1's tiers. |
| Row 1 (REDRUM kernel pin) | none | `notify-only`: needs kernel testing and a human-run REDRUM switch. |

The `options` shape inside `modelSelection` is **unverified**; the capability
catalog lists the option as `{id: "effort"}`. If a launch rejects it, omit
`options` and set effort in the UI.

## Webhook triggers

Not worth it now. Cadence is weekly, so a poll costs one small turn a week.
A webhook would need T3 Connect (a public tunnel), a signed secret via
`request_secret`, and it makes the agent launchable by anyone holding the URL.
The upstream repos are third-party, so we cannot attach GitHub webhooks to them
anyway; only our own repo could, and nothing there needs an instant reaction.
Revisit if the cadence goes to daily or more, in which case a systemd timer on
REDRUM running `schedule-precheck` and calling the webhook only when `changed`
is true would cut the LLM floor to zero.

## Idle and failed runs

- **Nothing changed:** `changed: false` → the prompt prints one line and stops.
- **Script failed** (exit 3, or `errors` non-empty): the prompt runs
  `schedule-precheck health <schedule> "<last lines>"` once and stops. That files
  at most one `schedule-health` issue per schedule per month and comments on
  repeats. It does not diagnose.
- **A tool call is blocked or denied:** the prompt says stop immediately and
  list the blocked command. Never retry variants: unattended threads cannot answer
  approval cards, and probing around a deny rule is exactly what we do not want.
- **Stale:** the report carries `daysSinceLastSuccess`; the prompt mentions it
  when above 14.
- **Worker already running:** the `worker-launched` label (set by `mark-launched`)
  and a `t3_thread_list` check on the branch name prevent a second launch.
- **One failed probe** does not stop the others; it is recorded as `error` with
  the message.

## MCP tools

- **mcp-nixos** (`nix`, `nix_versions`): used by workers, not by the dispatcher.
  `info` on a package in a channel, `nix_versions` to find which nixpkgs commit
  carried a fix, `flake-inputs` to read the *locked* nixpkgs source, and `cache`
  to confirm a package is substituted. A fix that exists in `nixos-unstable` but
  not in the locked revision needs a `flake.lock` bump, which is a human
  decision (REDRUM pins; T3 client/server versions must match), so a worker
  stops and comments instead of bumping.
- **T3 tools:** `t3_thread_launch` (worker, worktree, model), `t3_thread_list`
  (in-flight check), `link_pull_request` + `watch_pull_request` (worker links and
  watches its PR so T3 wakes it on checks), `list_scheduled_tasks` /
  `run_scheduled_task_now` (a smoke test after changing a prompt).
- **GitHub:** no GitHub MCP is installed; `gh` covers it, and putting it in the
  script means the model needs none.

## Findings from the first dry run (2026-11-01)

These are the real results of the new tooling against the live world, and they
are why the design is worth having:

- **Row 7 looks fixed upstream.** `nix build --dry-run github:NixOS/nixpkgs/nixos-unstable#mcp-nixos`
  reports only fetches (nothing to build): `pkgs.mcp-nixos` is now 3.0.2 and
  substitutable. The flake lock pins an older nixpkgs (`3ec6363`), so removal
  also needs to be checked against the locked revision.
- **Row 2 is partly fixed.** nixos-unstable's `qidi-studio` now has `libsoup_3`
  in `extraPkgs` (package version 2.07.02.73) but not `libpng`, `glib-networking`
  or a CA path, so the override stays; the probe records which pieces landed.
- **Rows 1, 3, 4, 5, 6** are unchanged (nixos-hardware#2027 open, last update
  2026-10-08; QIDIStudio#244 open; the nixdatifier lines still present; no
  `xodus*` in `pkgs/by-name/xo`; no `flake.nix` in `xodus-nexus`).
- **Seven distinct evaluation warnings** exist today (texlive.combine, renamed
  `programs.noctalia-greeter`, nixcord, `programs.rofi.font`, opencode `tui`,
  two avahi options) plus `pnpm: Override nodejs-slim` on REDRUM. LittleNix fails
  to evaluate (missing firmware path), which is ignored with a reason until
  thread 2 merges.
- **Stale cross-references:** `3d-printing.nix` and `nixdatifier.nix` cited the wrong
  registry rows; the workflow branch already fixes them (`917d021`).

## Rollout

1. Merge the workflow/docs PR first (workers use `./rebuild.sh check|build` and the
   `ship-pr` skill), then this one (the prompts call `docs/schedules/bin/schedule-precheck`,
   which must exist in the checkout the scheduled runs use).
2. Approve (or edit) the prompts in `upstream-check.md` and `build-flags.md`.
3. Thread 4 allows `Bash(docs/schedules/bin/schedule-precheck *)`, so an unattended
   run does not stall on a prompt (see Handoffs).
4. Smoke test: `update_scheduled_task` the two existing tasks, then
   `run_scheduled_task_now` once each with `--dry-run` appended to the script call
   (edit the prompt temporarily), and read the thread.
5. Remove `--dry-run`, run once for real, and watch the issues appear.
6. When the REDRUM prerequisites exist, create the `--detect-only` copies on
   REDRUM's server and keep the GOD-KILLER tasks as they are: they launch the
   workers for whatever REDRUM filed.

The currently-live "Build Flags" task fires today at 17:00Z with its old prompt
and will edit the root checkout if the tree is clean. If you would rather it did
not, `update_scheduled_task enabled=false` before then.

## Handoffs to other threads

**Workflow thread (`workflow/pr-rebuild-docs`).** Its handoff is applied here: `auto/<slug>`
branches from `origin/master`, `./rebuild.sh check|eval|build` and the `ship-pr` skill in the
worker briefs, Haiku low for scheduled checks, and the registry at
`docs/agents/upstream-registry.md`. What is left for it:

- The AGENTS.md standing instruction ("in every rebuild conversation, re-check each entry")
  should become a read of the open `upstream-fix` issues once the schedule is live; the
  replacement wording is in `upstream-check.md`. Not before, or nothing polls the registry.
- The registry now exists in three places: `docs/agents/upstream-registry.md`, the README
  mirror (`./rebuild.sh check` compares those two) and `upstream-probes.json`
  (`schedule-precheck` warns when its row numbers differ). Consider extending the check, or
  generating the probe file's row list from the registry. A worker that removes a row deletes
  it from all three.
- Packaging: `schedule-precheck` borrows `python3` through `nix shell` because agent shells
  have none. Ship it properly (home-manager package or `writers.writePython3Bin` with
  `gh git nix` as runtime inputs) next to the other scripts in `modules/scripts/`, and add it
  to the REDRUM `t3code` user's tools.
- `TODO.md` items "Upstream-fixes watchdog" and "Rebuild warnings catcher" are implemented
  by this work. Remove them once the schedules are verified live (the repo rule is to remove
  an item when it is implemented; removing them earlier would hide that nothing runs yet).
  The watchdog item's registry pointer is already updated on this branch.

**Thread 4 (permissions):**

- Allow `Bash(docs/schedules/bin/schedule-precheck *)` (or its packaged name) in
  both the user and the REDRUM managed policy. Without it an unattended run
  stalls on a card. No `gh issue *` allow is needed.
- Scheduled and worker threads must not run `full-access`. Decide whether workers
  launch `approval-required` (they then wait for you on each build) or
  `auto-accept-edits`.
- `gh pr create` and `git push` stay `ask`; the worker's PR step will wait for you
  by design.

**Thread 5 (secrets):** a fine-grained token for `gh` on REDRUM scoped to
`cqjro/nixos` with `issues: write`, `pull_requests: write`, `contents: write`.
The schedules need nothing else.

**Thread 6 (notifications):** the dispatcher ends with a one-paragraph summary and
the worker waits on a PR approval, so "thread finished" and "approval needed"
notifications are the right wake signals; no schedule-specific hook is needed.

**Thread 2 (firmware):** when the firmware module merges, delete the LittleNix
entry in `upstream-probes.json`'s `ignore` list.
