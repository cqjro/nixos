# T2 Wi-Fi/Bluetooth firmware

Covers: what the `brcm` firmware is and whether it may go to GitHub or agents,
how the config consumes it without it being in git, which machine can build
what, and the runbook for scrubbing it from git history.

Status legend: **verified** = run on GOD-KILLER on 2026-11-01; **untested** =
needs a human or another machine.

## TL;DR

- The files are Apple's per-Mac Broadcom Wi-Fi/Bluetooth firmware, extracted
  from macOS. Treat them as **proprietary third-party files**: not a secret, not
  a credential (nothing to rotate), but not ours to redistribute, so: **not in
  git, not in a public binary cache**.
- They now live **outside the repo**, are pinned by hash in each host's
  `machine.nix`, and are found through the **Nix store** (`pkgs.requireFile`).
  Evaluation never needs them; only a build does. Clean clones, T3 worktrees and
  reviewers evaluate all three hosts with no files and **without `--impure`**
  (verified).
- They are **still in git history** (both REDRUM's and LittleNix's sets) on
  `master` and `dendritic`. The plan (section 6): rename the old repo to the
  private `nixos-archive`, rewrite a scratch clone once (firmware, secrets paths,
  emails) and publish it as a new `cqjro/nixos`, so the repo can be public again
  without the firmware and nothing is force-pushed or purged.

## 1. What is in the directory

`modules/hosts/REDRUM/firmware/brcm/` (gitignored, 27 MB, 168 files; names only,
contents never leave the machine):

| Pattern | Count | What |
| --- | --- | --- |
| `brcmfmac4355c1/4364b2/4364b3/4377b3-pcie.apple,<model>.*` | 130 | Wi-Fi: firmware `.bin`, regulatory `.clm_blob`, `.txcap_blob`, board NVRAM `.txt` |
| `brcmbt4377b3/4378b1/4378b3/4387c2/4388b0/4388c0-apple,<model>.*` | 38 | Bluetooth: patch `.bin`, `.ptb` |

`<model>` is an Apple board codename (`ekans`, `kahana`, `hawaii`, `santorini`,
...). The t2linux extractor copies the set for **every** T2 Mac, not only the
host's own model, so each host's directory holds far more than it uses.

Where the files have been:

| Place | REDRUM set (168 files) | LittleNix set (163 files) |
| --- | --- | --- |
| git history, added | `2412d99` (2026-07-16) as `hosts/REDRUM/firmware/brcm` | `0181e6a` (2025-05-13) as `hosts/LittleNix/firmware/brcm` |
| git history, deleted | `18bdb40` (2026-09-03) | `e7db8ad` (2026-05-04) |
| branches containing them | `master`, `dendritic`, `origin/master`, `origin/dendritic` | same |
| working trees | GOD-KILLER `~/.nixos/modules/hosts/REDRUM/firmware/brcm`, REDRUM's own checkout | LittleNix's own checkout (not on GOD-KILLER) |

The REDRUM copy in history and the copy on disk are byte-identical (same NAR
hash, verified). The LittleNix copy on the LittleNix machine may differ from the
2025 commit; its hash is **unverified** (section 3).

The earlier research thread said only REDRUM's set was in history. LittleNix's
is too, so the scrub must cover both paths.

## 2. License and exposure assessment

**Conclusion (not legal advice):** treat the files as proprietary and
non-redistributable. Keeping them in a private repo limits access but still
hosts a copy at GitHub, in every clone, and in anything that clones or forks
while the repo is visible. The risk is redistribution, not agents reading them.

Evidence:

- Hector Martin (Asahi Linux), on the brcmfmac Apple T2/M1 series, LKML Dec
  2021: "the firmware for these machines is not available under a redistributable
  license" and "every owner of one of these machines is implicitly licensed to
  posess the firmware"; the packages are on Apple's CDN without authentication.
  <https://lkml.iu.edu/hypermail/linux/kernel/2112.3/00773.html>
- The t2linux Wi-Fi/Bluetooth guide gives five ways to *extract* the firmware
  from macOS or an Apple Recovery image on the user's own machine, and ships no
  copy. It says nothing about licensing.
  <https://wiki.t2linux.org/guides/wifi-bluetooth/>
- The t2linux NixOS guide tells users to copy the files into their config
  directory (`src = ./firmware/brcm;`) with no licensing warning. That is the
  origin of the commit.
  <https://wiki.t2linux.org/distributions/nixos/installation/>
- linux-firmware's `WHENCE` marks the generic Broadcom `brcm/` firmware
  "Redistributable" under `LICENCE.broadcom_bcm43xx`. I read only the first
  100 kB of its 514 kB and found **no** Apple-specific `apple,<model>` entries
  there; that is inconclusive, but it matches the distro practice of not shipping
  these files.

Not verified: the text of Apple's macOS license for these components, Broadcom's
terms for the Apple-customised builds, and how a court or GitHub would treat a
private copy. What I did not verify, I did not assume away.

Exposure paths, in order of concern:

1. **git/GitHub**: history on `origin` (private now). **Confirmed by the owner: the repo was
   public while the firmware was in history, then made private.** Making a public
   repo private detaches its forks into separate public repos, and the current
   `forkCount: 0` would not show them, so clones and detached forks may still
   hold the files and cannot be recalled. The goal is to make the repo public again, so history is handled by
   publishing a rewritten copy as a new repo and keeping this one private
   (section 6). That cannot recall copies made while it was public (6.7).
2. **Binary caches**: none configured except the read-only Millennium cachix in
   `modules/system/games.nix`; nothing pushes. Keep it that way: never
   `nix copy` or `cachix push` firmware to a public cache.
3. **Every clone**: GOD-KILLER, REDRUM (`config-sync`, and `./rebuild.sh switch` fast-forwards `master`), LittleNix, T3
   worktrees under `~/.t3/worktrees/.nixos/*`, and T3's hidden
   `refs/t3/orchestration-v2/checkpoints/*` refs (117 locally; all reach the
   firmware commits).
4. **Agents**: file *names* are fine. Agents never need the bytes. Git does not
   print binary diffs, but the 70 board-NVRAM `*.txt` files are text, so
   `git log -p`/`git show` of `2412d99`/`0181e6a` would put them in a
   transcript. Low impact (calibration text) but another reason to scrub, and
   agents should not run those commands.
5. **T3 attachments / `request_secret`**: never attach or paste the files.

## 3. How the config consumes the firmware

### Options considered

