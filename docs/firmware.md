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
  `master` and `dendritic`. Section 6 is the runbook. Do it **before the first
  workflow PR is opened** (section 6.1).

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
   hold the files and cannot be recalled. Section 6.4 (GitHub Support) is
   therefore required, not optional, to clear cached views and orphaned objects.
2. **Binary caches**: none configured except the read-only Millennium cachix in
   `modules/system/games.nix`; nothing pushes. Keep it that way: never
   `nix copy` or `cachix push` firmware to a public cache.
3. **Every clone**: GOD-KILLER, REDRUM (`config-sync` pulls), LittleNix, T3
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
   - **From the REDRUM checkout's old location**: `sudo install -d -o cairo -g users /var/lib/firmware-src/REDRUM && mv ~/.nixos/modules/hosts/REDRUM/firmware/brcm /var/lib/firmware-src/REDRUM/brcm`.
   - **From the Mac itself**: re-extract with the t2linux `firmware.sh`. Output can
     differ by macOS version, so expect a hash `MISMATCH` and then re-pin.
2. `cd ~/.nixos && nix run .#t2-firmware-import -- REDRUM`. Expect `OK`.

Alternatively move the store path directly (verified path format; `nix copy` to
a remote store is **untested** from here): `nix copy --to ssh-ng://cairo@redrum /nix/store/prscpri4fy5x2gy488j3rag9awjv568x-brcm-firmware`.
The path is content-addressed, and REDRUM already lists `cairo` in
`nix.settings.trusted-users`. Add a GC root on the target afterwards (the
importer does this when pointed at the staging dir).

If the build says the firmware is missing, the message already names the hash and
these commands.

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
- Do not rewrite history, `git push --force` or contact GitHub Support: the
  runbook below is for the human.
- If a build fails with "The Apple Broadcom firmware ... is not in the Nix store",
  stop and tell the human which machine and host; do not work around it.

## 6. Runbook: scrub the firmware from git history (human only)

Nothing below has been executed. It follows GitHub's procedure
(<https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository>)
with `git-filter-repo >= 2.47` (the nixpkgs build supports
`--sensitive-data-removal`; checked). Firmware is not a credential, so
**nothing needs rotating**, but the rewrite is irreversible for everyone who
holds old hashes.

### 6.1 When it is safe (read first)

The tip of `master` already has no firmware, so the rewrite changes **only
hashes**; trees at the tip are identical. What matters is the pull-request refs:
GitHub keeps `refs/pull/N/head` for every PR, those cannot be force-pushed, and
each one that descends from the firmware commits pins the data until GitHub
Support clears it. As of 2026-11-01 `origin` has only `master` and `dendritic`
(no PR refs, no tags).

**Recommended order:**

1. Let the six workflow threads finish and **commit locally**; do not push them
   or open PRs yet.
2. **Merge nothing from them first.** Run this runbook now, while there are zero
   PRs.
3. Re-clone, re-create the workflow branches (6.5), push them and open the PRs
   against the rewritten `master`.

If you open and merge the workflow PRs first, every one of them adds a PR ref
that carries the old history and you must involve GitHub Support (6.4) even if
you would otherwise have skipped it. Rewriting later also invalidates every open
branch, worktree and PR on all machines at once.

Decided by the owner: `dendritic` (338 commits, tip `a54f8c4`) is obsolete (the
config already uses the dendritic pattern on `master`), so **delete it** instead
of rewriting it: `git push origin --delete dendritic` after the rewrite, and
never re-create it. The 6.3 mirror push would otherwise rewrite it too.

### 6.2 Prepare

```bash
# on GOD-KILLER, nothing running in ~/.nixos or T3 worktrees
nix shell nixpkgs#git-filter-repo nixpkgs#git

# 1. Make sure the firmware exists outside git on every machine (hash-checked):
nix run ~/.nixos#t2-firmware-import -- REDRUM        # expect OK
#    LittleNix: run the same on the LittleNix machine; if the files exist only in
#    git history, export them first:  git -C ~/.nixos archive 0181e6a hosts/LittleNix/firmware/brcm | tar -x -C /tmp/ln
#    then move them to /var/lib/firmware-src/LittleNix/brcm and import.
# 2. Identify ignored local files you must carry over to the new clones:
git -C ~/.nixos ls-files --others --ignored --exclude-standard
#    expect firmware/, .log/, modules/server/youtube/{config,token,client_secret}.json
#    (copy those by hand after re-cloning; do NOT copy firmware back into the repo)
# 3. Fresh clone, away from ~/.nixos and any worktree:
cd /tmp && git clone https://github.com/cqjro/nixos.git nixos-rewrite && cd nixos-rewrite
# 4. Record the blob ids that must disappear (for verification):
git rev-list --all --objects | grep -E ' (modules/)?hosts/(REDRUM|LittleNix)/firmware/' \
  | cut -d' ' -f1 | sort -u > /tmp/firmware-objects.txt
wc -l < /tmp/firmware-objects.txt        # expect ~187
# 5. Record the tip tree so you can prove the rewrite changed no file at the tip:
git rev-parse origin/master^{tree} > /tmp/tip-tree.txt
```

### 6.3 Rewrite and verify

