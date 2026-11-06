# T3 Code + Claude Code reference

Operational detail for agents running under T3 Code on GOD-KILLER and REDRUM.
The essentials are summarised in [AGENTS.md](../../AGENTS.md#agent-safety-essentials);
read this when touching pushes, pairing, or T3 on REDRUM.

The desktop (GOD-KILLER) runs agents through T3 Code, which drives Claude Code.
What an agent may do (permissions, the sandbox, the `claude-guard` hook, which
T3 mode to pick, the smoke test) is one managed policy for both hosts,
described in [security.md](security.md) — read it before assuming what an agent
may do.

- **Consent model.** See [security.md](security.md#t3-runtime-modes): Accept edits for
  TODO threads, Supervised for policy, secrets or networking work, and avoid
  Full access (`--permission-mode bypassPermissions
  --allow-dangerously-skip-permissions`: deny rules, the sandbox and the guard
  still hold, but every `ask` rule is refused). **Never set
  `permissions.disableBypassPermissionsMode`:** it contradicts T3's launch
  flags, so Full access threads fail with a provider error.
  `programs.claude-code.mutableSettings` merges `dynamic * static`, so a key
  dropped from Nix stays in the live `~/.claude/settings.json` — delete it
  there too (`jq 'del(.permissions.disableBypassPermissionsMode)'`). The
  home-manager fragment now writes empty `permissions` lists for exactly that
  reason.
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
  credential helper and git identity (`GIT_CONFIG_*` env) and the sandbox
  tools are declared in `t3code.nix`; the Claude policy is the same
  `claude-code-policy` fragment GOD-KILLER imports, so there is nothing to keep
  in step. Its logins (`sudo -u t3code -H claude` / `gh auth login`) are manual
  one-offs stored in `/var/lib/t3code`. The T2 firmware comes from a
  world-readable store path, so `t3code` needs no extra access to it. REDRUM has
  its own clone of the repo, owned by `t3code` in `/var/lib/t3code`, and a
  REDRUM build was tested there, so REDRUM threads are full repo threads (see
  [workflow.md](workflow.md#one-project-either-machine)). The clone is
  agent-writable: never point a privileged switch at it; the human switches
  from their own checkout.
  - **Phone tokens and the terminal.** The T3 terminal on GOD-KILLER gives a
    real tty (tested 2026-11-06: `tty && sudo -v` works), so the human can run
    `systemd-run --user --wait ./rebuild.sh switch GOD-KILLER` from the phone
    and type the sudo password there (the systemd-run wrapper keeps an app
    restart from interrupting the switch). That needs a token with terminal
    scope, which is as powerful as `cairo`: mint it only when needed and revoke
    it if the phone is lost.
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
  `--permission-mode <mode> --permission-prompt-tool stdio --add-dir <worktree>
  --add-dir ~/.t3/userdata/attachments --allowedTools "mcp__t3-code__*"`
  (visible in `journalctl`; mode mapping in [security.md](security.md#t3-runtime-modes)).
  A worktree thread gets no `--add-dir ~/.nixos`. The process does
  **not** inherit the login shell's `SSH_AUTH_SOCK`, which is why SSH pushes
  failed from agent threads (`ssh_askpass: exec(): No such file or directory`,
  `Permission denied (publickey)`) and why pushes now go over HTTPS (see "Git pushes" above).

## Permissions smoke test

Superseded by the smoke test in [security.md](security.md#smoke-test-re-runnable), which
matches the managed policy. The 2026-10-30 run (in git history) predates it;
its lasting results are that `sudo -n true` needs a password (no `NOPASSWD`),
that `git push` over HTTPS works through the gh credential helper, and that
Full access threads skipped every prompt before the guard refused `ask` rules
under bypass.
