## Summary

<!-- What changed and why, in 1–3 sentences. Title = the squash commit subject. -->

- TODO item: <!-- title from TODO.md (removed in this PR), or n/a -->
- Branch: `todo/<slug>`

## Hosts affected

- [ ] GOD-KILLER
- [ ] REDRUM
- [ ] LittleNix

## Verification

<!-- Paste results, not promises. Mark anything untested as untested. -->

- `./rebuild.sh check …`:
- `./rebuild.sh build …` (machine it ran on):
- Closure diff summary:
- Test activation (`./rebuild.sh test|dry HOST`), if any:

## Review

- Tier 1 `nix-reviewer`:
- Tier 2 `lockout-reviewer` (only for lockout-surface changes):
- Tier 3 `deep-reviewer` (only if escalated):
- Open questions for the human:

## Rollout

<!-- Per host, after merge: cd ~/.nixos && git pull --ff-only && ./rebuild.sh switch HOST.
     Manual steps (secrets, tunnels, firmware), dry-run first, console access needed? -->

## Docs

- [ ] README.md / AGENTS.md / docs/agents updated (or not needed: why)
- [ ] Upstream registry rows added/removed in both README.md and docs/agents/upstream-registry.md