| Option | Pure eval / clean clone | Clear error | Agent (`t3code`) access | Verdict |
| --- | --- | --- | --- | --- |
| `builtins.path` on an absolute out-of-repo path (old REDRUM approach) | needs `--impure`; **eval fails** when the path is absent unless guarded by `pathExists` + an env-var/placeholder (impure too); copies and hashes 27 MB on every eval | only via a `throw` you write | the *evaluating* user must read the path, so `/home/cairo/...` fails for `t3code` (home is 0700); `/var/lib/...` would need a group | rejected |
| local flake input (`path:/var/lib/...`, `flake = false`) | every host, including GOD-KILLER, fails to lock/eval without the files unless every command passes `--override-input`; absolute path and narHash land in `flake.lock` | confusing fetch error | same as above | rejected |
| encrypted blob in git (sops/age/git-crypt) | works | n/a | n/a | rejected: still publishes a copy to GitHub |
| **`pkgs.requireFile` + content-addressed store path** | **pure; eval never touches the files** (verified: `nix flake check --no-build` passes without `--impure`) | custom message with the exact commands and expected hash | store paths are world-readable, so the `t3code` user needs nothing from `/home` | **chosen** |

Costs of the chosen design: the hash must be bumped when the firmware set
changes (rare), and each machine that *builds* a T2 host must have the path in
its store once (a one-line import), pinned with a GC root so it survives
`nix-collect-garbage`.

### What was added

- `modules/system/t2-firmware.nix`: NixOS fragment `t2-firmware` with options
  `t2-firmware.hash` (SRI NAR hash of the host's `brcm` dir, `null` until set)
  and `t2-firmware.stagingDir` (default `/var/lib/firmware-src/<hostName>/brcm`).
  It wraps `pkgs.requireFile { name = "brcm-firmware"; hashMode = "recursive"; }`
  in a `runCommand` that copies into `lib/firmware/brcm` and sets
  `allowSubstitutes = false` so no cache is ever asked for it. It also creates
  `/var/lib/firmware-src[/<host>]` (0755, `cairo:users`). The same file exports
  `packages.x86_64-linux.t2-firmware-import`.
- `modules/scripts/t2-firmware-import.sh` (the `t2-firmware-import` command):
  `nix run .#t2-firmware-import -- HOST [DIR]` hashes `DIR`, adds it to the store
  with `--name brcm-firmware`, creates `<DIR>/../brcm-firmware.gcroot`, and
  compares the hash with `machine.nix`: `OK`, or `MISMATCH` with the hash to use.
- `modules/hosts/{REDRUM,LittleNix}/machine.nix`: the inline `hardware.firmware`
  blocks are replaced by `imports = [ inputs.self.modules.nixos."t2-firmware" ]`
  plus `t2-firmware.hash`. The fragment is imported from `machine.nix` instead of
  `host.nix` to stay out of other threads' files; moving that one line into
  `host.nix` is equally valid.
- `.gitignore`: backstop patterns beyond `firmware/` (`brcm/`, `firmware.tar*`,
  `brcm-firmware.gcroot`, `brcmfmac*`, `brcmbt*`, `*.clm_blob`, `*.txcap_blob`,
  `*.ptb`). No tracked file matches them (checked).

The path name `brcm-firmware` and the recursive SHA-256 are exactly what the old
`builtins.path` produced, so the REDRUM store path **already exists** on
GOD-KILLER (`/nix/store/prscpri4fy5x2gy488j3rag9awjv568x-brcm-firmware`), and
the new wrapper output is byte-identical to the deployed one (NAR hash
`sha256-NNlOCVgPJlUDyAREk8YPKgOEz5YhgQlmA6mayTP81/4=`), so switching changes no
firmware.

### Pinned hashes

| Host | `t2-firmware.hash` | Status |
| --- | --- | --- |
| REDRUM | `sha256-JZmV/AGsxtMeLcYKFjHQ/oUwZhcxk9AJu7q8FT+pwq8=` | verified against the on-disk copy and the copy in git history |
| LittleNix | `sha256-bA/Thojm8PRCMrTwV40FhNZ++Y5pfRmPavgCNHkw+J4=` | **unverified**: hash of the 2025 copy in git history. Run the importer on LittleNix; on `MISMATCH`, set the printed hash. |

### Is a placeholder needed for eval-only checks?

No. `requireFile` is lazy: evaluation (and `nix build --dry-run`) succeeds without
the files, and only realising the derivation fails. Verified in a clean worktree
with the firmware directory absent:

- `nix eval ... toplevel.drvPath` succeeds for REDRUM, LittleNix and GOD-KILLER,
  no `--impure`.
- `nix flake check --no-build` passes.
- `nix build ...LittleNix.config.hardware.firmware` fails with the placement
  instructions (the hash was never imported on this machine).

A `t2-firmware.allowMissing` switch that builds without Wi-Fi was deliberately
**not** added: a successful `switch` that silently drops Wi-Fi/Bluetooth on a
headless server is worse than a failed build. Reviewers use eval and
`--dry-run`; builds need the files.

### Placing the files

On any machine that builds a T2 host (steps for REDRUM; LittleNix is the same
with its own name):

1. Get the files into `/var/lib/firmware-src/REDRUM/brcm`:
   - **From a machine that already has them** (preferred, keeps the hash):
     `rsync -a --info=progress2 /var/lib/firmware-src/REDRUM/brcm/ redrum:/var/lib/firmware-src/REDRUM/brcm/`
     (over Tailscale/SSH; never via GitHub, chat or T3 attachments).
   - **From the checkout's old location** (GOD-KILLER today has them, untracked,
     in `~/.nixos/modules/hosts/REDRUM/firmware/brcm`, 27 MB): *copy* them out,
     do not move yet:
     `sudo install -d -o cairo -g users /var/lib/firmware-src /var/lib/firmware-src/REDRUM && cp -a ~/.nixos/modules/hosts/REDRUM/firmware/brcm /var/lib/firmware-src/REDRUM/`.
     Delete the old directory only after this branch is merged: until then
     `master` still points its REDRUM firmware at that absolute path, and the
     old `~/.nixos` is replaced by the re-clone in 6.5 anyway.
   - **From the Mac itself**: re-extract with the t2linux `firmware.sh`. Output can
     differ by macOS version, so expect a hash `MISMATCH` and then re-pin.
2. `cd ~/.nixos && nix run .#t2-firmware-import -- REDRUM`. Expect `OK`.
   Until this branch is merged, `~/.nixos` (`master`) has no importer or
   `t2-firmware.hash`; run it from the branch's checkout instead:
   `cd ~/.t3/worktrees/.nixos/workflow-firmware && nix run .#t2-firmware-import -- REDRUM`
   (it reads the pinned hash from `.`, so it must be run from there).