```bash
git filter-repo --sensitive-data-removal --invert-paths \
  --path hosts/REDRUM/firmware --path hosts/LittleNix/firmware \
  --path modules/hosts/REDRUM/firmware --path modules/hosts/LittleNix/firmware
# --sensitive-data-removal re-fetches all refs from origin first, so no ref that
# holds the data is left behind. Note "First Changed Commit(s)" in the output.

# Verify: none of the recorded objects may exist, and no path may mention them
git cat-file --batch-check < /tmp/firmware-objects.txt | grep -vc missing   # expect 0
git rev-list --all --objects | grep -ci -E 'brcm|/firmware/'                 # expect 0
git count-objects -vH                                                        # size-pack should drop by ~25-30 MB
grep -c '^refs/pull/.*/head$' .git/filter-repo/changed-refs                  # expect 0 (PR refs)
test "$(git rev-parse master^{tree})" = "$(cat /tmp/tip-tree.txt)" && echo tip-tree-unchanged   # must print
```

Stop and discard `/tmp/nixos-rewrite` if the PR count is not 0 or the tip tree
differs. Optionally run `gitleaks detect --log-opts=--all` on this clone while
you are here (no credentials were found by file name in history, but the secrets
audit thread owns the real scan).

```bash
git remote add origin https://github.com/cqjro/nixos.git     # filter-repo removes origin
git push --force --mirror origin      # point of no return; rewrites every ref, then delete dendritic (6.1)
```

`refs/pull/*` rejections are expected and harmless when there are none; any other
rejected ref means branch protection, so disable it, retry, and re-enable.

### 6.4 GitHub Support (cached views, orphaned objects)

After a force push, the old commits are unreachable but GitHub keeps serving them
by SHA (for example `github.com/cqjro/nixos/commit/2412d99`) until server-side
garbage collection. Support only acts once every non-PR ref is clean and no fork
still has the data, and may decline "non-sensitive" data; unlicensed firmware is
not a credential, so **the outcome is theirs to decide (untested)**. Open a
ticket at <https://support.github.com/> with: owner/repo `cqjro/nixos`, number of
affected PRs (0 if you follow 6.1), the "First Changed Commit(s)" from the
filter-repo output, and that the data is third-party proprietary firmware. Ask
them to run garbage collection and clear cached views. If the repo was ever
public, check for forks first (GitHub cannot tell you who owns them) and ask
their owners to delete.

Then check from a signed-in browser that the old commit URLs 404 and the repo's
size dropped. Until Support confirms, the repo should stay private.

### 6.5 Re-clone every machine

Old hashes make every existing clone incompatible: a normal `git pull` fails
with unrelated histories, and **a merge or push from an old clone restores the
data**. Treat old clones as tainted; replace, do not repair. The same applies to
the T3 checkpoint refs.

Per machine (GOD-KILLER, REDRUM, LittleNix), with no T3 thread running on it:

```bash
cd ~ && mv .nixos .nixos.pre-rewrite
git clone https://github.com/cqjro/nixos.git ~/.nixos            # HTTPS: agents push via gh credentials
# carry over only ignored runtime files (never firmware):
#   rsync -a .nixos.pre-rewrite/modules/server/youtube/{config,token,client_secret}.json ~/.nixos/modules/server/youtube/   (REDRUM)
./rebuild.sh build "$(hostname)"                                  # sanity: should be empty output, exit 0
# once satisfied and the firmware is confirmed under /var/lib/firmware-src:
rm -rf ~/.nixos.pre-rewrite
```

- **REDRUM** also has the T3 agent clone `/var/lib/t3code/nixos` (if used) and
  `config-sync`/`start.sh` auto-pull: replace the clone the same way, or the
  next login's auto-pull will fail.
- **T3 worktrees** (`~/.t3/worktrees/.nixos/*`, one per thread) are bound to
  the old clone: `git worktree prune` is not enough because their object store is
  the old repo. Delete them after re-cloning and let T3 create new worktrees.
  Threads that were bound to a worktree lose their diffs/checkpoints (117
  `refs/t3/orchestration-v2/checkpoints/*` refs exist in the old clone and are
  not recreated). How T3 reacts to a project whose repo was replaced in place is
  **untested**; re-adding the project is the fallback.
- **Open branches / PRs.** Local-only branches (`workflow/*`) die with the old
  clone. Before step 6.2 either (A) export each: `git format-patch -o ~/patches/<branch> master..<branch>`,
  then recreate from the new `master` with `git switch -c <branch> && git am ~/patches/<branch>/*.patch`
  (the trees match at the tip, so patches apply cleanly), or (B) push the
  branches to `origin` *before* the rewrite so the mirror run rewrites them with
  `master` (only safe while no PR exists, 6.1). Do not `git merge` old branches
  into new `master`.
- **Generations**: commit messages from `rebuild.sh` carry a generation number,
  not a hash, so history stays meaningful. If `system.configurationRevision` is
  later adopted, revisions recorded before the rewrite will not resolve.
- **`flake.lock`** does not pin this repo, so it is unaffected.
- Nix store copies of the flake source from the days the firmware was tracked
  (`/nix/store/*-source`) may contain the files; they are local, not shared, and
  disappear on garbage collection once no generation references them.

### 6.6 After

- Remove nothing from `.gitignore`: it stays as the backstop.
- Tell thread 5 (secret-guard) to add the firmware filename patterns above to its
  path denylist and thread 4 that `Read`-denying `/var/lib/firmware-src` is
  optional (the files are not secret), but Bash `cat`/`strings` of them is
  unwanted.

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
  history scan during 6.3.
