# Agent notifications (approval needed / thread finished / run failed)

Goal: know on **desktop and phone** when a T3 Code thread needs an approval,
finishes, or fails, and **which machine and thread** is asking.

Status legend: **verified** = I ran it; **docs** = from upstream docs/issues,
not exercised here; **untested** = needs the human (marked in the test
procedure).

## 1. What T3 Code provides natively

| Surface | What exists | Status |
| --- | --- | --- |
| Native mobile app (iOS/Android) | Push on thread **phase change**: waiting for approval, waiting for input, completed, failed. Sent through T3's relay to APNs/FCM; title = thread title + status + project; tapping deep-links to the thread. Settings toggles named `notifyOnApproval` / `notifyOnCompletion`. Per-type toggles beyond that, per-thread mute and rate limits are *proposals*, not shipped. | docs ([discussion 19500](https://github.com/pingdotgg/t3code/discussions/19500)) |
| Desktop app | Opt-in native OS notifications and sounds shipped on `main` ([discussion 7046](https://github.com/pingdotgg/t3code/discussions/7046): "Resolved by #11481"); completion notification names the thread and opens it on click; waits for the whole run, not subagents. Linux behaviour and setting location not stated. | docs, **untested** |
| Browser / PWA push | **Not documented anywhere.** The remote-access docs mention a *mobile app* (Settings → Environments, QR pairing), not a PWA, and say nothing about web push or notification permission. Assume the phone gets push only via the native app, not a browser tab. | docs (absence) |
| Tailscale HTTPS origin | Documented for pairing (`https://machine.tailnet.ts.net/`). Whether a browser grants notification permission on it is irrelevant until web push exists. | docs |
| In-app status | Sidebar thread status, `pendingRequestCount`; agents see it via `t3_thread_list/read` and `t3_pending_request_list`. | verified (field present in `t3_thread_read`) |

Limits of the native path: fixed text, no Focus-mode break-through (relay sets
no interruption level), and no control over priority or quiet hours. That is
the gap the hook fallback fills. **Run both** at first; the hook output carries
host + worktree + branch, which the native text lacks.

### Please check in the T3 UI (I cannot see it)

1. Desktop app → Settings: is there any notifications / sounds section? What are
   the toggles called, and are they off by default?
2. Phone app → Settings: the same, and is `notifyOnApproval` /
   `notifyOnCompletion` there? Does the phone app need to be paired to *each*
   machine (GOD-KILLER and REDRUM) separately to get pushes from each?
3. Does the notification text say which machine (environment) the thread is on?

## 2. Hook fallback (`agent-notify`)

`modules/scripts/agent-notify.sh`, packaged and wired by
`modules/home-manager/ai-tools/notifications.nix`. A deterministic bash script
(no LLM, no tokens spent) run by Claude Code hooks:

| Hook | Becomes | ntfy priority | Desktop urgency |
| --- | --- | --- | --- |
| `Notification` `permission_prompt` / `elicitation_dialog` / `agent_needs_input` | Approval needed | 4 (high) | critical |
| `Stop` | Thread finished (skipped if `stop_hook_active`) | 3 (default) | normal |
| `StopFailure` (rate limit, overloaded, auth, billing, …) | Run failed | 4 (high) | normal |
| `Notification` `idle_prompt` | dropped (would duplicate the Stop push) | – | – |
| `SubagentStop` | not registered (T3 itself waits for the whole run) | – | – |
| `PermissionRequest` | Approval needed, ranked by the command (below) | 4 or 5 | critical |

Title: `HOST - worktree (branch)`, e.g. `GOD-KILLER - workflow-notifications
(workflow/notifications)`. The worktree directory and branch are the closest
thing a hook has to a "thread name" (`todo/<slug>` branches make this readable).
It is the hook's `cwd`, so threads on `master` show `nixos (master)`.

Delivery: `notify-send` on GOD-KILLER (falls back to
`/run/user/UID/bus` when `systemd-run` did not pass the session bus) and an
ntfy POST when `~/.config/agent-notify/topic` exists. The topic and token go to
curl through stdin config, so they never appear in `ps`.

**Privacy:** completion pushes carry only "Thread finished" unless you
`touch ~/.config/agent-notify/include-text`, because the agent's last message
would otherwise leave the machine (on ntfy.sh, via a third party). Approval
text (`Claude needs your permission to use Bash`) is sent as-is.

### Approvals that matter most

`PermissionRequest` hands the script the actual command, so it can rank:

| Command contains | Heading | Priority |
| --- | --- | --- |
| `gh pr merge` | MERGE approval (approving the card **is** the merge) | 5 |
| `rebuild.sh switch` / `nixos-rebuild switch` / `rebuild.sh test` | Activate-system approval | 5 |
| `gh pr create` | Open-PR approval | 4 |
| `git push` / `rebuild.sh push` | Push approval | 4 |
| `rebuild.sh dry` / `revert` | Rebuild approval | 4 |
| `sudo ` | sudo approval | 4 |

The generic `Notification:permission_prompt` stays registered as a fallback
(waits 2 s so the command-aware one wins the dedupe); if `PermissionRequest`
does not fire under T3 you still get an unranked approval push.

PR babysitting needs no notifications from here: T3's `watch_pull_request`
wakes the thread on checks, comments or conflicts.

### Dedupe and quiet hours

* **Dedupe:** the same `(session, kind)` inside 30 s (`AGENT_NOTIFY_DEDUPE_SECS`)
  is one notification; so `Notification` + `PermissionRequest` for one prompt
  collapse, and a Stop that re-fires is ignored. This does **not** dedupe
  against T3's own push; the combined volume is the reason to pick one source
  once you know which works (section 6).
* **Quiet hours:** `~/.config/agent-notify/quiet-hours` containing
  `22:00-07:00` (wraps midnight). During the window completions are dropped,
  approvals/failures are still sent but at priority 3 with no desktop popup (a
  blocked agent should not be invisible). For stronger phone-side control use
  the ntfy app's own per-topic DND/priority settings.
* **Evidence log:** every decision, sent or not, is appended to
  `~/.local/state/agent-notify/events.log` (rotates at 200 KB). `touch
  ~/.config/agent-notify/debug` additionally dumps raw hook payloads to
  `payloads.jsonl` (this is how to learn the exact `StopFailure` field name, see
  below).

### Do the hooks fire under T3? (partly known, partly untested)

* Docs: hooks run for Agent SDK sessions, and the env var
  `CLAUDE_CODE_DISABLE_PERMISSION_PROMPT_NOTIFY_HOOKS` ("turn off
  `permission_prompt` notifications in Agent SDK-hosted sessions") implies
  `Notification:permission_prompt` **is** emitted when an SDK host such as T3
  handles the prompt. T3 answers approvals through its own UI, so this is the
  main thing to test.
* `Stop` and `StopFailure` are generic turn-end events and should fire in every
  runtime mode. `StopFailure` payload field names were not visible in the docs I
  could read; the script tries `error_type`, `error`, `reason` — confirm with
  the debug dump.
* Only **Supervised** (`default` permission mode) threads prompt at all. In
  Full access (`bypassPermissions`) there is nothing to ask, so no approval
  notification will ever exist; completion/failure still work. In Auto the
  classifier may auto-approve and only prompt on escalation.
* Settings must be present when the session starts; existing threads need a
  restart after a rebuild.

**All of that is untested.** Run test procedure 6.2 before trusting it.

## 3. Alternative without hooks: poll thread status (assessment, not built)

Threads expose status (`running`, waiting on `pendingRequestCount > 0`,
`completed`, `failed`) through the T3 MCP tools
(`t3_thread_list`, `t3_pending_request_list`). Those tools exist only inside an
agent session, so a poller would be an LLM thread polling — expensive and
self-defeating on the Pro plan. A deterministic poller needs T3's own HTTP/WS
API with a paired bearer token; I found **no documented stable public API** for
that, and a token with scopes is exactly the "paired device as powerful as the
server's user" risk in AGENTS.md. A narrow
`--scope orchestration:read` token could work, but this is
unverified. **Recommendation:** do not build a watcher. Use native push plus
hooks. Revisit only if both prove unreliable. (Pairing a scoped read token and
`curl`ing the server's thread list would be the first experiment; do it as a
human step, agents must not mint tokens.)

A cheaper complement: a systemd timer that notifies when a scheduled-task thread
produced no `events.log` line by its expected time ("dead man's switch"). That
belongs with thread 3's schedules.

## 4. Setup

### Choose a transport

| Option | Needs | Trade-off |
| --- | --- | --- |
| **ntfy.sh + private topic** (default) | an unguessable topic string | Zero infrastructure, works from anywhere, instant push on iOS and Android. The topic *is* the credential: anyone who knows it can read and publish. Messages transit a third party, hence the privacy note above. |
| Self-hosted on REDRUM | `modules/server/ntfy.nix` (optional, **not** in `host.nix`) + a human-run `tailscale serve` | Messages stay on your network; phone must be on Tailscale; iOS still pings ntfy.sh (empty poll request) for instant push. More to maintain, and REDRUM being down silences GOD-KILLER's phone alerts. |

I recommend starting with ntfy.sh, and moving to self-hosting only if you do not
want agent output (even just titles) transiting a third party. **Your call**,
nothing is enabled yet.

### Create the topic (human, once per machine)

The topic is a secret; it lives outside the repo (thread 5 owns secrets
tooling, and this should move to its mechanism once chosen).

```bash
# GOD-KILLER, as cairo
install -d -m 700 ~/.config/agent-notify
umask 077
head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32 > ~/.config/agent-notify/topic
# REDRUM, for the t3code user (same or different topic; one topic is simplest)
sudo install -d -m 700 -o t3code -g t3code /var/lib/t3code/.config/agent-notify
sudo install -m 600 -o t3code -g t3code ~/.config/agent-notify/topic /var/lib/t3code/.config/agent-notify/topic
```

Optional: `echo 22:00-07:00 > ~/.config/agent-notify/quiet-hours`; for a
self-hosted server `echo https://redrum.<tailnet>.ts.net:8443 >
~/.config/agent-notify/server` and, with auth, a `token` file. The agents' Read
deny rules do not yet cover `~/.config/agent-notify/` (thread 4/5 handoff:
add `Read(~/.config/agent-notify/**)`).

### Wire it into the hosts (not done on this branch)

GOD-KILLER: add `agent-notifications` to the `imports` list in
`modules/hosts/GOD-KILLER/machine.nix` (`with inputs.self.modules.homeManager`).
It merges hooks into `programs.claude-code.settings` without touching
`claude-code.nix` (verified by evaluating GOD-KILLER with the fragment added:
hooks present, the 28 allow rules intact).

REDRUM (handoff to thread 4, who owns `t3code.nix` and the managed settings):

1. Add `inputs.self.modules.nixos."agent-notifications"` to the REDRUM list in
   `modules/hosts/host.nix`.
2. In `t3code.nix`'s `managed-settings.json` attrset add
   `hooks = config.agentNotifications.hooks;` (read-only option the fragment
   defines). Managed hooks run alongside user hooks; if thread 4 ever sets
   `allowManagedHooksOnly`, these keep working, user hooks would not.
3. The t3code unit already sets `HOME` and `XDG_CONFIG_HOME` to
   `/var/lib/t3code`, so the config dir above is found without further env.
   `notify-send` is absent on REDRUM by design (headless): only ntfy is used.
   Verified: REDRUM's toplevel evaluates with the fragment.

### Optional self-hosted ntfy (REDRUM)

`modules/server/ntfy.nix` follows the "Creating a server module" rules: binds
`127.0.0.1:8089` (free: ABT 8086, 8087 reserved, t3code 8088), runs as the
module's own `ntfy-sh` user, no Cloudflare tunnel, `auth-default-access =
deny-all`. Not imported anywhere until you approve. To adopt it:

1. Add `inputs.self.modules.nixos.ntfy` to REDRUM in `host.nix`; set the real
   `base-url`.
2. Rebuild REDRUM (you switch it), then create access:
   `sudo -u ntfy-sh ntfy user add --role=admin cairo`,
   `sudo -u ntfy-sh ntfy token add cairo` (use the token as the `token` file).
3. Publish on the tailnet yourself: `sudo tailscale serve --bg --https=8443
   http://127.0.0.1:8089` (agents never run this).
4. Add the README port-table row and an AGENTS.md mention (thread 1 handoff).

Unverified: `nix eval` of the REDRUM toplevel with the module passes, but
runtime behaviour (ntfy-sh state dir, auth db, iOS upstream relay) is untested.

## 5. Phone setup

1. **T3 native app:** install, pair to each machine (Settings → Environments →
   scan QR / paste pairing URL; use a *narrow* scope, see AGENTS.md), enable the
   notification toggles, allow OS notifications. Because the native push
   goes through T3's relay, each environment must be paired.
2. **ntfy app** (Play Store / F-Droid / App Store): add subscription → topic
   from `cat ~/.config/agent-notify/topic` (use a QR from `qrencode` if you
   like; avoid pasting it into chat). For a self-hosted server set it as the
   default server and log in with your user.
3. **Test the topic:**
   `curl -H 'Title: test' -H 'Priority: 4' -d 'hello' "https://ntfy.sh/$(cat ~/.config/agent-notify/topic)"`
4. **Android:** disable battery optimisation for both apps (Settings → Apps →
   ntfy → Battery → Unrestricted). ntfy's default ("Instant delivery" with
   FCM) works without that for ntfy.sh; for self-hosted it holds a foreground
   service, so exempting it matters. In the ntfy app, make the "high" priority
   channel play sound / bypass DND if you want approvals to ring through.
5. **iOS:** notifications are push-only (APNs). Enable Time-Sensitive
   notifications for ntfy (Settings → Notifications → ntfy) so priority-4 can
   break through Focus; T3's relay sets no interruption level, so it will not.
6. **PWA:** not a notification path for T3 (see section 1). Installing T3 as a
   PWA gives a home-screen shortcut only.
7. Tailscale must be connected on the phone for self-hosted ntfy and for the
   T3 connection, but **not** for ntfy.sh pushes.

## 6. Test procedure (you run it; tick each on both devices)

Setup: `agent-notifications` imported on GOD-KILLER and switched, topic file
created, ntfy app subscribed.

**6.1 Script alone (no T3).** On GOD-KILLER:
`agent-notify test approval`, `agent-notify test finished`,
`agent-notify test failed`. Expect desktop popup + phone push each; titles read
`GOD-KILLER - <dir> (<branch>)`; approval and failed are high priority.
Check `~/.local/state/agent-notify/events.log`. (Desktop popup of the first run
was seen working during development; phone path verified only against a local
HTTP listener, not a real ntfy server.)

**6.2 Hooks under T3** (start a **new Supervised** thread after the switch).
`touch ~/.config/agent-notify/debug` first.
1. *Approval:* ask the agent to run `git push --dry-run origin HEAD` (an `ask`
   rule). Do not answer for ~10 s. Record: did T3's own notification fire? did
   the hook one? Look for `type=permission_prompt` in `events.log`. If the hook
   line is absent, add `PermissionRequest` in `notifications.nix` (comment
   there) and retest; if still absent, rely on T3's native push for approvals.
2. *Completion:* a trivial prompt ("say hi"). Expect `kind=finished`.
3. *Failure:* hard to trigger on purpose. Cheapest: in a shell, run `claude -p hi --model nonexistent` (a `model_not_found` StopFailure) with the hook active, then read `payloads.jsonl` for the real field names; otherwise wait for the next rate limit.
4. *Full access:* repeat 2 in a Full access thread; expect completion only.
5. Do the same from a thread on REDRUM's T3 (after thread 4 wires the managed
   hook): approval, completion; the title must say `REDRUM`.
6. *Dedupe/quiet:* send two completions <30 s apart (one push); set
   `quiet-hours` to cover now, finish a thread (no push), trigger an approval
   (push, priority 3).

Report which of T3-native vs hook delivered each event; then keep one source
per event type (or keep both, accepting duplicates).

## 7. Handoffs

* **Thread 1 (AGENTS.md/README):** add a short "Notifications" bullet to the
  agent workflow section pointing here; list ntfy under the REDRUM port table
  only if the optional module is adopted (port 8089); mention
  `agent-notifications` among the `ai-tools` fragments.
* **Thread 4 (permissions):** wire `config.agentNotifications.hooks` into the
  managed settings (above); add `Read(~/.config/agent-notify/**)` to the deny
  list; if sandboxing is enabled, allow network to `ntfy.sh` for the hook (hooks
  are run by Claude Code, but check whether they inherit the sandbox) and write
  access to `~/.local/state/agent-notify`.
* **Thread 5 (secrets):** the ntfy topic/token are secrets of the
  "unguessable URL" kind; adopt whatever file-credential mechanism you choose.
* **Thread 3 (schedules):** scheduled threads that find something should fail
  loudly (`StopFailure`/Stop) so the same hooks announce them.

## 8. rebuild.sh integration (handoff to the workflow-docs thread)

`rebuild.sh` (not edited here) has `notify_ok()` at the end of `switch` and of
the interactive flow; it only calls `notify-send`, so a switch started from a
phone or REDRUM would never reach the phone. `agent-notify` gained a
non-hook entry point for it:

```bash
AGENT_NOTIFY_LABEL="Rebuild done" agent-notify send finished "$host generation $current"
AGENT_NOTIFY_LABEL="Rebuild failed" agent-notify send failed "$host build failed"
```

Suggested `notify_ok` body: keep the `echo`, then
`if command -v agent-notify >/dev/null; then AGENT_NOTIFY_LABEL="Rebuild done"
agent-notify send finished "$1" || true; elif command -v notify-send ...` as
today. `send` honours quiet hours (a completion is dropped inside them),
dedupe and the ntfy config, and its text is sent to ntfy because the caller, not
an agent, wrote it. It exits 0 always. A `die`/failure path can call the
`failed` form. Verified against a local listener; `rebuild.sh` itself untested.