Alternatively move the store path directly (verified path format; `nix copy` to
a remote store is **untested** from here): `nix copy --to ssh-ng://cairo@redrum /nix/store/prscpri4fy5x2gy488j3rag9awjv568x-brcm-firmware`.
The path is content-addressed, and REDRUM already lists `cairo` in
`nix.settings.trusted-users`. Add a GC root on the target afterwards (the
importer does this when pointed at the staging dir).

If the build says the firmware is missing, the message already names the hash and
these commands.

### LittleNix (parked)

LittleNix is not being rebuilt for now, so nothing here is urgent, but the
config is ready for it. Its pinned hash is **unverified**, and a fresh install of
the machine is possible, so know where its firmware can come from:

- **The history copy survives in the private archive repo** (`cqjro/nixos-archive`, and
  in `~/.nixos.pre-rewrite` until you delete it), but not in the new public repo. To
  extract it, from a clone of the archive (or the old `~/.nixos`), on GOD-KILLER:
  `mkdir -p /tmp/ln && git -C ~/.nixos archive 0181e6a hosts/LittleNix/firmware/brcm | tar -x -C /tmp/ln && sudo install -d -o cairo -g users /var/lib/firmware-src/LittleNix && mv /tmp/ln/hosts/LittleNix/firmware/brcm /var/lib/firmware-src/LittleNix/brcm`.
  Do not open, print or attach the files.
- **Verify it** on any machine with the branch checked out:
  `nix run .#t2-firmware-import -- LittleNix`. `OK` means the pinned hash was
  right and the file set equals what the machine used. `MISMATCH` prints the
  hash to put in `modules/hosts/LittleNix/machine.nix`.
- **The current install** also holds the files (wherever they were extracted),
  but a **fresh install wipes them**. Before reinstalling either extract the copy
  above (copy it off over Tailscale/SSH or a USB stick, never GitHub), or plan to
  re-extract from macOS with the t2linux `firmware.sh` (Linux install guide of
  the t2linux project); output can differ by macOS version, so expect `MISMATCH`
  and re-pin.
- **On the (re)installed machine:** put the directory in
  `/var/lib/firmware-src/LittleNix/brcm` (create the parents with
  `sudo install -d -o cairo -g users`), run the importer, then build. With no
  files the build fails with the placement instructions, and the machine gets
  no Wi-Fi/Bluetooth, which matters on first boot of a new install: keep a wired
  adapter or a phone tether handy for the first rebuild.
- A GOD-KILLER build of LittleNix (`./rebuild.sh build LittleNix`) also needs the
  files imported on GOD-KILLER.

## 4. Who can build what, and how the files get there

| Builder | Target | Needs | Status |
| --- | --- | --- | --- |
| GOD-KILLER (human or agent) | GOD-KILLER | nothing | verified (eval) |
| GOD-KILLER | REDRUM | REDRUM firmware in GOD-KILLER's store (already there; importer adds a GC root) | **verified**: full `toplevel` build from a worktree, no `--impure` |
| GOD-KILLER | LittleNix | LittleNix firmware imported into GOD-KILLER's store | not possible yet: files are only on the LittleNix machine |
| REDRUM | REDRUM | REDRUM firmware in REDRUM's store (run the importer once; the old path may have been GC'd) | untested |
| REDRUM | GOD-KILLER | never build; eval-only works with no files | verified (eval) |
| `t3code` user on REDRUM | REDRUM | the store path only; no read access to `/home` or the staging dir | untested (user absent here) |
| any clean clone / worktree | any host | nothing to eval; files only to build | verified |

Switching REDRUM from a GOD-KILLER build needs no firmware step on REDRUM at all:
`nix copy --to ssh-ng://cairo@redrum ./result` moves the finished closure, which
already contains the copied firmware (`nixos-rebuild --target-host` does the
same). The human still runs the switch (AGENTS.md: agents build REDRUM, never
switch it).

Keep these private: copy only over SSH/Tailscale or `nix copy` to your own hosts.

## 5. Rules for agents

- File names, counts and sizes may be listed. Never `cat`, `strings`, `xxd`,
  `git show`, `git log -p` or attach firmware files or the history commits
  `2412d99` / `0181e6a`.
- Never `git add -f` a firmware path, push a `result` that contains it to a
  cache, or paste it into `request_secret` (it is not a secret; it just must not
  be shared).
- Do not run the section 6 runbook, rewrite history, `git push --force` or touch
  the archive repo: that is for the human.
- If a build fails with "The Apple Broadcom firmware ... is not in the Nix store",
  stop and tell the human which machine and host; do not work around it.

## 6. Runbook: publish a clean history in a new repo (human only)

Decided by the owner on 2026-11-02: the goal is to make the repo **public again
without the firmware**, and the old repo is kept **private forever** as an
archive. So nothing is force-pushed or purged on GitHub. Instead:

1. the old repo is renamed `cqjro/nixos-archive` (stays private, optionally
   archived) and is never modified again;
2. a **scratch clone** is rewritten **once**: firmware, the secrets thread's
   extra paths and personal emails are all removed in the same
   `git filter-repo` run (section 2.7 of the private audit), and the six `workflow/*`
   branches are rewritten with it;
3. a brand-new **empty** repo `cqjro/nixos` (same name, so every URL in the docs
   and in `rebuild.sh` stays valid) receives only `master` and the workflow
   branches from that scratch clone, private first, public after the checks.

Why this beats rewriting in place: no `push --force --mirror`, no PR-ref problem
(the new repo has none), no GitHub Support decision, and the old history is still
there if you ever want it (including the LittleNix firmware at `0181e6a`).

**Rehearsed 2026-11-02** on a throwaway local clone (nothing contacted GitHub,
the clone is deleted): 187 firmware objects found and 0 left; 0 non-noreply
author/committer emails left; refs after the rewrite are `master` plus the six
`workflow/*` branches; each branch still branches from the rewritten commit it was cut from
(`eac96f8`; `master` has since moved 2 commits ahead of it, see 6.8) with
its commit count intact (agent-security 3, firmware 7, notifications 6,
pr-rebuild-docs 4, schedules 2, secrets 10 commits ahead, counts before the 6.2a squash, which turns the secrets branch into pr-rebuild-docs plus one commit); the tip tree differs
from the old one in exactly two files (`modules/_archive/rclone.nix` and
`modules/home-manager/terminal/git.nix`, one email line each). Not rehearsed: the
GitHub steps (rename, create, push, visibility).

