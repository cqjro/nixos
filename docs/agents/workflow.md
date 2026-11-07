# Change workflow: branches, PRs, testing, merging, generations

The rules are summarised in [AGENTS.md](../../AGENTS.md#change-workflow); this is
the full procedure. GitHub (`cqjro/nixos`, default branch `master`) is the hub
between machines: every unit of work is a branch and a PR, and only merged
`master` is switched into a recorded generation.

## Machines and what each may do

Each machine runs its own T3 server and its own checkout. Pick the machine by
picking the T3 environment in the client.

| Thread runs on | Edit config for | `eval` | `build` | `test` / `dry` | `switch` |
| --- | --- | --- | --- | --- | --- |
| GOD-KILLER (home, fast) | any host | any host | GOD-KILLER, REDRUM (LittleNix only once its firmware is imported here) | GOD-KILLER locally (card in a Supervised thread plus the askpass dialog at the desk, or the human in a terminal incl. T3's); REDRUM only by the human from a terminal (`--target`) | GOD-KILLER, from merged `master`, human-approved (same routes) |
| REDRUM (away, always on) | any host | any host — **eval-only for GOD-KILLER** | REDRUM only (never GOD-KILLER: too slow, and pointless) | human, over SSH | human, over SSH |

- REDRUM agents run as the `t3code` system user and cannot sudo, so every
  activation on REDRUM is the human's (`ssh redrum`, then `./rebuild.sh test|switch REDRUM`).
- REDRUM has its own clone of the repo, owned by `t3code` in its home
  (`/var/lib/t3code`), and a `./rebuild.sh build REDRUM` was tested there. A
  REDRUM thread is therefore a full repo thread: edit, `check`, `eval`, build
  REDRUM and commit/push like on GOD-KILLER (GOD-KILLER stays eval-only).
  Building REDRUM needs its firmware imported into REDRUM's store once
  (`nix run .#t2-firmware-import -- REDRUM`; see `docs/firmware.md`). That
  clone is agent-writable, so it must never be the source of a privileged
  switch: the human switches from their own `master` checkout.
- A REDRUM build done on GOD-KILLER can be shipped instead of rebuilt:
  `nix copy --no-check-sigs --to ssh-ng://redrum <toplevel path>` (run on
  GOD-KILLER from a clean `master` build, so the path matches what REDRUM
  computes), then the switch on REDRUM is a cache hit. `--no-check-sigs` is
  needed because locally built paths are unsigned; it works because `cairo` is a
  trusted Nix user on REDRUM (`modules/hosts/REDRUM/machine.nix`). Run by the
  human (it uses SSH keys agents cannot reach). Use it when REDRUM cannot
  rebuild a fixed-output derivation itself (this is how generation 38 was
  switched on 2026-11-06, before the pnpm FODs were made reproducible, see
  gotchas.md); the `dry`/`switch` on REDRUM then never builds it.

### One project, either machine

The repo is one T3 project (T3 identifies it by its git remote,
`github.com/cqjro/nixos`) that exists on both servers; pick the machine by
picking the environment when you start a thread.

- **T3 does not move code between machines.** Each machine has its own
  clone, and GitHub is the hub. A thread is bound to the server that runs it
  (its agent process, worktree and filesystem live there), so "switching
  machine" means pushing the branch and starting or forking a thread on the
  other environment, not moving a running thread.
- **A branch lives on one machine at a time.** Hand off by pushing, then
  `git fetch` and check the branch out on the other machine; do not commit to
  it in both places.
- **Verified 2026-11-07** (master `0949eb1`, then a throwaway branch each way):
  both servers list the repo as a project with the same
  `repositoryIdentity.canonicalKey` (`github.com/cqjro/nixos`; REDRUM's root is
  `/var/lib/t3code/nixos`); `check` and `build REDRUM` pass on both machines
  and yield the **identical** REDRUM toplevel from the same commit and
  `flake.lock`; `eval GOD-KILLER` passes on REDRUM (no RAM/disk problem); a
  branch pushed with `./rebuild.sh push` on either machine is fetched and
  built/checked on the other (`git fetch origin`, `git switch --detach
  origin/<branch>`) with the same toplevel path. Auto threads on both machines
  push over HTTPS without a card. A docs-only commit still changes the toplevel
  (the `git-<sha>` label), so compare paths only for the same commit.
- Prefer REDRUM for edits, evals and REDRUM builds when GOD-KILLER is off;
  prefer GOD-KILLER for anything that builds GOD-KILLER. Both draw on the same
  Pro quota, so a second machine adds availability, not throughput.

### Activating a system (switch, test, dry, revert)

Agents cannot run these on their own: `sudo` has no passwordless rule
(deliberately: an agent that can get code merged and switched owns root), and
`claude-guard` refuses the commands in **Auto** and Full access, where no
person would see a card ([security.md](security.md#t3-runtime-modes)).

- **From a thread that needs a switch to continue** (Auto, or any mode):
  launch a **Supervised child thread** for just that step with
  `t3_thread_launch` (`runtimeMode: "approval-required"`; confirm in the launch
  result that it really is Supervised). Its `ask` card is the approval. On
  GOD-KILLER the sudo password is typed in the desktop's GUI askpass dialog, so
  that route only completes when someone is at the machine. Otherwise hand the
  human the exact command and wait.
- **GOD-KILLER from your phone:** open the GOD-KILLER environment's terminal in
  T3 (tested 2026-11-06: a real tty, `sudo -v` takes the password) and run it
  from the main checkout as a plain command: `cd ~/.nixos && ./rebuild.sh
  switch GOD-KILLER` (worked on 2026-11-06). Do not wrap it in `systemd-run
  --user --wait` without `--pty` and `--working-directory`: it then has no tty
  (so `rebuild.sh` falls back to the GUI password dialog), no visible output
  and runs in `$HOME`. Keep terminal scope off phone pairing tokens unless you
  need it: a token with terminal scope is as powerful as the server's user
  (revoke it if the phone is lost).
- **REDRUM:** `ssh redrum` (from the phone too), then `./rebuild.sh switch
  REDRUM` in the human's checkout. Agents never switch REDRUM and there is no
  privileged switch service.
- A REDRUM thread cannot activate GOD-KILLER (`rebuild.sh` refuses a host that
  is not the local machine, and a remote activation needs a terminal).
  GOD-KILLER is told about merged changes by the unswitched-changes notifier,
  and switches when you do; nothing pulls or switches automatically.

## Checkouts

- `~/.nixos` (main checkout) stays on `master` and clean. It is where the
  human switches from. Nothing pulls it automatically: `./rebuild.sh switch`
  fetches and fast-forwards `master` itself, and agents never touch it.
- Work happens in T3 worktrees (`~/.t3/worktrees/.nixos/<branch>`), one per
  branch. `./rebuild.sh` operates on the checkout it lives in, so run it from
  the worktree. Uncommitted edits are not copied into new worktrees; push
  before launching a thread that depends on local-only commits.
- Never have the same branch checked out and committed to on two machines at
  once. Hand off by pushing, then fetching on the other machine.

## Lifecycle of a change

1. **Branch.** One TODO item = one thread = one worktree = one branch:
   `todo/<slug>` (TODO.md items), `fix/<slug>` (ad-hoc fixes),
   `auto/<slug>` (opened from a scheduled-thread finding),
   `workflow/<slug>` (agent tooling and docs). Base it on `origin/master`.
   From another thread: `t3_thread_launch` with
   `workspaceStrategy: {type: "worktree", baseRef: "master", branch: "todo/<slug>", startFromOrigin: true}`.
2. **Implement.** Follow AGENTS.md conventions; check options and packages
   with mcp-nixos before using them. Update README/AGENTS/docs and remove the
   TODO.md item in the same branch.
3. **Commit** on the branch (allowed; a commit on `master` asks). Plain descriptive subjects, no
   generation metadata. Several commits are fine; the merge squashes them.
4. **Verify** (agent, no root): `./rebuild.sh check HOST...` (tier 0), then
   `./rebuild.sh build HOST` for every affected host this machine may build.
   Affected hosts = the hosts whose module lists in `modules/hosts/host.nix`
   or `machine.nix` imports reference a changed fragment. Empty output with
   exit 0 from `build` is success; the log is `.log/nixos-build.log`.
5. **Test-activate** (optional, human-approved): `./rebuild.sh test HOST`
   activates the branch build without a boot entry or generation; `./rebuild.sh
   revert` (or a reboot) returns to the recorded generation. `./rebuild.sh dry
   HOST` lists what a switch would restart without changing anything — prefer it
   on REDRUM for network/SSH/Tailscale/boot/cloudflared changes, where a bad
   activation on a headless box needs physical access.
6. **Review** — see [review.md](review.md) for the tiers.
7. **Push** the branch: `./rebuild.sh push` (pushes the current branch, never
   forced; refuses `master` without a terminal).
8. **Open the PR** (allowed for this repo; `--repo` elsewhere asks): `gh pr create --base master --head <branch>
   --title "<what changed>" --body-file <filled template>` using
   [`.github/pull_request_template.md`](../../.github/pull_request_template.md).
   Then call T3's `link_pull_request` with the PR URL. If asked to babysit it,
   `watch_pull_request` and end the turn (T3 wakes the thread); call
   `unwatch_pull_request` when handing back.
9. **Keep it current.** If `master` moved, `gh pr update-branch <N>` (merges
   master into the branch on GitHub; no force-push) or `git merge origin/master`
   locally, then re-run step 4. Conflict hotspots: README.md, AGENTS.md,
   TODO.md, `modules/hosts/host.nix` — keep edits there small.
10. **Merge.** Only when the human asks. The agent runs
    `gh pr merge <N> --squash --delete-branch`; approving that permission card
    in T3 **is** the approval (PRs are authored with the human's own token, so
    GitHub's self-approval is unavailable). The squash commit's subject is the
    PR title plus `(#N)`.
11. **Switch** the affected hosts from merged master (human-approved):
    on the host, in `~/.nixos`: `./rebuild.sh switch HOST` (it fetches and
    fast-forwards `master` first, and refuses if `master` has diverged or the
    tree is dirty while behind). Optionally note the result on the PR
    (`gh pr comment <N> --body "GOD-KILLER: generation 231"`).

`switch` refuses to run off `master`, so unmerged work can only ever be
test-activated. The human can still bypass this for an emergency with plain
`sudo nixos-rebuild switch --flake .#HOST`; that generation is then
stamped with the branch commit (or `-dirty`).

## Generation tracking

`modules/essentials/config-revision.nix` (in every host's module list) sets

- `system.configurationRevision` = the flake's git commit (`<sha>-dirty` if
  built from a tree with uncommitted changes) — the "Configuration Revision"
  column of `nixos-rebuild list-generations` and `nixos-version --json`;
- `system.nixos.tags = [ "git-<shortsha>" ]` — the short hash in the boot menu
  entry and the system path name.

`./rebuild.sh generations [--target USER@IP]` prints each generation with the
subject of the commit it was built from (for squash merges: PR title + `#N`).
Generations from before this module fall back to the subject of the old
`HOST: <gen> … || message` metadata commit. The flake metadata only carries the
hash, so the message is looked up in git at listing time; on a clone that lacks
the commit it says so (`git fetch`).

There is no post-switch commit any more: the commit exists before the switch,
and the generation records it. The interactive `./rebuild.sh` on `master`
therefore runs build → commit → switch → push.

## Model and effort per task

TODO.md items carry a 1–10 effort score. One provider (Claude, Pro plan) means
every thread draws from the same quota, so more threads is not more throughput
— keep about three build-heavy threads in flight.

| Work | Model | Effort |
| --- | --- | --- |
| Triage, scheduled checks, tier-1 reviews | Haiku | low |
| Effort 1–3 | Sonnet | medium |
| Effort 4–6 | Sonnet | high |
| Effort 7–10 | Opus to plan (plan mode, no edits), then Sonnet (high) to implement | — |
| Review escalation (tier 3) | Opus | high |

Avoid `ultra` reviews (billed) and T3's heaviest multi-agent effort for routine
config work. The `start-todo` skill applies this table when launching a thread.

## Path to close

A thread exists to finish one piece of work, so every reply to the human ends
by showing the way to finishing it. Use this block, after the answer itself:

```markdown
### Path to close
1. **Agent** — re-run `check` and `build` for GOD-KILLER and REDRUM.
2. **You** — approve the push card.
3. **Agent** — open the PR and link it to this thread.
4. **You** — say "merge it", then `./rebuild.sh switch REDRUM`. *(closes the thread)*

**Delegated:** scheduled drift check → [Scheduled threads](t3-thread://v1/<threadId>)
**Waiting on:** firmware PR merging first
```

- **One ordered list, both perspectives.** Tag each step **Agent** (what this
  thread will do next) or **You** (decisions, approvals, commands only the
  human can run, such as `switch`, sudo or anything on another machine).
  Order the steps by dependency, so the first one is always the next thing to
  happen, and mark the last one *(closes the thread)*.
- **Concrete steps.** Each step names a command, file, PR or decision, not
  "follow up". Questions the human must answer are **You** steps.
- **Delegated** lists work handed to another thread, subagent or scheduled
  task, linked as `t3-thread://v1/<threadId>` or by task id. Delegated work
  does not keep this thread open; the receiving thread owns it.
- **Waiting on** lists outside events (another PR, a reboot, an upstream fix)
  that gate a step. Omit empty sections.
- Keep it short and update it every reply. Drop finished steps, and do not
  repeat what the answer above already explained.

### Settling

When the list is empty, or every remaining step is delegated, replace it with a
recommendation to settle, after checking:

- commits are pushed (or deliberately local, and the human knows why);
- every PR from this thread is linked (`list_thread_pull_requests`), merged or
  handed off, and `unwatch_pull_request` has been called;
- delegated work has a named owner thread or task;
- the worktree has no uncommitted changes (`git status`), and docs, TODO.md
  and memory are updated.

Then recommend one of:

- **Settle** — done. T3's `t3_thread_organize` `settle`, only after the human
  agrees; it takes effect when the turn ends.
- **Snooze until <event>** — the only thing left is waiting, e.g. for a PR
  merge or a reboot.
- **Archive** — the work was abandoned or superseded (say by what).

After a merge, also suggest removing the thread's worktree once nothing else
uses the branch.
