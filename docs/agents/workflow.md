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
| GOD-KILLER (home, fast) | any host | any host | GOD-KILLER, REDRUM (LittleNix once its firmware evaluates) | GOD-KILLER locally (askpass); REDRUM only by the human from a terminal (`--target`) | GOD-KILLER, from merged `master`, human-approved |
| REDRUM (away, always on) | any host | any host — **eval-only for GOD-KILLER** | REDRUM only (never GOD-KILLER: too slow, and pointless) | human, over SSH | human, over SSH |

- REDRUM agents run as the `t3code` system user and cannot sudo, so every
  activation on REDRUM is the human's (`ssh redrum`, then `./rebuild.sh test|switch REDRUM`).
- Until REDRUM has its own clone of the repo readable by `t3code` and the
  firmware is readable there (firmware thread), REDRUM agents are host
  troubleshooters (see [t3-claude.md](t3-claude.md)) and flake builds stay on
  GOD-KILLER.
- A REDRUM build done on GOD-KILLER can be shipped instead of rebuilt:
  `nix copy --to ssh-ng://USER@redrum ./result`, then the switch on REDRUM is a
  cache hit. Run by the human (it uses SSH keys agents cannot reach).

## Checkouts

- `~/.nixos` (main checkout) stays on `master` and clean. It is where the
  human switches from, and where `config-sync`/`start.sh` pull.
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
3. **Commit** on the branch (ask rule). Plain descriptive subjects, no
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
8. **Open the PR** (ask rule): `gh pr create --base master --head <branch>
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
    on the host, in `~/.nixos`: `git pull --ff-only`, then
    `./rebuild.sh switch HOST`. Optionally note the result on the PR
    (`gh pr comment <N> --body "GOD-KILLER: generation 231"`).

`switch` refuses to run off `master`, so unmerged work can only ever be
test-activated. The human can still bypass this for an emergency with plain
`sudo nixos-rebuild switch --flake .#HOST --impure`; that generation is then
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