### 6.1 What renaming does to existing clones

GitHub redirects the old name to the renamed repo, including `git clone`,
`git fetch` and `git push` (GitHub docs, "Renaming a repository"). **But if you
create a new repo with the original name, the redirect stops.** So:

- Until the new `cqjro/nixos` exists, old clones keep working against
  `nixos-archive` through the redirect.
- Once it exists, an old clone's `origin` (`https://github.com/cqjro/nixos.git`)
  points at the **new** repo. A `pull` then fails with unrelated histories and a
  normal `push` is rejected, but **a force push from an old clone would put the
  firmware back**. Treat every old clone and worktree as tainted: replace them
  (6.4), never repair them.
- A clone you keep as a local archive: `git remote set-url origin https://github.com/cqjro/nixos-archive.git`.

### 6.2 Before you start

1. **No thread may be running** and every branch must be committed. Check each:
   ```bash
   for w in ~/.t3/worktrees/.nixos/*/; do echo "$w: $(git -C "$w" status --short | wc -l) uncommitted"; done
   git -C ~/.nixos status -sb        # master must be in sync with origin/master
   ```
   **Do not run `./rebuild.sh switch` (it commits and fast-forwards `master`) or
   commit to `master` between the 6.3 clone and the 6.4 retire**: a commit made in
   that window is not in the new repo. If `master` advances after the clone, redo 6.3.
   Do not start threads that use `~/.nixos` until step 6.4 is done. Read what you
   want from the threads first: deleting their worktrees later loses their diffs
   and checkpoints.
2. **Place the firmware outside the repo** (section 3, "Placing the files") and
   confirm `OK` from the importer.
3. **Tools:** `nix shell nixpkgs#git-filter-repo nixpkgs#git` for the rewrite;
   gitleaks and trufflehog run through `nix run` below.

### 6.2a Split and squash `workflow/secrets` (before 6.3)

Requested by the owner via the secrets thread. The dated audit report
(`docs/secrets.md` sections 1 and 2: findings, exposure timeline, owner
questions) must live **only** in the private `cqjro/nixos-archive`. Moving the
file is not enough: every earlier commit of `workflow/secrets` contains that
text, and the branch rides along in the 6.3 rewrite. So the branch history is
squashed first and the audit file never enters the public repo.

**Order, and why it differs from the request.** The task said "once the empty
repo exists and before `workflow/secrets` is pushed". The binding constraint is
the second half. Doing the squash **before 6.3** satisfies it with less risk: the
6.3 scratch clone copies every local branch of `~/.nixos`, so with the old branch
still present its audit history would go through the rewrite and into the clone
that is pushed. Only committing the audit file to `nixos-archive` has to wait for
the rename (6.4 step 1).

Each block below is for you to run and approve; stop and ask if any output is not
what is stated. Everything stays in `/tmp` and local branches; nothing is pushed.

1. **Save the full history to a private path** (outside every repo, not synced):
   ```bash
   install -d -m 700 ~/private-backup
   git -C ~/.nixos bundle create ~/private-backup/secrets-full.bundle eac96f8..workflow/secrets
   git bundle verify ~/private-backup/secrets-full.bundle      # expect "is okay"
   ```
   The `eac96f8..` range keeps the old pre-rewrite `master` (and the firmware in
   it) out of the bundle; restoring needs `master`, which the archive repo has.
   Do not copy this bundle into any repo, T3 attachment or cloud folder.
2. **Split, on a scratch worktree of the branch** (the real `workflow/secrets`
   stays untouched: a worktree and a finished thread are bound to it):
   ```bash
   git -C ~/.nixos worktree add -b workflow/secrets-after-split /tmp/secrets-split workflow/secrets
   cd /tmp/secrets-split
   f=docs/secrets.md
   s=$(grep -n '^## 1\. Do these first' $f | cut -d: -f1)
   e=$(grep -n '^## 3\. Nix store exposure' $f | cut -d: -f1)
   # the audit report goes to a PRIVATE file, never into this tree:
   { printf '# Secrets audit (private; lives only in cqjro/nixos-archive)\n\n'; sed -n "${s},$((e-1))p" $f; } > ~/private-backup/secrets-audit.md
   # public file: header + your short summary + sections 3 to 9 unchanged
   { sed -n "1,$((s-1))p" $f; cat ~/private-backup/secrets-summary.md; echo; tail -n +$e $f; } > /tmp/secrets.new && mv /tmp/secrets.new $f
   sed -i 's|\[1 Do these first\](#1-do-these-first) · \[2 Audit\](#2-audit) ·|[1 Summary](#1-summary) ·|' $f
   ```
   Write `~/private-backup/secrets-summary.md` in your editor **before** running
   the block (the owner asked for about ten lines). Proposed text:

   > ## 1. Summary
   >
   > - No credential was found in the working tree or in any git history that was
   >   ever public (gitleaks and trufflehog over every commit).
   > - The larger risk is at runtime: credentials in files an agent can reach (a
   >   Full access thread runs without prompts) and anything pasted into a thread.
   >   Sections 4, 6 and 7 are the response.
   > - Rotation is a precaution, not the response to a known leak.
   > - The dated audit report (method, findings, exposure timeline, decisions) is
   >   kept in the private repository `cqjro/nixos-archive` as
   >   `docs/secrets-audit.md`.

   Rehearsed on a throwaway clone with an empty summary: the audit range was lines
   14-342 of 796 (329 lines) and the public file kept 471 lines.
3. **Fix the references the split broke.** List them and reword each to "see
   `docs/secrets-audit.md` in the private `cqjro/nixos-archive`" or delete it:
   ```bash
   grep -nE '\b2\.[0-9]\b|\bF[0-9]+\b|section (1|2)\b|Do these first' \
     docs/secrets.md docs/agents/secrets.md TODO.md README.md AGENTS.md CLAUDE.md \
     modules/scripts/*.sh modules/_archive/secrets*
   ```
   The rehearsal found 4 hits in `docs/secrets.md` alone (a `2.5` and a `2.4`
   cross-reference, and two rows of section 8) plus `history-email-scrub.sh`'s
   header comment (`docs/secrets.md 2.7`) and the `TODO.md` item. In `TODO.md`,
   delete the finished sub-items of "Secrets: finish before the new repo goes
   public"; **its "Split `docs/secrets.md` …" line currently starts with a stray
   `$1`** (a broken substitution), so rewrite that part by hand. Then
   `git add -A && git commit -m "split audit out of docs/secrets.md"` on this branch.
