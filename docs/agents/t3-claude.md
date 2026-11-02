# T3 Code + Claude Code reference

Operational detail for agents running under T3 Code on GOD-KILLER and REDRUM.
The essentials are summarised in [AGENTS.md](../../AGENTS.md#agent-safety-essentials);
read this when touching permissions, pushes, pairing, or T3 on REDRUM.

The desktop (GOD-KILLER) runs agents through T3 Code, which drives Claude Code.
Policy lives in `modules/home-manager/ai-tools/claude-code.nix`
(`programs.claude-code.settings.permissions`, merged into a writable
`~/.claude/settings.json`) — read it before assuming what an agent may do.

- **Consent model.** Threads should run **Supervised** (set in T3: Settings →
  Threads → New threads → Permissions). **Supervised is the only safeguard:**
  T3 launches Full access threads with
  `--permission-mode bypassPermissions --allow-dangerously-skip-permissions`, and
  a Full access thread ran `git push` and `sudo -n true` with **no prompt**
  (verified 2026-10-30; Supervised, Accept edits and Auto all prompted). Whether
  `deny` rules still hold under bypass is untested — do not rely on them there.
  **Never set `permissions.disableBypassPermissionsMode`:** it contradicts T3's
  launch flags, so Full access threads fail with a provider error, and it
  protected nothing anyway. `programs.claude-code.mutableSettings` merges
  `dynamic * static`, so dropping a key from Nix does **not** remove it from the
  live `~/.claude/settings.json` — delete it there too
  (`jq 'del(.permissions.disableBypassPermissionsMode)'`).
  `blockReadsOutsideWorkingDirectories` makes
  reads outside the project (including read-only Bash like `cat`/`ls`) prompt,
  like opencode's `external_directory`; grant a directory with `/add-dir`. The
  agent-side tool result can be a plain "blocked … `/add-dir`" error (it does
  not wait for the card), so re-issue the call after the human grants access.
  Secrets (`~/.ssh`, `~/.config/gh`, `~/.t3/userdata/secrets`, `*.env`,
  `token.json`, `client_secret.json`) are `Read`-denied. Those rules cover the
  Read/Grep/Glob tools only: there is **no Bash-level deny for `~/.ssh`**, so
  `cat ~/.ssh/…` is stopped by `blockReadsOutsideWorkingDirectories` and your
  approval, not by a `deny` rule.
- **Git pushes use gh credentials over HTTPS.** `modules/home-manager/ai-tools/github-cli.nix`
  makes `gh` git's credential helper (`git_protocol = "https"`), so an approved
  `git push` works without an ssh-agent or any access to `~/.ssh`. The `origin`
  remote must be `https://github.com/cqjro/nixos.git` (set once with
  `git remote set-url`; it lives in `.git/config`, not Nix). The token sits in
  `~/.config/gh/hosts.yml` (`Read`-denied); `deny` rules also block
  `gh auth token|status <args>|refresh|login|logout|switch`, `git credential*` and
  `*hosts.yml*` in Bash. These globs are best-effort — a push still runs with
  your token once approved, so keep `git push *` and `gh api *` as `ask` rules.
- **Multi-machine T3.** Each machine runs its own T3 server; clients (GOD-KILLER
  app, phone browser) pair to several over Tailscale. REDRUM's server is
  `modules/server/t3code.nix` (`127.0.0.1:8088`, published by the root oneshot
  `t3code-tailscale-serve` via `tailscale serve`), with **no Cloudflare tunnel**.
  Pairing steps are in the README ("T3 Code on REDRUM"). Pairing scopes default
  to terminal + filesystem write, so a paired device is as powerful as the
  server's user — keep phone tokens narrow. Port 8086 is the ABT sidecar; do not
  reuse it. The REDRUM agent runs as the `t3code` system user, which home-manager
  never reaches: its tools (`claude`, `gh`, `git`, `bash`, `nix`), the `gh` git
  credential helper (`GIT_CONFIG_*` env) and the Claude policy
  (`/etc/claude-code/managed-settings.json`) are all declared in `t3code.nix`,
  and its logins (`sudo -u t3code -H claude` / `gh auth login`) are manual
  one-offs stored in `/var/lib/t3code`. Keep that policy in step with
  `ai-tools/claude-code.nix` when either changes. The T2 firmware comes from a
  world-readable store path, so `t3code` needs no extra access to it. What still
  keeps REDRUM agents to host troubleshooting is the missing `t3code`-readable
  checkout of the repo; until it exists, flake builds stay on GOD-KILLER (see
  [workflow.md](workflow.md)).
  Operational facts (full detail in the README's "T3 Code on REDRUM"):
  - Client and server versions must match ("This client requires a newer
    server"). REDRUM's pinned nixpkgs ships an older t3code, so `t3code.nix`
    takes the package from the main `nixpkgs` input (`# TODO-remove:`, listed in
    `T2-PIN.md`); after `nix flake update nixpkgs`, both machines need a switch.
  - `t3 pair` prints a `http://127.0.0.1:8088/…` link (the server binds
    loopback); the host must be rewritten to `https://redrum.<tailnet>.ts.net`
    (no trailing dot — `.Self.DNSName` has one). Tokens are single-use, 5 min.
    Do not use `t3 pair --tailscale` (t3code user lacks the rights, clashes
    with `t3code-tailscale-serve` on :443).
  - GOD-KILLER's backend (`127.0.0.1:3773`) is published for phones with
    `sudo tailscale serve --bg --https=443 http://127.0.0.1:3773`, run by the
    human. The app's Tailscale HTTPS toggle fails silently without Tailscale
    operator rights; **do not set `tailscale set --operator`** for agents'
    convenience — it lets anything running as `cairo` (agents included) change
    Tailscale settings without a password. Agents should never run
    `tailscale serve`/`set` themselves; it exposes a service on the tailnet.
  - The desktop app stores saved connections in the system keyring; "Desktop
    secure storage is unavailable" = locked keyring (see the Xodus gotcha:
    `keyring` fragments, password login required).
- **How T3 launches Claude.** Via `systemd-run` with
  `--permission-mode default --add-dir ~/.nixos --add-dir ~/.t3/userdata/attachments
  --allowedTools "mcp__t3-code__*"` (visible in `journalctl`). The process does
  **not** inherit the login shell's `SSH_AUTH_SOCK`, which is why SSH pushes
  failed from agent threads (`ssh_askpass: exec(): No such file or directory`,
  `Permission denied (publickey)`) and why pushes now go over HTTPS (see "Git pushes" above).

## Permissions smoke test (verified 2026-10-30, GOD-KILLER)

Run in a fresh **Supervised** thread; the agent edits nothing and the human
approves/denies prompts. **The agent cannot see the approval UI**, so "the call
returned output" does not prove "no prompt appeared" — the human must record
which calls prompted (an early run of this test mislabelled prompted steps as
gaps for exactly that reason).

| Step | Expected | Verified result |
| --- | --- | --- |
| Read outside the project (`/etc/hostname`), Bash `jq` on `~/.claude/settings.json` | prompt / directory-access card | Read returned a "blocked, `/add-dir`" error; Bash ran after approval and showed `theme dark`, `bypass "disable"`, `blockReads true`, allow 28 / ask 11 / deny 15 |
| mcp-nixos `nix` + `nix_versions` | no prompt (allow-listed) | works; channels: 25.11, 26.05 (= stable/beta), unstable |
| `journalctl`, `systemctl is-active`, `nixos-rebuild list-generations`, `gh auth status`, `gh issue view` | no prompt | ran; `NixOS/nixos-hardware#2027` was still OPEN (registry row 1) |
| `Read` of `~/.ssh/**`, `~/.config/gh/**` | denied, no prompt | denied |
| Bash `cat ~/.ssh/known_hosts` | not allowed | denied (no Bash-level deny rule exists — see consent model) |
| `git push`, `sudo -n true`, `gh pr create --help` | prompt | prompted; `sudo -n true` → "a password is required" (no `NOPASSWD`) |
| `./rebuild.sh build GOD-KILLER` | exit 0, nothing staged on a clean tree | exit 0, empty output, tree stayed clean |
| `./rebuild.sh switch GOD-KILLER -m …` | ask rule, then GUI sudo askpass | both appeared; clean tree → no commit, no push |
| `git push origin master` over HTTPS | prompt, then success | succeeded via the gh credential helper (after switching `origin` to HTTPS) |
| `sudo -n true`, `git push --dry-run`, `git push` in a **Full access** thread | prompt (expected while `disableBypassPermissionsMode` was set; since removed, as it made Full access threads error) | **no prompts** — all three ran silently; launch flags are `--permission-mode bypassPermissions --allow-dangerously-skip-permissions`. Supervised / Accept edits / Auto all prompted |
