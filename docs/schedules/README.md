# Scheduled threads

How the recurring T3 Code threads for this repo work, what they cost, and how a
finding turns into an issue, a branch, and a PR. Nothing here is live until the
prompts are approved (see [Rollout](#rollout)): the two scheduled tasks that
exist today still run their original prompts.

| File | What it is |
| --- | --- |
| [`upstream-check.md`](./upstream-check.md) | Prompt + `schedule_task` JSON: "Upstream Issues Check" (registry polling) |
| [`build-flags.md`](./build-flags.md) | Prompt + `schedule_task` JSON: "Build Flags" (eval warnings and failures) |
| [`unswitched-changes.md`](./unswitched-changes.md) | Prompt + `schedule_task` JSON + REDRUM steps: per-host "merged but not switched yet" notifier |
| [`worker-briefs.md`](./worker-briefs.md) | The `t3_thread_launch` calls and briefs for the PR-opening worker threads |
| [`bin/schedule-precheck`](./bin/schedule-precheck) | The deterministic pre-step (no LLM): probes, state, issue bookkeeping |
| [`host-scopes.json`](./host-scopes.json) | Path → hosts rules the unswitched check uses |
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
schedule-precheck buildflags [--host H]… [--detect-only] [--max-new N] [--dry-run]
schedule-precheck unswitched [--host H] [--notify] [--remind-hours N] [--dry-run]
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
- **`buildflags`** fetches `origin/master` into the private clone, adds a detached worktree there, runs
  `nix eval --impure --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
  for every `modules/hosts/*` directory, and parses stderr into
  `evaluation warning` / `warning` / `trace` / `error` blocks (multi-line
  warnings are joined). Messages are normalised (store hashes, line numbers,
  whitespace) and hashed into a stable key, so the same warning on three hosts
  is one finding. Evaluating `origin/master` instead of the checkout means a
  half-edited tree can never produce a false report, and only merged work is
  judged. `ignore` entries in the probe file silence known noise with a reason.
- **`unswitched`** answers "has this host switched to everything merged on master?"
  See [`unswitched-changes.md`](./unswitched-changes.md).
- **Nothing here writes to `~/.nixos`.** The human's switch checkout is never fetched,
  pulled, worktree'd or logged into by a schedule (user rule: cross-machine awareness
  is a notification, never a pull). All git work happens in a private partial clone,
  `~/.local/state/nixos-schedules/clone` (a few MB, under the passwd home, not `$HOME`),
  made and fetched by the script from the constant URL `https://github.com/cqjro/nixos.git`
  (it does not read `~/.nixos/.git/config`, which the sandbox lets agents write).
  `--state-dir`, `--tree-path`, `--remote-url` and `--repo` exist for debugging and are
  **refused** unless you create `~/.config/nixos-schedules/allow-overrides`, because this
  script runs outside the sandbox and an agent chooses its arguments (docs/agents/security.md).
  `$NIXOS_SCHEDULE_STATE`/`$XDG_STATE_HOME` are ignored. Throw-away worktrees are created inside
  that clone's state directory and removed afterwards. (My first version wrote a
  worktree entry and a `.log/` state file into `~/.nixos`; this fixes that.)
- **State** is the same directory: `upstream-state.json`, `buildflags-state.json`,
  `unswitched-<HOST>.json`, `heartbeat.json`. Losing it is harmless (the next run
  re-baselines; issues are the durable record).
- **`--detect-only`** files and updates issues but reports nothing actionable.
  For a host that must not launch workers (see [Placement](#placement)).
- **What it runs.** `buildflags` runs `nix eval --impure` on `origin/master` with the
  caller's environment, i.e. it executes merged repo code at evaluation time; fine for a
  self-authored repo, which is also why only merged `master` is evaluated, never a PR branch.
  The shebang borrows `python3` from the flake registry's `nixpkgs` (unpinned, needs the
  registry or network); the packaged unit in `unswitched-changes.md` option A avoids that.
- **Sandbox and permissions.** The script cannot run in the agent sandbox (it runs `gh`,
  `git` and `nix`, whose sockets and `~/.config/gh` the sandbox hides). Found 2026-11-04
  when the live "Unswitched changes" task failed with `cannot create Unix domain socket`.
  `modules/home-manager/ai-tools/claude-code.nix` now excludes and allow-lists the
  **absolute path** `/home/cairo/.nixos/docs/schedules/bin/schedule-precheck *` (and
  `claude-guard` blocks Edit/Write on it), so one allow rule covers every `gh` and `nix`
  call inside it and an unattended run needs no `gh issue *` rules. Rules for prompts:
  - **one plain command**, absolute path: exclusion applies to plain commands only, so
    `cd … && …`, a pipe or `; echo $?` runs sandboxed and fails, and `claude-guard` blocks
    any command naming the script path that is not a single plain command. A `health`
    message therefore must not contain `"`, `$`, a backtick or a backslash;
  - **never the relative path from a worktree**: that copy is code the agent can edit and
    run in the same turn, so it is deliberately not excluded (smoke test steps 27-32).
  The script is only as safe as its checkout: `~/.nixos` changes by merged PR plus your
  switch, and `docs/schedules/bin/*` is on the tier-2 review list for that reason. Full
  reasoning, REDRUM and the packaged alternative: docs/agents/security.md, "Scheduled
  checks run unsandboxed".

### Verified vs untested

Run on GOD-KILLER on 2026-11-01/02 in this worktree (the clone-based version, `unswitched`
statuses and the reminder state machine included): all `upstream` probes against
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

## GitHub permissions

The issue-based design needs the `gh` token on the machine that runs the schedules to have
**Issues: read and write** on `cqjro/nixos`, on top of Contents and Pull requests. The script
(`schedule-precheck`) lists issues, creates and comments on and closes them, edits labels on
them (`worker-launched`) and creates labels. Probes of other repositories (nixpkgs,
nixos-hardware, QIDIStudio, nixdatifier, xodus-nexus, learnharness) only read public data.

**Granted 2026-11-04:** the GOD-KILLER token has Issues read and write on `cqjro/nixos`, and
the REDRUM `t3code` token (only `cqjro/nixos`, Contents + Pull requests + Issues, expires
2027-02-02) is installed. The issue-based design is therefore the decision; the paragraph
below is kept only as the road not taken. Not re-tested with the new permission yet: the
first real run is the Rollout smoke test.

Before the grant, the script degraded instead of failing, and still does if a token ever
lacks the permission: probes and evaluation still run, nothing is filed, the report carries
a `warnings` entry saying so, new findings are reported with `issueSkipped: true`, and no
worker is `actionable` (a worker needs an issue to point at). The `unswitched` check does
not use issues. Testing that degraded mode against the real repo **created the six labels**
(`scheduled`, `upstream-fix`, `rebuild-warning`, `eval-failure`, `worker-launched`,
`schedule-health`) in `cqjro/nixos`; no issue was created. They are what the script would
create anyway.

*Had the owner chosen PR comments instead*, these files would have changed and nothing else:
`docs/schedules/bin/schedule-precheck` (the `Issues` class and `LABELS`, `cmd_mark_launched`,
`cmd_health`: `gh issue *` becomes `gh pr list/comment` against one standing draft PR on a
dedicated branch such as `auto/schedule-findings`, with the same `<!-- sched-key -->` marker
per comment; "close" becomes a "resolved" comment because comments have no state or labels,
so `worker-launched` moves into the marker), `upstream-check.md` and `build-flags.md` (the
prompts say "issue"), `worker-briefs.md` (`gh issue view/comment`, `Fixes #N` become the PR
comment and a link in the PR body), this README (dedupe table, label list, the token line for
the secrets lane), and the owner item in `TODO.md`. The cost: no auto-close on merge, and a
standing PR must carry at least one commit.

## Placement

Each T3 server has its own scheduler, and a scheduled task runs on the server
that owns it. `schedule_task` called from a GOD-KILLER thread creates a
GOD-KILLER task. REDRUM tasks must be created from a client connected to
REDRUM's server.

| Schedule | Now | Target | Why |
| --- | --- | --- | --- |
| Upstream Issues Check | GOD-KILLER | REDRUM, `--detect-only` | Only needs `gh` and a read-only checkout; REDRUM is always on, GOD-KILLER often is not. |
| Build Flags | GOD-KILLER | REDRUM, `--detect-only` | Nix evaluation does not depend on the machine, so REDRUM can evaluate all three hosts (REDRUM 7 s, GOD-KILLER 15 s). It is eval only, never a GOD-KILLER build. |
| Unswitched changes | none | every machine (own copy per T3 server, or a timer) | It must run on the host it is about; see `unswitched-changes.md`. |
| Worker launches | GOD-KILLER | GOD-KILLER | Workers need builds for GOD-KILLER modules, which REDRUM must not do. The same prompts run on GOD-KILLER without `--detect-only` and pick up whatever REDRUM filed, because `actionable` is computed from live issue state, not local state. |

REDRUM prerequisites before moving detection there (none exist yet): a repo
checkout readable by the `t3code` user (thread 4 / REDRUM docs), `gh` login for
that user with a fine-grained token limited to `cqjro/nixos` (issues + PRs,
thread 5), and `nix` flakes enabled (the firmware module is merged, so evaluation no longer needs
the absolute `/home/cairo` path). Until then, keep both on GOD-KILLER.

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

`modelSelection.options` as `{"effort": "low"}` was accepted by `t3_thread_launch`
(verified 2026-11-02). A task created *from* a thread inherits that thread's model, so a
Haiku-low scheduled task is made by launching a Haiku-low thread and having it call
`schedule_task` (how "Unswitched changes" was created).

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
  two avahi options) plus `pnpm: Override nodejs-slim` on REDRUM. LittleNix failed
  to evaluate on 2026-11-01 (missing firmware path); after the firmware PR merged it evaluates
  OK and the ignore entry was removed.
- **Stale cross-references:** `3d-printing.nix` and `nixdatifier.nix` cited the wrong
  registry rows; the workflow branch already fixes them.

## Rollout

1. (Done) the workflow, firmware, security, secrets, notifications and schedules PRs are
   merged and both hosts switched. The script exists in `~/.nixos`.
2. Merge the sandbox-policy PR (`workflow/schedule-sandbox`: exclusion + allow rule +
   guard rule + these prompts) and **switch GOD-KILLER** (`./rebuild.sh switch` fast-forwards
   `master` itself; nothing pulls automatically).
3. Approve the prompts in `upstream-check.md` and `build-flags.md` and update the two
   existing tasks (`update_scheduled_task`, ids in each file).
4. Smoke test, in this order, reading each thread: `run_scheduled_task_now` once per task
   with `--dry-run` appended to the script call in the prompt (edit it temporarily), then
   smoke-test steps 25-32 in docs/agents/security.md.
5. Remove `--dry-run`, run once for real, and watch the issues appear.
6. When the REDRUM prerequisites exist, create the `--detect-only` copies on
   REDRUM's server (and see the REDRUM note in docs/agents/security.md: it needs the
   packaged script, not an absolute path) and keep the GOD-KILLER tasks as they are: they
   launch the workers for whatever REDRUM filed.

The live "Build Flags" task still has its original prompt, which builds and **edits the
clean `~/.nixos` checkout**. That dirties the tree you switch from (`switch` then refuses
or commits it). Pause it (`update_scheduled_task enabled=false`) until step 3 replaces its
prompt; next run Sunday 2026-11-08 12:00 local.

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
- The `TODO.md` items "Upstream-fixes watchdog" and "Rebuild warnings catcher" are removed
  by this PR (implemented by the probes and `buildflags`). They are *built*, not yet *live*: the
  prompts are unapproved and the token lacks Issues permission, so the owner items stay in
  `TODO.md`.

**Thread 4 (permissions):**

- Done in `workflow/schedule-sandbox`: the absolute-path exclusion and allow rule for
  `schedule-precheck` (covers the `unswitched` check too), plus the guard rule. Still open:
  REDRUM, where the shared entry is inert and no `t3code` entry exists (docs/agents/security.md, "Scheduled checks run unsandboxed").
  No `gh issue *` allow is needed.
- Scheduled and worker threads must not run `full-access`. Decide whether workers
  launch `approval-required` (they then wait for you on each build) or
  `auto-accept-edits`.
- `gh pr create` and `git push` stay `ask`; the worker's PR step will wait for you
  by design.

**Thread 5 (secrets):** a fine-grained token for `gh` on REDRUM scoped to
`cqjro/nixos` with `issues: write`, `pull_requests: write`, `contents: write`.
The schedules need nothing else.

**Thread 6 (notifications):** the dispatchers end with a one-paragraph summary and the worker
waits on a PR approval, so "thread finished" and "approval needed" are the right wake signals.
The unswitched check delivers through `agent-notify send info` with a label (the `info` kind
now exists on `master`); what is still open (whether a scheduled thread's completion pings
the phone, the REDRUM `t3code` topic file) is in the last section of
[`unswitched-changes.md`](./unswitched-changes.md).

**Firmware thread:** nothing left; its `ignore` entry is already removed.