4. **Squash onto the docs branch** in a second clean worktree (3-way apply of the
   branch's net change; `69b6e65` is the commit of `workflow/pr-rebuild-docs`
   that `workflow/secrets` merged, so the diff is only the secrets thread's own work):
   ```bash
   git -C ~/.nixos worktree add -b workflow/secrets-squashed /tmp/secrets-squash workflow/pr-rebuild-docs
   cd /tmp/secrets-squash
   git diff 69b6e65 workflow/secrets-after-split -- . ':!docs/secrets-audit.md' | git apply --3way --index
   git diff --name-only --diff-filter=U        # expect no output (no conflicts)
   test ! -e docs/secrets-audit.md && echo audit-file-absent     # must print
   git commit -m "secrets: audit docs, secret-guard hooks, email scrub helper"
   ```
   Rehearsed with the **unsplit** branch on a clone of the docs branch at
   `f40408a`: the apply was clean (0 conflicts, 18 files). With your edits from
   step 3 it is **not** rehearsed; if it reports conflicts, stop and do not
   resolve them in a hurry.
5. **Clean up the scratch worktrees** (keep the branch `workflow/secrets-squashed`):
   `git -C ~/.nixos worktree remove --force /tmp/secrets-split` and the same for
   `/tmp/secrets-squash` (the `-after-split` branch stays until after the push; it contains the
   unsquashed history of the branch, so it must **not** be in the 6.3 clone: 6.3
   step 1 drops it).

The squashed branch is based on `workflow/pr-rebuild-docs`, so its PR shows the
docs commits too until that one is merged: merge pr-rebuild-docs first.

### 6.3 Rewrite in a scratch clone (reversible, touches nothing real)

```bash
nix shell nixpkgs#git-filter-repo nixpkgs#git      # a subshell with the tools

# 1. Clone the LOCAL repo (the workflow branches exist only there), away from ~/.nixos
rm -rf /tmp/nixos-rewrite && git clone file:///home/cairo/.nixos /tmp/nixos-rewrite
cd /tmp/nixos-rewrite
git branch -D -r origin/dendritic        # obsolete branch stays in the archive only
# the unsquashed secrets history must not enter the clone (6.2a): drop it, keep the squashed one under the real name
git branch -D -r origin/workflow/secrets origin/workflow/secrets-after-split
git update-ref refs/remotes/origin/workflow/secrets refs/remotes/origin/workflow/secrets-squashed
git update-ref -d refs/remotes/origin/workflow/secrets-squashed

# 2. Record what must disappear, to prove it later
git rev-list --all --objects | grep -E ' (modules/)?hosts/(REDRUM|LittleNix)/firmware/' \
  | cut -d' ' -f1 | sort -u > /tmp/firmware-objects.txt
wc -l < /tmp/firmware-objects.txt        # expect 187
git rev-parse origin/master^{tree} > /tmp/old-tip-tree.txt

# 3. Email files (the helper lives on workflow/secrets; the files list the very
#    addresses being removed, so they stay OUTSIDE any repo and are deleted after)
git show origin/workflow/secrets:modules/scripts/history-email-scrub.sh > /tmp/history-email-scrub.sh
bash /tmp/history-email-scrub.sh /tmp/nixos-rewrite ~/rewrite-emails   # prints counts only

# 4. The one rewrite
git filter-repo --invert-paths \
  --path hosts/REDRUM/firmware --path hosts/LittleNix/firmware \
  --path modules/hosts/REDRUM/firmware --path modules/hosts/LittleNix/firmware \
  --path modules/system/networking/school-wifi.nix --path nixos-switch.log --path result \
  --mailmap ~/rewrite-emails/mailmap.txt --replace-text ~/rewrite-emails/replace-text.txt
```

`filter-repo` deletes the `origin` remote, which is what you want: the archive
can no longer be pushed to from here by accident.

**Verify (all of these must pass, otherwise discard `/tmp/nixos-rewrite` and
stop):**

```bash
git remote -v                                                   # expect no output
git for-each-ref --format='%(refname)'                          # expect master + 6 workflow/* (no dendritic)
git cat-file --batch-check < /tmp/firmware-objects.txt | grep -vc missing   # expect 0
git rev-list --all --objects | grep -ci -E 'brcm|/firmware/'    # expect 0
git log --all --name-only --pretty=format: | sort -u | grep -ciE 'school-wifi|nixos-switch\.log|^result$'   # expect 0
git log --all --format='%ae%n%ce' | sort -u | grep -vc noreply  # expect 0
git log --all -p | grep -c 'The public wind[o]w'           # tripwire, expect 0 (the bracket stops it matching itself)
git log --all --name-only --pretty=format: | sort -u | grep -c 'secrets-audit'   # expect 0
# the branches were cut from the old eac96f8; master may have moved on since (6.8), so
# check against the rewritten eac96f8 from filter-repo's commit map:
old=$(git -C /home/cairo/.nixos rev-parse eac96f8)
new=$(awk -v o="$old" '$1==o {print $2}' .git/filter-repo/commit-map)
for b in $(git for-each-ref --format='%(refname:short)' 'refs/heads/workflow/*'); do
  echo "$b: $(git rev-list --count $new..$b) ahead, branched from the rewritten eac96f8: $([ "$(git merge-base master $b)" = "$new" ] && echo yes || echo NO)"; done
# tip tree may differ from the old one in the two email files only:
git archive master | tar -x -C /tmp --one-top-level=newtip
git -C /home/cairo/.nixos archive master | tar -x -C /tmp --one-top-level=oldtip
diff -rq /tmp/oldtip /tmp/newtip      # expect exactly rclone.nix and git.nix
nix run nixpkgs#gitleaks -- detect --source . --log-opts=--all --redact=100 --no-banner    # expect: no leaks found
nix run nixpkgs#trufflehog -- git file://$PWD --no-verification | tail -3                  # expect only the known false positives (section 2.3 of the private audit, `docs/secrets-audit.md` in the archive)
```

### 6.4 GitHub and the machines

The point of no return is **making the new repo public** (6.5), not the push.

1. **Rename the old repo:** github.com/cqjro/nixos → Settings → General →
   Repository name → `nixos-archive`. Confirm it is **Private**.
   Then commit the audit report into it (from 6.2a), **before** the token swap in
   step 3 (the new token cannot push here) and before archiving it:
   ```bash
   git clone https://github.com/cqjro/nixos-archive.git ~/nixos-archive-private   # outside ~/.nixos
   install -D ~/private-backup/secrets-audit.md ~/nixos-archive-private/docs/secrets-audit.md
   git -C ~/nixos-archive-private add docs/secrets-audit.md
   git -C ~/nixos-archive-private commit -m "docs: secrets audit report (split from the public docs/secrets.md)"
   git -C ~/nixos-archive-private push origin HEAD      # the archive's default branch
   ```
   Agents read the report later through this local clone, granted per session
   with `/add-dir ~/nixos-archive-private`; never copy it into `~/.nixos`.
   Optionally then Settings → General → Danger Zone → *Archive this repository*
   (read-only, so nothing can be pushed to it).
2. **Create the new repo, empty:** `gh repo create cqjro/nixos --private`
   (no README, licence or gitignore; it must not be a fork or a template copy of
   the old repo, because forks share object storage with their parent and the old
   firmware would stay reachable by SHA).
3. **Replace the broad `gh` login with a fine-grained token** (requested by the
   secrets thread; detail in `docs/secrets.md` 4.1 and section 2.8 of the private audit). Do it **after** step
   2, because a repo named `cqjro/nixos` must exist again before a token can be
   scoped to it, and **before** making the repo public (6.5). Four Full access
   threads ran on 2026-10-29..31, so treat the old `gh` token and the Claude login
   as exposed.
   - github.com → Settings → Developer settings → Fine-grained tokens →
     Generate: *Repository access* **only `cqjro/nixos`** (the new repo);
     permissions **Contents: read and write**, **Pull requests: read and write**,
     **Metadata: read**; expiry 30-90 days. **One token per machine**:
     GOD-KILLER, and the `t3code` user on REDRUM.
   - Enter it without putting it on a command line or in chat:
     ```bash
     read -rs T; printf %s "$T" | gh auth login --with-token; unset T
     # REDRUM: sudo -u t3code -H bash -c 'read -rs T; printf %s "$T" | gh auth login --with-token'
     ```
   - Then revoke the old broad grant: github.com → Settings → Applications →
     Authorized OAuth Apps → *GitHub CLI* → Revoke, and log each machine in again
     with its own token. The steps after this one (the push in step 4) then run
     with the new token. Note that a token scoped to `cqjro/nixos` only makes `gh`
     fail on your other repositories; use a separate login for those.
4. **Push only what you intend, from the scratch clone** (no `--mirror`):
   ```bash
   cd /tmp/nixos-rewrite
   git remote add origin https://github.com/cqjro/nixos.git
   git push origin master 'refs/heads/workflow/*:refs/heads/workflow/*'
   ```
   Never add `nixos-archive` as a remote of this clone.
5. **Retire the old clone on every machine** (GOD-KILLER first, no T3 thread
   running):
   ```bash
   cd ~ && mv .nixos .nixos.pre-rewrite
   git -C ~/.nixos.pre-rewrite remote set-url origin https://github.com/cqjro/nixos-archive.git
   git clone https://github.com/cqjro/nixos.git ~/.nixos
   # carry over only ignored runtime files, never firmware (REDRUM):
   #   rsync -a ~/.nixos.pre-rewrite/modules/server/youtube/{config,token,client_secret}.json ~/.nixos/modules/server/youtube/
   cd ~/.nixos && git fetch origin && git branch --list -r 'origin/workflow/*'   # the six branches are here
   ```
   No patch export is needed: the branches were rewritten with `master` in 6.3
   and pushed in step 4, with their commits, order and authorship intact.
6. **T3:** the worktrees under `~/.t3/worktrees/.nixos/*` pointed at the old clone
   and are now broken; delete them (`rm -rf ~/.t3/worktrees/.nixos/*`) and let
   T3 create new ones from the pushed branches. Old threads lose their diffs and
   the 117 hidden `refs/t3/orchestration-v2/checkpoints/*` refs (they stay in
   `.nixos.pre-rewrite`). How T3 reacts to a project whose repo was replaced in
   place is **untested**; re-adding the project is the fallback. Existing thread
   *conversations* are T3's own data and are not part of the repo.
7. **REDRUM and LittleNix:** re-clone the same way when you next use them;
   REDRUM also replaces `/var/lib/t3code/nixos` if it is used. `config-sync` and
   `./rebuild.sh switch` fail on the old clone (unrelated histories) rather than
   doing damage; nothing pulls automatically any more.
8. **Clean up** once the new `~/.nixos` builds and you have everything you need:
   `rm -rf /tmp/nixos-rewrite ~/rewrite-emails /tmp/firmware-objects.txt /tmp/history-email-scrub.sh /tmp/oldtip /tmp/newtip ~/.nixos.pre-rewrite`.
   (`.nixos.pre-rewrite` holds the old history, including firmware; the private
   archive repo keeps a copy anyway.)

### 6.5 Making it public

Keep the new repo **private** until all of these hold; the flip cannot be taken
back (anything public can be cloned or archived immediately):

- the 6.3 checks passed and you looked at the secrets thread's findings
  (the private audit and `docs/secrets.md`; anything it says to rotate is rotated);
- the tripwire in 6.3 printed 0 and `docs/secrets-audit.md` is in no branch;
- you opened the new repo in a browser: branches are `master` + `workflow/*`,
  the repo is **not** marked "forked from", and `git log` shows only the
  `cqjro` noreply identity;
- the token swap (6.4 step 3) is done on every machine and the old *GitHub CLI*
  OAuth grant is revoked;
- GitHub account settings *Keep my email addresses private* and *Block command
  line pushes that expose my email* are on (per the secrets thread; not
  verified from here).

Then Settings → General → Danger Zone → Change visibility → Public.

### 6.6 After

- **Open the workflow PRs on the new repo.** `workflow/secrets` already contains
  `workflow/pr-rebuild-docs` (it was merged into it), so merge pr-rebuild-docs
  first or the PRs will show the same commits twice. **Merge the firmware branch
  before building REDRUM or LittleNix**: rewritten `master` still has the old
  `builtins.path` on `/home/cairo/.nixos/modules/hosts/REDRUM/firmware/brcm` (and
  LittleNix's repo-relative `./firmware/brcm`, untracked at the tip), so neither
  host evaluates from a clean clone until the firmware change is in. GOD-KILLER
  is unaffected.
- **Generations**: `rebuild.sh` commit subjects carry a generation number, not a
  hash, and the rewrite keeps those subjects. `system.configurationRevision` (the
  workflow/docs branch, `modules/essentials/config-revision.nix`) records a commit
  hash, so a generation built with it *before* the rewrite would record a hash
  that no longer exists in the new repo. None has been built yet.
- **`flake.lock`** does not pin this repo, so it is unaffected.
- Nix store copies of the flake source from the days the firmware was tracked
  (`/nix/store/*-source`) may contain the files; they are local and disappear on
  garbage collection once no generation references them.
- Remove nothing from `.gitignore`: it stays as the backstop.
- Tell thread 5 (secret-guard) to add the firmware filename patterns above to its
  path denylist; `Read`-denying `/var/lib/firmware-src` is optional (the files are
  not secret), but Bash `cat`/`strings` of them is unwanted.

### 6.7 What this cannot do

Copies made while the old repo was public (clones, third-party archives such as
Software Heritage, search-engine caches) are outside GitHub and cannot be
recalled by anything here; the owner reports no forks. The new public repo never
contains the firmware, which is the goal. GitHub Support is not needed for this
design because the old objects stay in a private repo.

### 6.8 After the rewrite: per-branch follow-ups

Handed over by the threads whose worktrees 6.4 deletes (T3 cannot move a thread
onto the new clone), so these steps belong to this runbook. Do them **after** the
new repo is pushed and the firmware PR is merged. Nothing here is run by the
firmware thread; the human runs or approves each step, and nothing is pushed or
opened as a PR until the human says so.

**Merge order (the firmware thread's suggestion):** firmware, then
`pr-rebuild-docs`, then `agent-security`, then `secrets` (it contains
`pr-rebuild-docs`, and its hooks must follow `agent-security`'s managed-settings
rule, below), then `notifications` and `schedules`. The `host.nix` and
`AGENTS.md` conflicts below are expected.

#### `workflow/pr-rebuild-docs` (from the workflow/docs thread)

State before the freeze: fully committed in `~/.nixos`, tip `f40408a`, nothing in
it touches firmware paths. The 6.3 rewrite carries it along and it needs nothing
before the freeze.

1. **New thread for the branch:** `t3_thread_launch` with
   `workspaceStrategy {type:"worktree", baseRef:"workflow/pr-rebuild-docs", branch:"workflow/pr-rebuild-docs", startFromOrigin:true}`
   (or `existing_worktree` if one exists). Sonnet, medium effort. Pass it steps 2 to 6.
2. `git merge origin/master` to bring in the merged firmware work. Conflicts are
   likely in `AGENTS.md`, `README.md`, the `machine.nix` firmware lines and
   `docs/agents/*`. Keep the firmware branch's versions of the firmware facts.
3. **Drop `--impure` from `rebuild.sh`**, everywhere it is passed (eval, build,
   test, dry, switch and `check`'s eval), and update the `AGENTS.md`/`README.md`
   lines that mention it.
4. **Verify:** `./rebuild.sh check GOD-KILLER REDRUM`, then
   `./rebuild.sh build GOD-KILLER` and `./rebuild.sh build REDRUM`. REDRUM needs
   the firmware imported into GOD-KILLER's store first (section 3); if it is
   missing, stop and tell the user.
5. **Review:** tier 1 `nix-reviewer`, then tier 2 `lockout-reviewer` (required,
   `rebuild.sh` and `start.sh` changed). Pass them the branch and the affected
   hosts, not the conversation.
6. **Ask the user, then push** (`./rebuild.sh push`), open the PR from
   `.github/pull_request_template.md`, and call `link_pull_request`.

PR body, listed as **untested** for the user to try: the interactive
`./rebuild.sh`; test/dry/revert; a real `switch`, including its new step that
fetches and fast-forwards `master` first (only covered in a temp repo so far);
`generations --target`; the start-todo skill's `t3_thread_launch`; `start.sh` at a
real login (it now only loads the SSH agent and no longer pulls); a REDRUM-on-REDRUM
build. After merge: `cd ~/.nixos && ./rebuild.sh switch GOD-KILLER`, then the user
switches REDRUM. Two rules from this branch appear in `AGENTS.md`: every reply
ends with a "Path to close" block, and nothing pulls `~/.nixos` automatically.

#### `workflow/agent-security` (from thread 4)

Three local commits on top of `eac96f8`, nothing pushed: `e001dab` (shared managed
Claude policy, strict sandbox, `claude-guard` hook), `3e4f782` (firmware
no-exfiltration rules), `e7c796b` (docs-thread handoff, `docs/agents/security.md`).
None contains firmware or secrets. **No re-apply is needed:** the 6.3 rewrite
carries all three (new SHAs). They touch `modules/home-manager/ai-tools/claude-code.nix`,
`modules/scripts/claude-guard.sh`, `modules/server/t3code.nix`,
`modules/hosts/host.nix`, `docs/agents/security.md` and one pointer line in
`AGENTS.md`. Do not run any check until the rewrite and branch recreation are done.
If steps 1, 2 or 6 differ from `docs/agents/security.md`, report it to the
`workflow/agent-security` lane; do not patch the policy from the firmware branch.

1. **Branch content:** `git log` on the recreated branch shows the three commits.
   `claude-guard --self-test` passes: build with
   `nix build .#nixosConfigurations.GOD-KILLER.config.environment.etc."claude-code/managed-settings.json".source`
   and run the guard from that closure, or `./rebuild.sh build GOD-KILLER` and
   `./rebuild.sh build REDRUM` then `claude-guard --self-test`. Both hosts build.
2. **Firmware rules vs the new layout.** Read (not run) on the branch: the
   `permissions.deny` Read rules in `claude-code.nix` already cover
   `//var/lib/firmware-src/**`, `//nix/store/*-brcm-firmware/**`,
   `//**/firmware/brcm/**`, `brcmfmac*`, `brcmbt*`, `firmware.tar*` and
   `brcm-firmware.gcroot`, and `fw_re` plus the self-test cases in
   `claude-guard.sh` include `cat /var/lib/firmware-src/...` and
   `git add -f ... firmware/brcm`. Confirm by running the self-test; both cases
   must be blocked. If anything under 6.x renames those paths, re-check.
3. **Merge conflicts.** `modules/hosts/host.nix` will conflict with the other
   threads (each adds module lines): keep all of them. The agent-security lines
   are `inputs.self.modules.nixos.claude-code-policy`, after `keyring` on
   GOD-KILLER and after `t3code` on REDRUM. For `AGENTS.md` take the docs thread's
   version and add the index row
   `| docs/agents/security.md | permissions, sandbox, the claude-guard hook, the security smoke test |`,
   and correct "Agent safety essentials" on four points: one managed policy from
   `claude-code.nix` covers both hosts; Full access no longer bypasses everything
   because ask rules are refused there; branch commits and `gh pr create` are
   allowed; Accept edits is the default for TODO threads.
4. **Secrets and notifications hooks.** `allowManagedHooksOnly = true` is set, so
   their hooks must be installed as
   `environment.etc."claude-code/managed-settings.d/50-secret-guard.json"` (secrets)
   and `60-notifications.json` (notifications); home-manager
   `programs.claude-code.settings.hooks` will not do it and the hooks silently
   never run. Notifications must also stop targeting the managed-settings block in
   `t3code.nix`, which was removed. Read on 2026-11-02: neither
   `workflow/secrets` nor `workflow/notifications` contains `managed-settings.d`
   yet, so both need that change; check the recreated `workflow/secrets` before
   its PR (the squash in 6.2a does not alter it).
5. **After merge and switch** (human): `./rebuild.sh switch GOD-KILLER`, and switch
   REDRUM on REDRUM itself. Then in a new thread check that
   `jq .permissions ~/.claude/settings.json` shows empty `allow`/`ask`/`deny`, and
   that `/etc/claude-code/managed-settings.json` exists on both hosts.
6. **Smoke test:** run the 22-step table in `docs/agents/security.md` once in an
   Accept edits thread and once in a Full access thread, and record which steps
   prompted (the agent cannot see approval cards). Still unverified: the installed
   `/etc` policy; `allowManagedHooksOnly`; how T3 shows the guard's "ask" prompts;
   everything on REDRUM (whether the sandbox starts for the `t3code` user, whether
   `GIT_CONFIG_*` identity reaches sandboxed commits, `journalctl` access via
   `systemd-journal`); Auto mode's classifier quota cost.
7. **REDRUM firmware access:** the `t3code` user gets no access to `/home` or
   `/var/lib/firmware-src`. After the switch, `sudo -u t3code test -r /var/lib/firmware-src`
   must fail.

#### Changes that landed on `master` while the branches were open (LearnHarness)

Recorded from the LearnHarness install thread (informational; nothing to do before
the freeze). On 2026-11-03 `master` gained two ordinary commits, already switched
on GOD-KILLER and pushed to `origin/master`: `65aa855` (a `TODO.md` item) and
`6cdc830` (`GOD-KILLER: 230 ... add LearnHarness AppImage`: new
`modules/home-manager/apps/learnharness.nix`, a pinned v0.4.1 AppImage via
`fetchurl` + `appimageTools.wrapType2` modelled on `xodus-nexus.nix`; one
`learnharness` line in `modules/hosts/GOD-KILLER/machine.nix`; the `TODO.md` item
rewritten into a smaller "LearnHarness registry row" follow-up). No firmware,
secrets, hostnames or keys are involved, so the rewrite carries them unchanged.
It is GOD-KILLER-only and does not affect REDRUM or LittleNix.

What this means for the runbook:

- **`master` is now 2 commits ahead of where every `workflow/*` branch was cut**
  (`eac96f8`). The 6.3 base check therefore compares with the rewritten `eac96f8`
  via filter-repo's commit map (rehearsed 2026-11-03 on a throwaway clone: all
  six branches "branched from the rewritten eac96f8: yes", `master` 2 ahead).
  The branches keep their old base; they pick up the two commits when merged.
- **Do the 6.3 clone after these commits.** They are on local `master` and
  `origin/master` now; a scratch clone started before 2026-11-03 must be redone.
  Any later `./rebuild.sh switch` adds another `master` commit (6.2 warns).
- **Conflicts:** a textual `git merge-tree` of the new `master` against all six
  branches is clean. `workflow/secrets` also edits `GOD-KILLER/machine.nix`
  (its `secret-guard` line is about 15 lines from the `learnharness` one); if it
  ever conflicts, keep **both** lines. The firmware `TODO.md` block does not
  overlap the LearnHarness item; keep both.

Follow-ups for **after `workflow/pr-rebuild-docs` (or `notifications`, which
merges it) lands**, because that branch moves the registry from `AGENTS.md` to
`docs/agents/upstream-registry.md` and renumbers it:

1. Add a LearnHarness row to `docs/agents/upstream-registry.md` **and** the
   README's "Pending upstream fixes" table, next free number (`xodus-nexus` is row
   6 there). Workaround: pinned AppImage (`fetchurl` + `appimageTools.wrapType2`)
   in `modules/home-manager/apps/learnharness.nix`. Blocked on: not in nixpkgs, no
   upstream flake or Nix expression (`github.com/amosblomqvist/learnharness`).
   Re-enable when: `pkgs.learnharness` or an upstream flake exists, then drop the pin.
2. Edit the `# TODO-remove:` comment in `learnharness.nix` to cite
   `docs/agents/upstream-registry.md row N` (the form the other branches apply to
   `xodus-nexus.nix`, `3d-printing.nix`, `nixdatifier.nix` and
   `patch-qidi-studio-ua.py`); it currently says the row is still to be added and
   points at `TODO.md`.
3. Delete the "LearnHarness registry row" item from `TODO.md` in that same change
   (remove, do not check off).

## 7. Handoffs to other threads

- **AGENTS.md / README.md (thread 1):** `--impure` is **no longer required** for
  any of the three hosts (pure `nix eval` of all three toplevels and
  `nix flake check --no-build` pass). Remove the "required because ... brcm-firmware"
  bullet from AGENTS.md (Quick commands) and README.md ("Notes" under the install
  steps) and drop `--impure` from the documented commands if `rebuild.sh` no
  longer needs it; `rebuild.sh` still passes it, which is harmless. Replace the
  `./firmware/brcm` example in AGENTS.md ("Prefer relative paths") and update the
  "Secrets and firmware are gitignored" gotcha and the REDRUM `t3code`
  absolute-`/home/cairo/.nixos/...`-firmware sentence: the firmware path is now
  the store, readable by every user. Add a pointer to `docs/firmware.md`.
  README fresh-install flow (clone, then `nixos-install --flake`) must import the
  firmware into the installer's store first (section 3, "Placing the files").
- **rebuild.sh (thread 1):** no change required. The firmware import is a one-time
  step per machine; if you want `rebuild.sh` to fail early, `nix build
  .#nixosConfigurations.HOST.config.hardware.firmware` is the cheap check.
- **Security (thread 4):** the `t3code` user needs no extra access; do not grant
  it read access to `/var/lib/firmware-src`.
- **Secrets (thread 5):** firmware filename patterns for the guard denylist;
  history scan during 6.3 (its extra paths and the email files are already in the 6.3 command; the audit split and squash are 6.2a).
