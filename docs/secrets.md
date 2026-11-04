# Secrets: audit, rotation, management, and keeping them away from agents

Written 2026-11-01 by the "secrets" workflow thread (branch `workflow/secrets`).
**This file is redacted on purpose.** It records locations, types and exposure,
never values. Keep it that way: do not paste a secret here to "show an example".

Contents: [1 Summary](#1-summary) ·
[3 Nix store exposure](#3-nix-store-exposure) · [4 Rotation runbook](#4-rotation-runbook) ·
[5 Secrets management (sops-nix deferred)](#5-secrets-management-on-host-files-now-sops-nix-deferred) ·
[6 T3 Code and secrets](#6-t3-code-and-secrets) ·
[7 Keeping secrets out of prompts](#7-keeping-secrets-out-of-prompts-secret-guard) ·
[8 Handoffs and open items](#8-handoffs-and-open-items) · [9 Unverified](#9-unverified-assumptions)

## 1. Summary

- No credential was found in the working tree or in any git history that was
  ever public (gitleaks and trufflehog over every commit).
- The larger risk is at runtime: credentials in files an agent can reach (a
  Full access thread runs without prompts) and anything pasted into a thread.
  Sections 4, 6 and 7 are the response.
- Rotation is a precaution, not the response to a known leak.
- The dated audit report (method, findings, exposure timeline, decisions) is
  kept in the private repository `cqjro/nixos-archive` as
  `docs/secrets-audit.md`.

## 3. Nix store exposure

Everything in `/nix/store` is world-readable on the machine, and ends up in
binary caches if you ever push a closure. What was checked:

| Risk | Finding |
| --- | --- |
| `builtins.readFile` of a secret | None. Uses are `neovim.nix:14` (Lua config), `rss-sources.nix:59` (public feed list), `actual-budget-tweaks.nix:217` (the ABT shim). |
| `builtins.getEnv`, `--impure` secret reads | None in modules. `--impure` exists for the firmware paths (thread 2 is replacing that). **The flag itself is the standing risk:** an edited module could `builtins.readFile ~/.config/gh/hosts.yml` and bake it into a derivation. Review diffs before `build`/`switch`, and prefer a pure eval where possible. |
| Values interpolated into units | `Environment = [...]` entries (`actual-budget-tweaks.nix:250`, `t3code.nix:57`) carry ports, paths and the `GIT_CONFIG_*` credential-helper wiring only; no token. |
| `environment.etc` | `t3code.nix:82` (managed Claude settings, no secrets), `vpn.nix:14` (OpenSSL config), `rss-sources.nix:80` (OPML of public feeds). |
| Secrets as file paths | `glance.nix:26`, `beszel.nix:56`, `miniflux.nix:25`, `paperless.nix:31`, `linkwarden.nix:23-25`, `cloudflared` `credentialsFile` ×8. The path string is in the store, the content is not. This is the right pattern. |
| Secrets in flake inputs / URLs | None. `flake.lock` holds public pins only. |

Rules for new code (also proposed for AGENTS.md, handoff H1):

- Never put a secret in a Nix string, `environment.etc.*.text`, `Environment=`,
  `ExecStart` arguments, or `pkgs.writeText`. Refer to a runtime path instead.
- Prefer `LoadCredential=name:/run/secrets/name` (the unit gets a private,
  unit-scoped copy at `$CREDENTIALS_DIRECTORY/name`) over `EnvironmentFile=`
  where the service can read a file; `EnvironmentFile=` is fine for
  `KEY=value` services (systemd reads it as root, then drops privileges).
- Never `builtins.readFile` a path outside the flake source.

## 4. Rotation runbook

> **Before the new public repo goes live, finish this list.** Only the README default
> admin passwords are required by the flip itself; the rest is recommended hygiene.
> The full checklist is in the private audit (`docs/secrets-audit.md` in `cqjro/nixos-archive`).

**Principle.** Rotate = create the new credential, deploy it, *then* revoke the
old one, so nothing breaks half-way. Anything that ever sat in git history stays
exposed to everyone who cloned the repo (GitHub, your machines, any fork), and
rewriting history does **not** un-expose it; for a credential that was really
committed, rotation is the only fix and the rewrite is hygiene.

Ordered by risk (blast radius × likelihood it was reachable). Steps marked
**you** need a password, a browser or a TTY and must not be done by an agent.

### 4.1 GitHub (highest risk) **you**

> **Status 2026-11-03:** done on GOD-KILLER (fine-grained token limited to `cqjro/nixos`; the broad "GitHub CLI" grant revoked). Still open: REDRUM's `t3code` user gets its own token when it is re-cloned (TODO.md).

Blast radius: the current `gh` token covers every private repo you own.

1. On each machine, replace the broad login with a fine-grained PAT:
   github.com → Settings → Developer settings → Fine-grained tokens → generate.
   Repository access: **only `cqjro/nixos`**. Permissions: Contents RW, Pull
   requests RW, Metadata R (add Issues RW only if the scheduled-thread design
   files issues). Expiry 30-90 days. One token **per machine** (GOD-KILLER,
   REDRUM `t3code` user) so you can revoke one.
2. Enter it without touching a command line or chat:
   `read -rs T; printf %s "$T" | gh auth login --with-token; unset T`
   On REDRUM: `sudo -u t3code -H bash -c 'read -rs T; printf %s "$T" | gh auth login --with-token'`.
   (`gh` keeps it in `hosts.yml` when no keyring is available, which is the
   headless case.)
3. Revoke the old broad grant: github.com → Settings → Applications → Authorized
   OAuth Apps → **GitHub CLI** → Revoke. This invalidates the token on all
   machines at once; re-login each with its PAT.
4. Check github.com → Settings → Security log and the repo's Settings → Deploy
   keys / Webhooks for anything you do not recognise.

### 4.2 SSH keys **you**

Only if the key has no passphrase, or a Full access thread could `cat` it and
you do not trust the passphrase: `ssh-keygen -t ed25519 -a 100` (passphrase on),
add the public key to GitHub twice (Authentication and Signing), replace the
two keys in `modules/hosts/REDRUM/machine.nix:80-81` (public keys, safe to
commit) and switch REDRUM *before* deleting the old key from GitHub and from
`authorized_keys`. Keep an existing SSH session open while testing the new key.
Agents never need this key: pushes go over HTTPS with the PAT from 4.1.

### 4.3 Cloudflare **you**

- **Tunnel credentials** (`/var/lib/cloudflared/<app>.json`, 8 files). Not in
  git, so only needed if the files were readable by an agent. Rotate by creating
  a replacement: `cloudflared tunnel create <app>-2`, copy its JSON over the
  credentials file, update the UUID in the module, add the DNS route
  (`cloudflared tunnel route dns <app>-2 <host>`), switch REDRUM, confirm the
  hostname answers, then `cloudflared tunnel delete <old>`.
- **`cert.pem`** from `cloudflared tunnel login` (in `~/.cloudflared/` on
  whichever machine ran it) is an *account-level* certificate able to create
  tunnels and edit DNS. It is not needed at runtime: **delete it** after
  creating tunnels. If it ever sat in a home directory an agent could read,
  revoke it by logging in again and clearing old authorisations in the
  Cloudflare dashboard → My Profile → API Tokens / Zero Trust.
- Any Cloudflare API token you created for DNS: roll it in the dashboard.

### 4.4 Claude / Anthropic **you**

Re-authenticate so the stored OAuth token is replaced: `claude` → `/logout`,
`/login` (GOD-KILLER); `sudo -u t3code -H claude` → `/logout`, `/login`
(REDRUM). Then review active sessions at claude.ai → Settings → Account and
sign out other devices. Consequence of a leak is quota theft, not billing, but
the token also lets someone read your account's chat history.

### 4.5 Tailscale **you**

No auth key is stored in the repo (no `authKeyFile` anywhere). If a pre-auth
key was ever used to enrol a machine, revoke it in the admin console → Settings
→ Keys. To force re-auth of a node: `tailscale logout` then `tailscale up` (or
expire the node key in the console; disable key expiry for REDRUM after). If
an agent ever ran `tailscale serve`/`set`, review `tailscale serve status` and
the ACLs. Consider an ACL that limits who can reach REDRUM's T3 port.

### 4.6 T3 Code sessions and pairing **you**

Pairing tokens are single-use and expire in 5 minutes, so an old link is not a
risk. A **paired device** (phone browser, other desktop) holds a long-lived
session and, by default, terminal + filesystem-write scopes. If a device is
lost or its scopes were too wide: remove it in T3 → Settings → Connections
(wording untested), re-pair with narrow scopes. To invalidate every session at
once, stop the T3 server and delete its signing secret under
`~/.t3/userdata/secrets` (inferred from the directory's role, **untested**; do
not let an agent read or touch that directory).

### 4.7 Application credentials **you**

| Credential | Where | Rotate by |
| --- | --- | --- |
| Miniflux admin password | `/var/lib/miniflux/admin.env` | Change in the web UI (Settings → Users) and update `admin.env`; the file is only read when the admin is first created |
| Miniflux API token | `~/.config/rss-sync/api-token` | Settings → API Keys: create new, replace the file, delete the old key |
| Linkwarden `NEXTAUTH_SECRET` | `/var/lib/linkwarden/nextauth-secret` | `openssl rand -base64 32` into the file, restart the unit (everyone is logged out) |
| Linkwarden `POSTGRES_PASSWORD` | `/var/lib/linkwarden/postgres-password` | `ALTER USER … PASSWORD …` in Postgres, update the file, restart |
| Actual Budget server password | in the Actual UI | Settings → Change server password; file-level encryption keys are separate and cannot be rotated retroactively |
| Glance password + `secret-key` | `/var/lib/glance/glance.env` | `glance secret:make` for the key, new password; restart. |
| Paperless admin | `/var/lib/paperless/admin-password` | `paperless-manage changepassword <user>`; the file is read only at first start |
| Beszel agent `KEY`/`TOKEN` | `/var/lib/beszel/agent.env` | Hub → Add system → new universal token; replace file, restart agent |

### 4.8 Google / YouTube OAuth **you**

`client_secret.json`: Google Cloud Console → APIs & Services → Credentials →
the OAuth client → add a new secret, download, replace, disable the old one.
`token.json` (refresh token): revoke at myaccount.google.com → Security → Third-party
access, then re-run `modules/server/youtube/setup_auth.py` to mint a new one.
Neither file was ever committed.

### 4.9 Anything you pasted into a thread

If you ever pasted a key into a prompt or an attachment, assume it is retained
in the local transcript (`~/.claude/projects/**`, the T3 database) and on
Anthropic's side. Rotate it per the table above; deleting the thread is not
rotation.

## 5. Secrets management: on-host files now, sops-nix deferred

> **Status (2026-11-02): archived, not active.** sops-nix would have had a single
> consumer (Glance), so the owner chose to keep secrets as on-host files (a runtime
> path in the module, the value in a file under `/var/lib/<app>/`). The module and
> its template were moved to `modules/_archive/secrets.nix` and
> `modules/_archive/secrets.sops.yaml`, the `flake.nix` input is commented out and
> `flake.lock` is back to the master version. Everything below is kept as the design
> to reintegrate later (the steps are in the header of the archived module).
> Revisit if a secret must be reproducible from git or keeping values out of the
> repo becomes unmanageable. Sections 5.3 to 5.6 describe the archived module.

### 5.1 Requirements for this repo

- Three hosts, one of them headless and unattended (REDRUM must decrypt at
  boot with no password, no network, no agent).
- The ciphertext lives in the repo, so agents can read it, and **must be able
  to build and evaluate without any key**.
- An agent must be able to *declare* a secret without ever seeing its value.
- Pure `nix eval`/`build` must not need decryption (decrypt only on the host
  at activation).
- Fits flake-parts + import-tree (a fragment, opted in per host).

### 5.2 sops-nix vs agenix

| | sops-nix | agenix |
| --- | --- | --- |
| Identity on a host | Host SSH ed25519 key, converted to age at activation (`sops.age.sshKeyPaths`) | Host SSH key used directly (`age.identityPaths`) |
| Headless boot | Decrypts in an activation script from the on-disk host key: no network, no prompt | Same |
| File layout | One encrypted YAML/JSON/dotenv per host (key **names** visible, values encrypted); or one file per secret (binary) | One `.age` file per secret, plus a `secrets.nix` recipient map |
| Review in a PR | Diff shows which keys changed and that the MAC changed | Whole-file binary change per secret |
| Agent declares a new secret | Adds `sops.secrets.<name>` (plain Nix). The value is added by the human with `sops` | Same, but the agent can also *create* the encrypted file: `age -R recipients -o x.age` needs only public keys |
| Agent edits an existing value | Cannot: `sops` must decrypt the data key first, so it needs a private key | Cannot (`agenix -e` decrypts first) |
| Rendering config files | `sops.templates` substitute secrets into a whole config file at activation (good for `KEY=value` env files with several secrets) | Whole file is the secret; no templating |
| Restart on change | `restartUnits` / `reloadUnits` per secret | Manual |
| Per-secret owner/mode | Yes | Yes |
| Rotation of recipients | `sops updatekeys` (needs a current key) | `agenix -r` (needs a current key) |
| Maintenance | Very active, large user base | Smaller, simpler, slower-moving |

**Pick: sops-nix.** `templates` (for the env-file style every service here
uses), `restartUnits`, and key-name visibility in review outweigh agenix's
simplicity. agenix is a perfectly good fallback; the module shape in
`modules/essentials/secrets.nix` would change only in the consuming lines.

### 5.3 What was built (now archived)

| File | Purpose |
| --- | --- |
| `flake.nix` / `flake.lock` | `sops-nix` input (`follows nixpkgs`), locked at 2026-10-26 |
| `modules/essentials/secrets.nix` | Fragment `nixos.secrets`: imports the sops-nix module, **inert until `secrets/<hostname>.yaml` exists in the repo**; decrypts with `/etc/ssh/ssh_host_ed25519_key`, no GPG, no generated key. Fragment `nixos."secrets-glance"`: moves Glance's `GLANCE_SECRET_KEY`/`GLANCE_PASSWORD` to a sops template rendered at `/run/secrets/rendered/glance.env`, replacing the hand-written `/var/lib/glance/glance.env`, restarting `glance.service` on change |
| `modules/hosts/host.nix` | Adds both fragments to **REDRUM** only |
| `.sops.yaml` | Creation rules with two `TODO` age recipients (admin + REDRUM host key) |

Why inert-by-default: until you bootstrap, REDRUM builds exactly as before
(Glance keeps reading the hand-written file). Nothing breaks, agents and the
weekly build check work without keys, and the switch that activates it is the
one you control.

Verified (2026-11-01, GOD-KILLER):

- `nix eval --impure …REDRUM…toplevel.drvPath` succeeds with the module inert
  **and** active (tested with a throwaway key and a dummy file that was deleted
  afterwards; nothing was committed).
- `sops-install-secrets` builds against REDRUM's pinned nixpkgs `cac0c1ef`
  (the Go-version trap that affects Tailscale does not apply).
- The generated manifest in the store lists secret **names** and `<SOPS:…:PLACEHOLDER>`
  tokens only; no value, no dummy string.
- `services.glance.environmentFile` resolves to `/run/secrets/rendered/glance.env`.
- GOD-KILLER and the hook wiring evaluate (`drvPath`).

**Not verified:** an actual activation on REDRUM, the file ownership of the
rendered env file at runtime, and a full REDRUM `build` (only eval plus the
`sops-install-secrets` build were run). LittleNix does not evaluate in this
checkout for an unrelated reason (gitignored firmware, thread 2).

### 5.4 Bootstrap (you)

On GOD-KILLER:

```bash
# 1. your admin key; keep the private half out of agents' reach
mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt        # prints age1…  (public; goes in .sops.yaml)

# 2. REDRUM's recipient: derived from its PUBLIC host key, no secret involved
ssh-keyscan -t ed25519 <redrum-address> 2>/dev/null | nix run nixpkgs#ssh-to-age
```

Put both public strings into `.sops.yaml` (replace the two `TODO` lines), then:

```bash
# 3. create the file (opens $EDITOR on a template; add the two keys)
sops secrets/REDRUM.yaml
#   glance_secret_key: <output of `glance secret:make`>
#   glance_password:   <a new password>
git add secrets/REDRUM.yaml .sops.yaml

# 4. build, then switch REDRUM yourself (agents may build but never switch it)
./rebuild.sh build REDRUM
./rebuild.sh switch REDRUM -m "REDRUM: sops-nix, glance secrets" --target USER@IP
```

Afterwards delete `/var/lib/glance/glance.env`, and `Read`-deny your admin key
(handoff H3). Back up `~/.config/sops/age/keys.txt` somewhere that is not this
repo and not a synced folder an agent can read; losing it means re-encrypting
from a host that can still decrypt (REDRUM's own key can, via
`SOPS_AGE_SSH_PRIVATE_KEY_FILE` as root).

### 5.5 Day-2 workflow

| Task | Who | How |
| --- | --- | --- |
| Declare a new secret and wire a service | agent (or you) | Add `sops.secrets.<name>` / a `sops.templates` entry in the service's fragment, and say which key name the file needs. Evaluates with no key |
| Put the value in | **you** | `sops secrets/REDRUM.yaml`, or non-interactively without exposing it on a command line: `read -rs v; jq -Rn --arg v "$v" '$v' \| sops set --value-stdin secrets/REDRUM.yaml '["name"]'; unset v` |
| Rotate a value | you | Same command with the new value, then switch the host |
| Add a host | you | Add its age key and a rule to `.sops.yaml`, then `sops updatekeys secrets/<HOST>.yaml` |
| Review a secrets PR | agent/you | The diff shows key names and `ENC[…]` blobs; a reviewer can confirm the *shape* (no plaintext slipped in) without any key. `gitleaks` or the guard (section 7) catches a plaintext file |

An agent that is asked to "add a secret" should end its turn with the exact
`sops` command for you to run, not ask for the value.

### 5.6 Migration order for the rest

Each is a fragment edit plus one `sops` command; do them one switch at a time,
lowest blast radius first: Glance (done here) → Beszel agent env → Paperless
admin → Miniflux `admin.env` → Linkwarden secrets → `rss-sync` API token →
(stop here while the repo is public, see 5.7). Possible only for a private repo: Cloudflare tunnel credentials (`credentialsFile` takes any path; use `sops.secrets.<name>.format = "binary"` with the JSON as a file) and the YouTube `client_secret.json`/`token.json` (the token file is *rewritten* by the app on refresh, so it needs a writable copy; copy it into place at start with `ExecStartPre`). Not suitable for sops: the Claude/GitHub logins on REDRUM (interactive, rewritten by the CLIs).

### 5.7 What "secret" means when the ciphertext is in a public repo

**In short:** public ciphertext is not a problem while the age keys stay private and
the encryption holds. It is a *second layer removed*: with a private repo an attacker
needs the key **and** the file, with a public one only the key. For rotatable app
passwords that difference is small; it matters for long-lived credentials.

A secret is secret because of the **key**, not because nobody has the file. Public
ciphertext is the same situation as an HTTPS session someone recorded: they hold
the bytes and can do nothing with them without the key. sops-nix encrypts each
value with age (X25519 key agreement + ChaCha20-Poly1305), and the data key is
wrapped separately for every recipient (you, each host). What public ciphertext
does change:

- **The key becomes the only wall.** An age private key that ever leaks (the
  admin key in `~/.config/sops/age/keys.txt`, a host's `/etc/ssh/ssh_host_ed25519_key`)
  decrypts **every revision ever pushed**, including values you have since changed.
  That is why those two paths are on the never-read list and why a leaked key means
  rotating every secret it could open, not just re-keying the file.
- **Harvest now, decrypt later.** Anyone can copy the ciphertext today and wait.
  Today's age is not known to be breakable; X25519 would not survive a large
  quantum computer (age's post-quantum recipients are newer and not what sops-nix
  uses here). That risk matters for secrets that stay valuable for years and not for
  an app password you rotate in a year.
- **Rotation makes old ciphertext worthless.** A password you have replaced is no
  longer a secret, so a stolen old revision opens nothing. Long-lived, hard to
  rotate material (the Cloudflare tunnel credentials, SSH or signing keys) is the
  case to avoid putting in a public repo at all.
- **Metadata is public.** Key names, how many secrets exist, their sizes, who can
  decrypt (the recipient public keys) and when each changed are all visible in
  `secrets/*.yaml` and the git history.

Choices, from most to least convenient:

1. **sops in the public repo** for rotatable app credentials (Glance, Miniflux,
   Paperless, Beszel, Linkwarden): the usual practice and what this branch builds.
2. **Keep crown jewels out of the repo**: tunnel credentials, Tailscale, SSH keys and
   the GitHub token stay as on-host files under `/var/lib` (the approach used today),
   or in a separate private repo. Cost: not reproducible from git alone and backed up
   by hand. A private repo pulled in as a flake input would make every build need
   access to it, which agents with a repo-only token would not have, so the
   "agents build without any key" property would be lost.
3. **Nothing secret in git at all**, which is what the repo did before this work.

My recommendation is 1 for the five app credentials above and 2 for everything
long-lived. This revises 5.6: leave the Cloudflare `credentialsFile` entries out of
the migration list while the repo is public.


## 6. T3 Code and secrets

What is known (from the tool definition in this environment; the app's source
was not read):

- **`request_secret`** opens a private card in the thread. The user types the
  value there; "the value is kept by the app and **never returned to the agent
  or shown in the transcript**". The result carries a **`secretRef`**, which
  works **once**, and the agent passes it to a tool that accepts one. A timeout
  (default 10 minutes) or cancel returns without a ref. Retrying with the same
  `clientRequestId` shows one card.
- The documented consumer is `schedule_task`'s `signature.secretRef` (the
  HMAC signing secret for a **webhook** task, for senders such as GitHub that
  sign requests). Other tools "that accept one" may exist; the agent cannot
  turn a `secretRef` back into a value, so it cannot write one into a file or
  a command line.
- `~/.t3/userdata/secrets` is the app's secret store (the directory is
  `Read`-denied and was **not** read for this document). It presumably holds the
  server's own credentials plus values saved through `request_secret`; the exact
  contents and encryption are **unverified**. Treat it as the most sensitive
  directory on the machine: never let an agent read it, never back it up to the
  repo. The desktop app's saved connections are separate (system keyring).

### 6.1 How threads and scheduled tasks should use it

| Situation | Use |
| --- | --- |
| A scheduled **webhook** task whose sender signs requests | Agent calls `request_secret` (label "GitHub webhook secret"), then `schedule_task` with `signature.secretRef`. Never ask for the secret in chat |
| Any value a service or the repo needs | **Not** `request_secret` (it cannot write a file). The agent points the module at a runtime path and gives you the command to create that file yourself (`docs/agents/secrets.md`) |
| A token a CLI needs (`gh`, `claude`) | You log in on the machine (`gh auth login --with-token`, `claude /login`); the agent never handles it |
| Scheduled / unattended threads | Must not need a secret in the prompt. Run as a user that already has a login, or use a webhook with `secretRef`. A scheduled prompt is stored in plain text in T3; never write a credential into one |

### 6.2 Agent-facing rule (now in `docs/agents/secrets.md`; kept here as the rationale)

> **Secrets.** Never ask the user to paste a secret into chat, a prompt, a file
> or a command line, and do not accept one if offered. If you need a secret:
> (1) for a T3 tool that takes a `secretRef` (for example a webhook signing
> secret), call `request_secret` and pass the ref on; (2) for anything the repo
> or a service needs, point the Nix module at a runtime path and tell the user
> the exact command to create that file themselves, with the value read from a
> hidden prompt. If a message contains something that looks
> like a key, token or private key, stop, do not repeat or store it, tell the
> user it must be treated as exposed and rotated (docs/secrets.md), and
> continue without it. Never read `~/.ssh`, `~/.config/gh`, `~/.config/sops`,
> `~/.t3/userdata/secrets`, `/run/secrets`, `*.env`, `token.json`,
> `client_secret.json`; never print a secret you find, report its location
> and type only.

This is advisory text. The enforceable layers are the hooks (section 7), the
`Read` denies (thread 4), and keeping the files out of reach.

## 7. Keeping secrets out of prompts: secret-guard

`modules/home-manager/ai-tools/secret-guard.nix` defines the NixOS fragment
`nixos."secret-guard"`, imported in `host.nix` by **GOD-KILLER and REDRUM** (the
hosts that import `claude-code-policy`). It sets `claude-code-policy.hooks`, because
the managed policy has `allowManagedHooksOnly = true`: Claude Code reads hooks
**only** from there and silently ignores home-manager
`programs.claude-code.settings.hooks`, project `.claude/settings.json`, skills and
subagents (`docs/agents/security.md`, "Adding hooks (merge point)"). The fragment
installs two hooks backed by `modules/scripts/secret-guard.sh`, with store-path
commands; `claude-guard` stays first in `PreToolUse`. LittleNix has no policy, so it
must not import the fragment.

| Hook | Does |
| --- | --- |
| `UserPromptSubmit` | Scans your message. A match **blocks it before the model sees it**; you get the reason in the UI and the message is not added to the context |
| `PreToolUse` on `Bash\|Write\|Edit\|MultiEdit\|NotebookEdit\|Read\|Grep\|Glob` | Scans the tool input. `Write/Edit/MultiEdit/NotebookEdit` with a secret are **denied**; `Bash` with one **asks** you. For `Read/Grep/Glob` only the **path arguments** are checked, and only against the firmware rule below (never the contents). Catches an agent that was handed a secret some other way and is about to write it down |

Properties: patterns in `secret-guard-patterns.txt` (vendor-prefixed tokens and
private key blocks are `strong`; a generic `password=…` and credentials in a URL
are `weak`, skipped when the message contains `[allow-secret-pattern]`; `strong`
ignores the bypass). The script **never logs or prints the match**, only the
label ("GitHub token"). It **fails open** on malformed input, so a broken
hook cannot lock you out; treat it as a net, not a wall. `suppressOriginalPrompt`
is set because, per the Claude Code docs, a blocked prompt is otherwise echoed
back in the block message and written to the transcript. Even so, **the text
you typed still lands in the on-disk transcript and prompt history** (the same
docs): a blocked secret is *not* safe, only unsent. Rotate anything you pasted.

Self-test: `bash modules/scripts/secret-guard-test.sh` (79 cases; fake tokens
are assembled at run time). Retro-scan: `secret-guard-scan.sh`.

### 7.1 Does it work under T3?

| Behaviour | Result |
| --- | --- |
| `PreToolUse` hooks configured in a project `.claude/settings.local.json` fire under T3, and are picked up mid-session | **Verified 2026-11-01** (probe logged a hook event for a Bash call in this thread) |
| `UserPromptSubmit` fires for a message typed in the T3 composer | **Verified 2026-11-02**: the probe logged 12 `UserPromptSubmit` events from the owner's messages in this thread (and 110 `PreToolUse`). Still open: whether a *blocking* one shows its reason in the UI (needs the `SECGUARD-MARKER` message below) |
| A blocking `UserPromptSubmit` surfaces in the T3 UI (shows the reason, not an error loop) | **Verified 2026-11-02** (owner-observed): the UI shows `UserPromptSubmit operation blocked by hook: <reason>`, with the hook's reason text, and the agent does not run. A normal message afterwards is expected to continue the thread (not separately checked) |
| Hooks from the managed policy (`claude-code-policy.hooks`, the only source now) fire under T3 | **Untested until the owner switches.** Everything above was observed with a project-level probe, a different channel that `allowManagedHooksOnly` now ignores; the managed channel is the same Claude Code mechanism, but it has not been observed for secret-guard. Evaluated: `claude-code-policy.hooks` has `PreToolUse` = 2 (`claude-guard` first, then secret-guard) and `UserPromptSubmit` = 1 on GOD-KILLER and REDRUM. Smoke-test step 24 in `docs/agents/security.md` is the check after the switch |
| Hooks run on REDRUM's `t3code` user | **Wired, untested**: REDRUM imports the fragment too, so the same managed JSON carries them (`/etc/claude-code/managed-settings.json`). Needs a REDRUM switch by the owner |

**The test (done 2026-11-02).** A probe in this worktree's untracked
`.claude/settings.local.json` logged each hook event (never the prompt) and blocked
any prompt containing `SECGUARD-MARKER`: 12 normal messages were logged and passed,
and a thread launched with the marker was blocked with the reason shown in the UI.
The probe file and its log were then deleted.

### 7.2 Limits

Not covered: secrets in image attachments or screenshots; values split across
messages; secrets without a recognisable prefix (a bare 40-char Cloudflare API
token, a random password); pastes via any client that bypasses Claude Code
(editing a file yourself). A high-entropy detector was left out on purpose:
store hashes and commit SHAs would trigger it constantly. `gitleaks` as a
pre-commit/pre-push hook is the matching layer for files (handoff H4).

**Firmware (not a secret).** The pattern file also carries the firmware denylist (names and paths only, from the firmware and agent-security threads): `hosts/*/firmware`, `modules/hosts/*/firmware`, `/var/lib/firmware-src`, `brcm/`, `firmware/`, `brcmfmac*`, `brcmbt*`, `*.clm_blob`, `*.txcap_blob`, `*.ptb` and `firmware.tar*` (blobs also with a `.zst`/`.xz`/`.gz` suffix), the T2 store directories `*-brcm-firmware` and `*-brcm-firmware-zstd` (`/run/current-system/firmware` resolves into the zstd one) and `brcm-firmware.gcroot`. Four rules: a `git add|stage|commit` that names one; a Bash read, copy or upload of one with `cat less more head tail xxd hexdump strings od base64 cp mv scp rsync tar zip 7z curl nc zcat zstdcat unzstd xzcat unxz bzcat gunzip lz4cat bat nl tac dd tee adb gh wget` (`ls`, `find`, `nix path-info` and the `t2-firmware-import` app are untouched); the Nix daemon's root-run reads, `nix store cat|dump-path|export`, `nix nar cat|dump-path`, `nix copy`, `nix bundle` and `nix-store --dump|--export`, when the same command names a firmware path; and a `Read`/`Grep`/`Glob` whose **path** is one (a grep *pattern* that merely mentions `brcmfmac` is fine). These **ask** in a Supervised thread because the files are proprietary, not credentials; **under Full access (`permission_mode` `bypassPermissions`) T3 approves every `ask` itself, so the hook returns `deny` instead**, the same conversion `claude-guard` makes. This is the second layer behind `claude-guard`'s `fw_re`/`fw_op_re`, which block Bash outright in every mode. It is a speed bump for agents, not a guarantee: `git add --all`, which `rebuild.sh` runs itself, is not caught, and Bash can reach files in ways a regex cannot see, so `.gitignore`, tier-0 (H7) and not granting the `t3code` user access to `/var/lib/firmware-src` are the real controls.



## 8. Handoffs and open items

| # | To | Item |
| --- | --- | --- |
| H1 | Thread 1 (AGENTS.md/README) | **Applied on this branch** after merging `workflow/pr-rebuild-docs`: the rule, store rules and on-host-file flow are in `docs/agents/secrets.md` (AGENTS.md index row and safety bullet point to it; the bullet and CLAUDE.md no longer say `request_secret` is the way to get *any* secret, because it only feeds tools that take a `secretRef`); `module-recipes.md` rules 3 and 4 updated (UUIDs are identifiers, secrets are runtime paths); README layout lists `docs/secrets.md`. **Still open:** (d) replace the README "Create app secrets" `sh -c \x27echo … >\x27` commands with a hidden-prompt version (`read -rs`; `install -m 600 -o <user>`), so passwords stay out of shell history and `ps`. |

| H2 | Firmware thread (owner of the 6.3 run) | Superseded by the new-repo plan. The scans over the old public history found **no credential**; the extra paths (listed in `docs/firmware.md` 6.3), the mailmap and the replace-text are already in your 6.3 command. The authoritative list of what must be decided before that single run is in the private audit; send me or the owner any change to it first, because the new repo is pushed once. Your firmware filename patterns are in the guard (7.2). Re-run gitleaks/trufflehog on the scratch clone before the push. |


| H3 | Thread 4 (permissions) | **(b) and (c) done** with the move to `claude-code-policy.hooks` (this branch, after PR #3): the fragment is wired on GOD-KILLER and REDRUM, and the home-manager hook and its import are gone. (a) `claude-code.nix`: add `Read` denies for `/etc/ssh/ssh_host_*` (and `~/.config/sops/**` if sops-nix is ever reintegrated); with the sandbox, `denyRead` the same plus `~/.ssh`, `~/.config/gh`, `~/.claude/.credentials.json`. (b) Hook merge: `claude-code-policy.hooks` lists concatenate across modules (checked by eval). Any `deny` wins, but two `ask`/`allow` results from different hooks are not combined predictably, and under Full access an `ask` is auto-approved, so secret-guard now turns its own `ask` into `deny` when `permission_mode` is `bypassPermissions` (as `claude-guard` does). (c) REDRUM: done by the same fragment. (d) Never put `disableBypassPermissionsMode` back; under Full access the `Read` denies do not stop Bash, so the sandbox and PAT scoping (4.1) are the real controls. |
| H4 | Thread 1/4 | Add `gitleaks` (already builds via `nix run nixpkgs#gitleaks`) as a `rebuild.sh`/pre-push check on the staged diff. |
| H5 | Thread 3 (schedules) | Scheduled prompts are stored in plain text: no credentials in them; use the GitHub CLI login of the machine, or `request_secret` + `secretRef` for webhooks. |
| H6 | Thread 6 (notifications) | If ntfy is added, its topic name is a bearer secret: keep it in an on-host file (as thread 6 already does), not in `notifications.nix`. |
| H7 | Thread 1 (`rebuild.sh`, `cmd_check`, your file) | Tier-0 additions this thread would like; all tested on a scratch repo, none applied. (a) **Filename regex**: append `\|(^\|/)(id_(rsa\|ed25519\|ecdsa)\|keys\.txt)$\|(^\|/)\.(netrc\|pgpass)$` to the existing tracked-secrets pattern; do **not** add `\.yaml`, so encrypted `secrets/*.yaml` stays allowed if sops-nix is reintegrated. (b) **Only if sops-nix is reintegrated** — sops files must be ciphertext: for every tracked `secrets/*`, fail unless it contains both `ENC[AES256_GCM` and a `sops:` block (a plaintext file dropped there would otherwise pass). (c) **Content scan of the staged diff**: `nix run nixpkgs#gitleaks -- git --staged --redact=100 --no-banner` (non-zero exit on a finding; verified to catch a staged token and pass a clean tree), or without network `modules/scripts/secret-guard-scan.sh` over the changed files (strong tier only, prints counts, never the match). (d) **Firmware paths**: the existing `(^\|/)firmware/` check is right; also reject tracked `brcmfmac*`, `brcmbt*`, `*.clm_blob`, `*.txcap_blob`, `*.ptb`, `firmware.tar*` anywhere and anything under `/var/lib/firmware-src` (cannot be tracked, listed for completeness). If (c) is added, `nix flake check` stays out of `rebuild.sh` as before. |

| Open | You | The owner questions in the private audit; run the 7.1 test; decide when to rotate GitHub/Claude (section 4). |

## 9. Unverified assumptions

- `UserPromptSubmit` firing and blocking display under T3 (7.1, needs you).
- Hooks at user level under T3; hooks on REDRUM.
- What `~/.t3/userdata/secrets` contains and how a T3 session secret is
  invalidated (4.6).
- Which T3 tools besides `schedule_task` accept a `secretRef`.
- sops-nix itself: it was only evaluated, never activated on REDRUM (archived).
- Whether the tunnel UUIDs are real, and whether the Linkwarden literals
  were ever live.
- That the SSH key is passphrase-protected (inferred from `start.sh`).
- Anthropic-side retention of transcripts (stated by the hooks docs for the
  local transcript only).
