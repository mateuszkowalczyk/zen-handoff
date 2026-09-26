# Zen Handoff

A minimal autonomous multi-agent workflow for software development.

## Philosophy

Zen Handoff is built around a simple idea: **autonomous agents should reduce cognitive load, not create more of it**.

Instead of a noisy swarm or heavyweight orchestration layer, work moves calmly through a few clear roles. GitHub Issues hold the durable state, each handoff is explicit, and task-local agent context is discarded when the work is done.

The intended rhythm is:

> clear task → focused agent → explicit handoff → fresh context

Humans stay in control through the Coordinator, while Builders and Reviewer work independently without carrying unnecessary conversational baggage from one task to the next.

## Roles

- **Coordinator** — human-facing agent; owns task scope, acceptance, routing, priorities, and durable decisions.
- **Builder Simple** — localized, well-understood, low-risk implementation work.
- **Builder Complex** — cross-cutting, uncertain, high-risk, or domain-heavy implementation work.
- **Reviewer** — independent, read-only review of the complete task diff.

Agents communicate only through **GitHub Issues, comments, labels, and linked branches/PRs**.

There is no message bus, orchestration server, custom database, or polling daemon.

## Files

```text
AGENTS.md
README.md

.agents/
  roles/
    coordinator.md
    builder-simple.md
    builder-complex.md
    reviewer.md

docs/
  product.md
  architecture.md
  decisions/
    PDR-template.md
    ADR-template.md
```

## Required GitHub labels

```text
role:coordinator
role:builder-simple
role:builder-complex
role:reviewer

status:ready
status:in-progress
status:review
status:blocked
status:done

human-needed
priority:high
```

## Runtime

Use four separate clones of the same repository:

```text
~/agents/my-project/
├── coordinator/
├── builder-simple/
├── builder-complex/
└── reviewer/
```

Start one interactive CLI coding agent in each clone.

The runtime model is:

```text
Coordinator       persistent interactive context

Builder Simple    persistent role supervisor
                  └── fresh subagent per task

Builder Complex   persistent role supervisor
                  └── fresh subagent per task

Reviewer          persistent role supervisor
                  └── fresh subagent per review pass
```

This keeps the terminals and role supervisors alive while discarding task-local LLM context after each handoff.

Example:

```text
cd ~/agents/my-project/coordinator
codex
```

Then tell it:

```text
Read AGENTS.md and .agents/roles/coordinator.md.
Start your autonomous work loop.
```

Repeat with the matching role file for the other clones.

The runtime may be Codex CLI, Pi, OMP, Claude Code, or another interactive CLI agent with shell, Git, GitHub CLI, and isolated subagent/task-context support.

Builder/Reviewer parent agents only poll and delegate. They do not implement or review directly. Each task or review pass is executed in a fresh subagent context, which reconstructs all necessary state from the repository and GitHub Issue.

## Human interaction

Talk directly to Coordinator in its terminal.

If another role needs a protected or ambiguous decision, it routes the relevant issue to Coordinator.

Coordinator either decides within its authority or comments `HUMAN_DECISION_REQUIRED` in that issue and mentions the human.

Any important decision made in the Coordinator terminal must be persisted into the relevant issue, `docs/product.md`, `docs/architecture.md`, or a PDR/ADR before dependent work continues.

## Durable decisions

Use:

```text
docs/product.md
docs/architecture.md
docs/decisions/
```

Naming:

```text
YYYYMMDD-PDR-short-name.md
YYYYMMDD-ADR-short-name.md
```

Examples:

```text
20260926-PDR-account-linking.md
20260926-ADR-identity-storage.md
```

Use a **PDR** when the decision mainly affects what the product does or how the user experiences it.

Use an **ADR** when the decision mainly affects how the system is built.

If multiple decisions of the same type and short name occur on the same day, make the slug more specific rather than adding sequence numbers.

## Handoff rule

Every handoff is:

> structured issue comment + role/status label change

Typical flow:

```text
Coordinator
    ↓
Builder Simple / Builder Complex
    ↓
Reviewer
    ├── PASS → Coordinator
    ├── CHANGES_REQUIRED → original Builder
    └── DECISION_REQUIRED → Coordinator
```
