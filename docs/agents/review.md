# Review tiers

A layered "council", cheapest first, so the Pro quota goes to the changes that
need it. Each tier only runs if the previous one passed. Record every tier's
result in the PR description's **Review** section.

| Tier | What | Cost | When |
| --- | --- | --- | --- |
| 0 | `./rebuild.sh check HOST...` (script syntax, tracked secrets/firmware, whitespace/conflict markers, registry row sync, eval of each host) + `./rebuild.sh build` of each affected host | free (no model) | always |
| 1 | `nix-reviewer` subagent (Haiku, low effort, read-only): AGENTS.md conventions on the branch diff | small | always |
| 2 | `lockout-reviewer` subagent (Sonnet, medium, read-only): "can this change lock me out of a machine?" | medium | only when the diff touches the lockout surface (below) |
| 3 | `deep-reviewer` subagent (Opus, high, read-only) | large | after two failed tier-1/2 rounds, for TODO effort ≥ 7, or when the human asks |

**Lockout surface** (triggers tier 2): `modules/essentials/{networking,ssh,users,keyring}.nix`,
`modules/server/{tailscale,cloudflared,t3code}.nix`, any `hardware.nix`,
`machine.nix` or `T2-PIN.md`, `flake.nix` inputs (`nixpkgs*`, `nixos-hardware`,
`home-manager`), `rebuild.sh`, `docs/schedules/bin/*` (runs unsandboxed), and any diff line mentioning `boot.`,
`fileSystems`, `networking.`, `firewall`, `services.openssh`, `users.users`,
`security.sudo`, `kernelPackages` or `system.stateVersion`. The `ship-pr` skill
greps for these.

## Rounds

1. The reviewer returns `VERDICT: PASS` or `VERDICT: CHANGES` with numbered
   findings (`file:line`, problem, concrete fix).
2. The implementing thread fixes, re-runs tier 0, and re-runs only the tier that
   asked for changes.
3. Two failed rounds at the same tier → escalate to tier 3 instead of looping.
4. A finding the implementer disagrees with goes into the PR description as an
   open question for the human, not into another round.

## Honest limits

- All tiers are the same vendor, so they share blind spots; tier 0 and real
  builds are the independent evidence. Do not count reviewer "votes".
- Subagents start cold: pass them the branch name and the hosts affected, not
  the whole conversation. They read the diff themselves (`git diff
  origin/master...HEAD`), which costs less than pasting it.
- Only Claude is enabled today. If a second provider (Codex, OpenCode) is
  enabled in T3 later, add it as an extra tier-2 reviewer through T3's
  `delegate_task` (separate `taskId` and `clientRequestId` per round, the prior
  findings in each new prompt). That gives a genuinely independent opinion at
  zero Claude quota.
- `/code-review` (low–high) is fine for a second look on large diffs; avoid
  `ultra` (billed, multi-agent).
