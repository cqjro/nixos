---
name: ship-pr
description: Take a finished branch through verification, the review tiers, push and PR creation for this NixOS flake. Use when a change is implemented and the human wants it reviewed, pushed or turned into a PR.
---

# Ship a branch as a PR

Stop and report at the first failure; do not push a branch that fails tier 0.

1. **Scope.** `git diff --stat origin/master...HEAD` and the uncommitted state.
   Work out the affected hosts from `modules/hosts/host.nix` and each
   `machine.nix` (which hosts import the changed fragments). On REDRUM, never
   build GOD-KILLER: use `./rebuild.sh eval GOD-KILLER` instead.
2. **Tier 0.** `./rebuild.sh check <hosts>` then `./rebuild.sh build <host>`
   for each host this machine may build. Empty output + exit 0 = success; on
   GOD-KILLER summarise the closure diff (new/removed packages, size).
   Building a T2 host needs its firmware in this machine's store; if the build
   says it is missing, report the machine and host and stop (docs/firmware.md).
3. **Tier 1.** Run the `nix-reviewer` subagent with: branch name, affected
   hosts, TODO item (if any). Fix `CHANGES`, re-run tier 0 and tier 1
   (max two rounds).
4. **Tier 2.** If the diff touches the lockout surface —
   `git diff origin/master...HEAD | grep -nE 'boot\.|fileSystems|networking\.|firewall|services\.openssh|users\.users|security\.sudo|kernelPackages|stateVersion'`
   or changed files under the list in docs/agents/review.md — run the
   `lockout-reviewer` subagent the same way.
5. **Tier 3.** Only per docs/agents/review.md (two failed rounds, effort ≥ 7,
   or the human asks): `deep-reviewer` with the unresolved findings.
6. **Commit** remaining changes on the branch (ask rule) with a plain
   descriptive subject.
7. **Push and PR** — only when the human has said to:
   `./rebuild.sh push`, then fill `.github/pull_request_template.md` into a
   temp file (outside the repo, e.g. `$TMPDIR`) and
   `gh pr create --base master --title "<what changed>" --body-file <file>`.
   Call T3 `link_pull_request` with the URL. If asked to babysit, call
   `watch_pull_request` and end the turn.
