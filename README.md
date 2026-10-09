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
  scripts/
    wait-for-issues.sh

.github/
  ISSUE_TEMPLATE/
    zen-handoff-request.yml

docs/
  product.md
  architecture.md
  decisions/
```

Preserve any existing project-specific instructions in `AGENTS.md`. Zen Handoff's shared instructions should complement them rather than replace them.

Include the hidden `.agents/` and `.github/` directories when copying. Preserve existing issue templates and other GitHub configuration. The human-facing issue form applies `role:coordinator` and `status:triage`; these are routing labels, not a GitHub user assignment. Commit the installed files to the project's default branch through its normal review/merge procedure before creating the role clones.

## Required GitHub labels

Create:

```text
role:coordinator
role:builder-simple
role:builder-complex
role:reviewer

status:triage
status:ready
status:in-progress
status:review
status:blocked
status:done

human-needed
priority:high
```

During setup, the configuring agent must enable GitHub Issues if necessary and create missing labels in the target repository, not merely list them for the human. Preserve existing labels/settings; do not change unrelated repository settings or branch protections. Verify access for issue/label management and publishing the issue form; report missing permissions or authentication rather than initiating sign-in automatically.

### Triage and approval

`status:triage` means an idea or task is not yet approved for agent work. **No agent, including Coordinator, acts on it or removes this label.** This gate wins even if another status label is accidentally present.

Use the **Zen Handoff request** issue form to submit an idea. When ready for Coordinator to handle it, the human replaces `status:triage` with `status:ready`, leaving `role:coordinator`. A comment alone does not bypass triage. Applying triage during active work pauses further agent actions on that issue.

## Quick start

All roles require Bash, Git, authenticated GitHub CLI (`gh`), and `jq` for the shared polling script. Use an interactive coding-agent harness that supports fresh isolated subagents and interruptible long-running shell commands. The optional OpenCode launcher additionally requires tmux and OpenCode V2.

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

### Optional OpenCode V2 setup

See the [OpenCode setup guide](integrations/opencode/setup.md) for configuring the target GitHub repository, four independent clones, and per-role models. Its companion [tmux launcher](integrations/opencode/start-agents.sh) opens four tiled OpenCode sessions and starts their autonomous loops immediately. Setup itself does not launch agents. These integration files are separate from `template/`; copy the launcher into the clones' parent folder, not into each project clone.

### Idle polling

All roles use the installed [Bash polling script](template/.agents/scripts/wait-for-issues.sh), checking GitHub every **60 seconds** while idle. The script waits silently and returns control to the model only when an eligible queue changes or an error occurs; unchanged blocked issues do not cause repeated model calls. Coordinator also watches native blockers' completion state. Each session reuses its own temporary snapshot file outside the repository. No polling daemon or orchestration service is needed.

The interval can be explicitly overridden with `ZEN_HANDOFF_POLL_SECONDS`. Human terminal input remains interruptible; API/authentication errors are reported rather than silently ignored.

## Human interaction

Contact the **Coordinator** in its terminal, or through GitHub: use the issue form and approve the request as described above, or comment on an approved issue labeled `role:coordinator`. That role label routes approved issues to Coordinator; `status:triage` prevents agent action.

If another role needs a protected or ambiguous decision, it routes the relevant GitHub Issue to Coordinator.

Coordinator either resolves the decision within its authority or posts a comment with `Outcome: HUMAN_DECISION_REQUIRED` after the explanation and mentions the human.

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

After `PASS`, Coordinator verifies completion, follows the project's merge/close procedure, comments a concise completion summary, sets `status:done`, and closes the issue when appropriate.

Agent comments start with useful content, not a lifecycle status already expressed by labels. Review results and decision requests use an `Outcome:` field after the content. Every agent comment ends with its role signature, for example `— Agent: reviewer`; task/review subagents sign with their supervising role.

Because agents communicate through GitHub Issues, their handoffs remain visible in issue comments and labels rather than hidden agent-to-agent state.

## Task dependencies

Coordinator records dependencies using GitHub Issues' native **blocked by** relationship and lists the blocking issue numbers in the task's `Dependencies` section. For example, if #42 requires #17, mark #42 as blocked by #17 and keep #42 `role:coordinator` / `status:blocked`.

Coordinator routes the task to its Builder with `status:ready` only after all required results are delivered. A blocker closed as not planned or duplicate does not automatically satisfy the dependency. Builders and Reviewer recheck dependencies before acting. See the [Coordinator instructions](template/.agents/roles/coordinator.md) for an API example and handling unavailable native relationships.

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
