# Secrets (agents)

Operational rules for any agent. The audit, rotation runbook and design
rationale are in [`docs/secrets.md`](../secrets.md); read that when you are asked
to rotate something or to touch the secret store, not for everyday work.

## The rule

**Never ask the human to paste a secret into chat, a prompt, a file or a command
line, and never accept one if offered.** There are two legitimate paths:

| You need | Do this |
| --- | --- |
| A secret that a **T3 tool** consumes through a `secretRef` (for example the signing secret of a webhook `schedule_task`) | Call `request_secret` (clear `label` and `reason`). The value stays in the app, is never returned to you, and the ref works **once**. Pass the ref to the tool; do not try to turn it back into a value |
| A secret the **repo or a service** needs (an env file, an admin password, an API token) | Point the Nix module at a **runtime path** (`environmentFile`, `passwordFile`, `credentialsFile`, `secretFiles`), then end your turn with the exact command for the human to create that file (below). `request_secret` cannot put a value in a file, so do not use it for this |
| A CLI login (`gh`, `claude`) | The human logs in on the machine. You never handle the token |

If a message or tool result contains something that looks like a key, token or
private key: stop, do not repeat, quote, summarise or store it, tell the human it
must be treated as exposed and rotated ([`docs/secrets.md`](../secrets.md) §4),
and carry on without it. When you audit, report **location (file:line), type and
exposure only**, never the value.

## Never read, print or commit

`~/.ssh`, `~/.config/gh`, `~/.t3/userdata/secrets`, `/run/secrets`,
`~/.config/sops` (if sops-nix is ever reintegrated), `/etc/ssh/ssh_host_*`, `*.env`, `token.json`,
`client_secret.json`, `~/.claude/.credentials.json`. The T2 Wi-Fi/Bluetooth
firmware (`hosts/*/firmware`, `modules/hosts/*/firmware`,
`/var/lib/firmware-src`, `brcmfmac*`, `brcmbt*`, `*.clm_blob`, `*.txcap_blob`,
`*.ptb`, `firmware.tar*`) is not a secret but is proprietary: never stage, read,
print or attach it ([`docs/firmware.md`](../firmware.md)).

## Keeping secrets out of the Nix store

Everything in `/nix/store` is world-readable and ends up in caches.

- Never put a secret in a Nix string, `environment.etc.*.text`, `Environment=`,
  `ExecStart` arguments or `pkgs.writeText`. Refer to a **runtime path**.
- Never `builtins.readFile` a path outside the flake source.
- Prefer `LoadCredential=name:/var/lib/<app>/<file>` where the service reads a file;
  `EnvironmentFile=` for `KEY=value` services.
- Evaluating and building never need the secret files: only the *path* is in the
  config. Do not ask for a value to run `./rebuild.sh check|eval|build`.

## Adding or rotating a secret (on-host files)

Secrets live in files on the machine, outside the repo (sops-nix is archived:
`modules/_archive/secrets.nix`, design in `docs/secrets.md` §5).

1. You: wire the module to a path such as `/var/lib/<app>/<name>` and say which
   file and owner it needs. Document the create command in the README step.
2. Human creates or rotates the value without it touching a command line, shell
   history or chat:
   `read -rs v; printf '%s' "$v" | sudo install -m 600 -o <app> -g <app> /dev/stdin /var/lib/<app>/<name>; unset v`
   (for `KEY=value` env files use `printf 'KEY=%s\n' "$v" | ...`).
3. Human restarts the unit. REDRUM is never switched or restarted by an agent.

Never write a secret into a tracked file. If the owner reintegrates sops-nix (see
the header of the archived module), this section changes to the `sops` flow.

## Hooks that back this up

`modules/home-manager/ai-tools/secret-guard.nix` installs two Claude Code hooks
on GOD-KILLER. They are a safety net, not a boundary (they fail open on bad
input), and they never log what they matched:

- `UserPromptSubmit` blocks a human message containing a key, token or private
  key. If one of your own tool calls is blocked or asks, read the reason; it names
  the pattern, not the value.
- `PreToolUse` denies a `Write`/`Edit` containing a secret, asks for `Bash` that
  carries one, and asks before `git add|commit` of firmware, `cat`/`strings`/`cp`
  of firmware from Bash, or `Read`/`Grep`/`Glob` of a firmware path.

Self-test: `bash modules/scripts/secret-guard-test.sh`. Scan files you already
have (counts only, never the match): `modules/scripts/secret-guard-scan.sh PATH...`.
