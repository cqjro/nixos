# T2 Wi-Fi/Bluetooth firmware

Covers: what the `brcm` firmware is and whether it may go to GitHub or agents,
how the config consumes it without it being in git, which machine can build
what, and a short history note on how it was scrubbed from git history.

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
- They **were in git history** (both REDRUM's and LittleNix's sets) of the old
  repo. That repo is now the private `cqjro/nixos-archive`; the history was
  rewritten once into a new `cqjro/nixos` (public since 2026-11-05), which never
  contains the firmware (section 6).

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
   (section 6). That cannot recall copies made while it was public (section 6,
   "What still matters from it").
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
  `/var/lib/firmware-src[/<host>]` (0750, `cairo:users`, so the `t3code` agent user cannot list them; the store copy that builds use is world-readable). The same file exports
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
     old `~/.nixos` is replaced by the re-clone anyway (section 6).
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
- Do not rewrite history, `git push --force` or touch the archive repo: that is
  for the human.
- If a build fails with "The Apple Broadcom firmware ... is not in the Nix store",
  stop and tell the human which machine and host; do not work around it.

## 6. History: how the repo was published without the firmware

**Done 2026-11-02 to 2026-11-05.** `cqjro/nixos` has been public since
2026-11-05 and its history contains no firmware. The step-by-step runbook (rewrite
in a scratch clone, GitHub steps, per-branch follow-ups) was removed from this
file once it had run; it is in git history, for example
`git show 23acd2e:docs/firmware.md`.

What was decided and done:

- **Decision (owner, 2026-11-02):** make the repo public again without the
  firmware, and keep the old repo **private forever** as an archive, so nothing is
  force-pushed or purged on GitHub.
- The old repo was renamed `cqjro/nixos-archive` (private, never modified again).
  The LittleNix firmware lives only there (commit `0181e6a`).
- A scratch clone was rewritten **once** with `git filter-repo`: firmware, the
  secrets thread's extra paths and personal emails removed together, with the six
  `workflow/*` branches rewritten alongside `master`. A new, empty `cqjro/nixos`
  (same name, so every URL stayed valid) received only `master` and those
  branches.
- The firmware moved out of the repo: pinned by hash in each host's `machine.nix`
  and found through the Nix store (sections 3 and 4).
- **Rollout (owner-run, as recorded in the TODO tracker at the time):** the PR
  chain (#1 to #9) was merged, GOD-KILLER (generation 233) and REDRUM (generation
  37) switched on the new repo, and the 24-step security smoke test of
  `docs/agents/security.md` passed in Accept edits and Full access. The generation
  to commit mapping is `./rebuild.sh generations`.

How it was checked before and after the flip (owner-run scans on fresh clones on
2026-11-05, plus an unauthenticated clone by the firmware thread; the output was
pasted into that thread, not stored in the repo):
firmware paths and blob extensions in history 0 and 0; the secrets thread's
tripwire string 0; `secrets-audit` in no path; every author and committer address
a GitHub noreply address; gitleaks "no leaks found"; trufflehog 5 unverified
findings, all false positives (four are the stock NixOS comment
`networking.proxy.default = "http://user:password@proxy:port/"` in the three
hosts' initial `configuration.nix`, one is a `narHash` in `flake.lock`). The
rehearsal on 2026-11-02 found 187 firmware objects and left 0.

What still matters from it:

- **Old clones are tainted.** An old clone's `origin` points at the new repo. A
  `pull` fails with unrelated histories, but **a force push from an old clone would
  put the firmware back**. Replace old clones and worktrees, never repair them. A
  clone kept as a local archive needs
  `git remote set-url origin https://github.com/cqjro/nixos-archive.git`.
- **What this cannot do:** copies made while the old repo was public (clones, third
  party archives such as Software Heritage, search-engine caches) cannot be recalled
  by anything here; the owner reports no forks. The new repo never contains the
  firmware.
- Nix store copies of the flake source from the days the firmware was tracked
  (`/nix/store/*-source`) may still contain it; they are local and disappear on
  garbage collection once no generation references them.
- `.gitignore` keeps its firmware patterns as the backstop.

### REDRUM after the move

REDRUM is switched on the new repo (generation 37). What may still be open there,
run as `cairo` on REDRUM:

1. **The `t3code` user gets its own token** (agents on REDRUM have their own
   login, stored in `/var/lib/t3code`). On github.com create a fine-grained token
   for **only `cqjro/nixos`** with Contents and Pull requests read and write (plus
   Issues if scheduled checks should file issues from REDRUM), 30-90 days. Then:
   ```bash
   sudo -u t3code -H bash -c 'read -rs T; printf %s "$T" | gh auth login --with-token; unset T'
   sudo -u t3code -H gh repo view cqjro/nixos --json name --jq .name
   ```
   Expect `nixos`. If a clone for T3 exists at `/var/lib/t3code/nixos`:
   `sudo -u t3code -H sh -c 'cd /var/lib/t3code && mv nixos nixos.pre-rewrite && git clone https://github.com/cqjro/nixos.git nixos'`.
2. **Check** that the `t3code` user cannot read the firmware staging directory
   (agent-security check 7): `sudo -u t3code -H ls /var/lib/firmware-src` should
   fail with "Permission denied".
3. **Clean up** the old clone if it is still there: `rm -rf ~/.nixos.pre-rewrite`
   (the firmware now lives in `/var/lib/firmware-src` and the store).

LittleNix stays parked ("LittleNix (parked)" above); re-clone it the same way if
you ever use it.
