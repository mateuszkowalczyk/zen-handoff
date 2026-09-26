# Zen Handoff

An autonomous agent workflow for software development. Its goal is to keep the human in the loop while reducing cognitive load. Team communication and handoffs are centered on GitHub Issues.

## Philosophy

Zen Handoff is built around a simple idea: **autonomous agents should reduce cognitive load, not create more of it**.

Work with agents much as you would with human coworkers: discuss what needs doing with a primary point of contact, track the work in GitHub Issues, and use issue comments for questions, decisions, and handoffs. The **Coordinator** is that primary contact. You mostly talk to it; it turns requests into scoped issues, assigns work to Builders, handles blockers and review outcomes, and brings decisions back to you when needed.

The intended rhythm is:

> human request → Coordinator scopes an issue → Builder implements → Reviewer checks → Coordinator closes the loop

GitHub Issues and the repository hold the shared record, including important outcomes from conversations with Coordinator. Each role-to-role handoff is explicit, so the human can follow the work without managing every agent directly. Fresh task contexts help Builders and Reviewer focus on their current assignment; the handoff model, not conversational memory, keeps the team coordinated.

## Roles

Four roles divide the work, with clear responsibilities and explicit handoffs between them.

- **Coordinator** — human-facing agent; owns task scope, acceptance, routing, priorities, and durable decisions.
- **Builder Simple** — handles localized, well-understood, low-risk implementation work.
- **Builder Complex** — handles cross-cutting, uncertain, high-risk, or domain-heavy implementation work.
- **Reviewer** — independently reviews the complete task diff and remains read-only.

Agents communicate through **GitHub Issues, comments, labels, and linked branches or pull requests**.

There is no message bus, orchestration server, custom database, or polling daemon.

## Runtime model

Use four separate clones of the same project repository:

```text
~/Work/my-project/
├── coordinator/
├── builder-simple/
├── builder-complex/
└── reviewer/
```

Run one persistent CLI agent in each clone.

```text
Coordinator       persistent interactive context

Builder Simple    persistent role supervisor
                  └── fresh subagent per task

Builder Complex   persistent role supervisor
                  └── fresh subagent per task

Reviewer          persistent role supervisor
                  └── fresh subagent per review pass
```

The Builder and Reviewer parent agents only poll, select work, and delegate it to fresh isolated subagents.

Task-local conversational context is discarded after every handoff. Durable context lives in GitHub and the repository.

## Installing Zen Handoff in a project

Copy the contents of `template/` into your project repository.

The exception is:

```text
template/AGENTS-template.md
```

Do **not** simply copy it as a separate file.

Its contents should be **inserted into your project's existing `AGENTS.md`**.

If the project does not yet have an `AGENTS.md`, create one from `AGENTS-template.md`.

The resulting project should contain roughly:

```text
AGENTS.md

.agents/
  roles/
    coordinator.md
    builder-simple.md
    builder-complex.md
    reviewer.md
  templates/
    PDR-template.md
    ADR-template.md

docs/
  product.md
  architecture.md
  decisions/
```

Preserve any existing project-specific instructions in `AGENTS.md`. Zen Handoff's shared instructions should complement them rather than replace them.

## Required GitHub labels

Create:

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

## Starting the agents

Start your preferred CLI coding agent in each clone.

For example:

```text
cd ~/agents/my-project/coordinator
codex
```

Then tell it:

```text
Read AGENTS.md and .agents/roles/coordinator.md.
Start your autonomous work loop.
```

Repeat with the corresponding role file for the other three clones.

Zen Handoff is intentionally tool-agnostic. The runtime can be Codex CLI, Claude Code, Pi, OMP, or another harness that provides shell, Git, GitHub CLI, and isolated subagent support.

## Human interaction

Talk directly to the **Coordinator**.

If another role needs a protected or ambiguous decision, it routes the relevant GitHub Issue to Coordinator.

Coordinator either resolves the decision within its authority or comments `HUMAN_DECISION_REQUIRED` in that issue and mentions the human.

Any important decision made through the Coordinator terminal must be persisted into the relevant issue, product/architecture documentation, PDR, or ADR before dependent work continues.

## Handoffs

Every role-to-role handoff consists of:

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

There is no hidden agent-to-agent communication state.

## Durable decisions

Current product and architecture state lives in:

```text
docs/product.md
docs/architecture.md
```

Important decisions are recorded under:

```text
docs/decisions/
```

Coordinator creates PDRs and ADRs there using the reusable templates in `.agents/templates/`.

Naming convention:

```text
YYYYMMDD-PDR-short-name.md
YYYYMMDD-ADR-short-name.md
```

For example:

```text
20260926-PDR-account-linking.md
20260926-ADR-identity-storage.md
```

Coordinator records accepted decisions as **PDRs** when they mainly affect what the product does or how the user experiences it.

Coordinator records accepted decisions as **ADRs** when they mainly affect how the system is built.
