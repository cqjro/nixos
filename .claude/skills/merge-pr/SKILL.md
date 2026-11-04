---
name: merge-pr
description: Merge an approved PR for this NixOS flake (squash) and hand the human the switch steps. Use only when the human explicitly asks to merge a PR.
---

# Merge a PR

1. `gh pr view <N> --json state,mergeable,mergeStateStatus,headRefName,title,body`
   and `gh pr checks <N>` (if any). Confirm the PR body's Verification and
   Review sections are filled and passing; if not, run the ship-pr skill first.
2. If `mergeStateStatus` is `BEHIND` or conflicted: `gh pr update-branch <N>`
   (or merge `origin/master` into the branch locally and push — never force),
   then re-run tier 0 for the affected hosts.
3. `gh pr merge <N> --squash --delete-branch`. The human approving this
   permission card is the approval; never retry a denied merge.
4. Tell the human how to roll it out, per affected host, from the host itself:
   `cd ~/.nixos && ./rebuild.sh switch HOST` (it fetches and fast-forwards master first)
   (REDRUM: over SSH; lockout-surface changes: `./rebuild.sh dry REDRUM` first
   and keep console access). Afterwards `./rebuild.sh generations` shows the
   new generation next to the PR title.
5. If T3 is watching the PR, `unwatch_pull_request`. The worktree can be
   removed once the human is done with the thread.
