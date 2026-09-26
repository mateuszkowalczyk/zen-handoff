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

## Quick start

Create four separate clones of the project repository:

```text
~/Work/my-project/
├── coordinator/
├── builder-simple/
├── builder-complex/
└── reviewer/
```

Run one persistent CLI agent from each clone.

Tell each agent:

```text
Read .agents/roles/<role-name>.md.
Start your autonomous work loop.
```

Replace `<role-name>` with the name of its clone: `coordinator`, `builder-simple`, `builder-complex`, or `reviewer`.

You can also pass the startup message at launch instead of typing it. From the corresponding clone, run one of:

```bash
codex "Read .agents/roles/<role-name>.md. Start your autonomous work loop."
```

```bash
claude "Read .agents/roles/<role-name>.md. Start your autonomous work loop."
```

```bash
opencode --prompt "Read .agents/roles/<role-name>.md. Start your autonomous work loop."
```

If your harness supports it, choose a model and reasoning effort for each role. For example, Builder Simple can use a smaller, cheaper model with lower reasoning effort than Builder Complex.

Give work to the Coordinator through its terminal or a GitHub Issue labeled `role:coordinator`; follow progress in the issue.

## Human interaction

Contact the **Coordinator** in its terminal, or through GitHub: create an issue or comment on an existing one labeled `role:coordinator`. The label routes the issue to the Coordinator's queue.

If another role needs a protected or ambiguous decision, it routes the relevant GitHub Issue to Coordinator.

Coordinator either resolves the decision within its authority or comments `HUMAN_DECISION_REQUIRED` in that issue and mentions the human.

Before related work continues, Coordinator records important outcomes from terminal conversations in the relevant issue or decision record. Lasting decisions also go in the relevant product or architecture docs and a PDR or ADR—not just issue comments.

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

After `PASS`, Coordinator verifies completion, follows the project's merge/close procedure, comments `DONE`, sets `status:done`, and closes the issue when appropriate.

Because agents communicate through GitHub Issues, their handoffs remain visible in issue comments and labels rather than hidden agent-to-agent state.

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
