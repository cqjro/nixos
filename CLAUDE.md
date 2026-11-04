@AGENTS.md

# Claude Code notes

AGENTS.md (imported above) is the shared source of truth for every agent; this
file only adds what is specific to Claude Code under T3. Do not copy shared
rules here. Keep the `@AGENTS.md` line. By default, Claude Code (2.1.x,
`agents_md_mode` `claude-md-or-agents-md`) loads AGENTS.md only when a project
has no CLAUDE.md, so this import is what loads it now. Imported files are not
loaded twice.

- **Subagents** (`.claude/agents/`): `nix-reviewer` (tier 1, Haiku),
  `lockout-reviewer` (tier 2, Sonnet), `deep-reviewer` (tier 3, Opus). All are
  read-only. Run them through the review tiers in `docs/agents/review.md`, and
  pass the branch and affected hosts rather than the conversation.
- **Skills** (`.claude/skills/`):
  - `start-todo` launches a worktree thread per TODO item with the mapped model.
  - `ship-pr` covers tier 0–3, push and PR.
  - `merge-pr` does the squash merge and gives the rollout steps.
- **T3 tools** (`mcp__t3-code__*`) are deferred, so load them with `ToolSearch` before use:
  - **PRs:** call `link_pull_request` after creating or touching a PR. When asked to babysit one, call `watch_pull_request` and end the turn. Call `unwatch_pull_request` when handing back.
  - **Threads:** use `t3_thread_launch` with `workspaceStrategy` for new branch threads.
  - **Secrets:** use `request_secret` for any secret the human must provide.
- **mcp-nixos** tools are deferred too (see AGENTS.md, "Using mcp-nixos").
- **Quota.** The account is on a Pro plan and every thread shares one quota:
  - Keep subagent prompts short.
  - Prefer `--stat` and targeted hunks over whole diffs.
  - Do not re-read a file you just edited.
