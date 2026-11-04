---
name: start-todo
description: Launch a T3 thread for one TODO.md item in its own worktree and todo/<slug> branch, with the model and effort that match the item's effort score. Use when the human asks to start, pick up or spin off a TODO item.
---

# Start a TODO item

1. Find the item in `TODO.md` (top-level `- [ ] **Title** — … — **N/10**`).
   Read only that item and its sub-items. If the human named several, repeat
   per item, at most three build-heavy threads in flight.
2. Slug: lowercase title, words joined by `-`, ≤ 40 chars (e.g.
   `todo/rebuild-warnings-catcher`). Check `git ls-remote --heads origin
   'todo/*'` and T3's `t3_thread_list` so you do not duplicate a branch or
   thread.
3. Pick the model from the score (docs/agents/workflow.md, "Model and effort"):
   1–3 Sonnet/medium, 4–6 Sonnet/high, 7–10 Opus in plan mode first (then
   Sonnet/high implements). Resolve the exact provider instance and model IDs
   with `orchestrator_capabilities`; never guess IDs.
4. Launch with `t3_thread_launch` (no idempotency key: on error, check
   `t3_thread_list` before retrying):
   - `title`: the item title
   - `workspaceStrategy`: `{"type":"worktree","baseRef":"master","branch":"todo/<slug>","startFromOrigin":true}`
   - model/effort from step 3; interaction mode `plan` for 7–10
   - `message`: the item text verbatim, then: "Follow AGENTS.md → Change
     workflow. Verify with ./rebuild.sh check/build, run the review tiers via
     the ship-pr skill, remove this item from TODO.md in the same branch, and
     do not push or open the PR until I say so."
5. Report the thread link `[title](t3-thread://v1/<threadId>)`, branch and
   model to the human.
