# Notifications (agent reference)

Human setup, phone steps and the test procedure are in
[docs/notifications.md](../notifications.md); this is what an agent needs.

  `agent-notify` (`modules/scripts/agent-notify.sh`; NixOS fragment
  `agent-notifications` in `modules/home-manager/ai-tools/notifications.nix`, which feeds
  `claude-code-policy.hooks` because `allowManagedHooksOnly` ignores every other hook
  source; GOD-KILLER and REDRUM only).
  It is deterministic: no LLM, no polling, exit 0 always.
- `PermissionRequest` ranks approvals by command: `gh pr merge` and
  `./rebuild.sh switch|test` are priority 5 (approving the card **is** the
  action), `gh pr create`, `git push`/`rebuild.sh push`, `rebuild.sh dry|revert`
  and `sudo` are labelled at priority 4.
- Do not poll for PR state to notify: T3's `watch_pull_request` wakes the thread
  on checks, comments or conflicts.
- Scripts that need to notify (e.g. `rebuild.sh`) call
  `AGENT_NOTIFY_LABEL="Rebuild done" agent-notify send finished "MESSAGE"`
  (kinds `approval|finished|failed|info`; `info` is priority 2-3, no desktop popup, not dropped by quiet hours), falling back to `notify-send` when the
  command is absent.
- Never print or log the ntfy topic/token (`~/.config/agent-notify/`, treat as a
  secret; `Read`-deny it). Do not run `tailscale serve` for the optional ntfy
  server (`modules/server/ntfy.nix`); the human does.
- Whether the hooks fire under T3 is still untested; the evidence is
  `~/.local/state/agent-notify/events.log`.
