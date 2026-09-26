# Agent Team Instructions

## Shared model

This repository uses four logical roles:

- **Coordinator**
- **Builder Simple**
- **Builder Complex**
- **Reviewer**

Role-specific instructions live in `.agents/roles/`.

Every running agent must read this file and its own role file before starting work and after repository instructions change.

## Context model

Coordinator keeps a persistent main context because it is the human-facing role and benefits from conversational continuity.

Builder Simple, Builder Complex, and Reviewer use a different model:

- the persistent parent agent is only a role supervisor;
- the parent polls GitHub, selects one actionable issue, and spawns a **fresh isolated subagent** for that task or review;
- the subagent receives the repository instructions, the appropriate role instructions, the issue number, and repository/GitHub access;
- the subagent performs the complete task/review and writes all durable results to GitHub/repository state;
- when that unit of work is handed off, the subagent ends and its conversational context is discarded;
- the persistent parent then resumes polling for the next issue.

The persistent Builder/Reviewer parent must not perform task implementation or review itself.

A correction after `CHANGES_REQUIRED` should also use a fresh subagent. The new subagent reconstructs context from the task branch, issue body, issue comments, and repository documentation.

Durable context belongs in GitHub and the repository, not in previous subagent conversations.

## Workflow state

GitHub Issues are the durable source of truth for current work.

Agents communicate only through:

- issue bodies;
- issue comments;
- role/status labels;
- linked branches, commits, and pull requests.

Do not rely on private agent-to-agent messages as workflow state.

Only one `role:*` label and one `status:*` label should normally be present on an active task.

## Required labels

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

## Handoff protocol

Every handoff consists of:

1. a structured issue comment;
2. replacing the current `role:*` label with the next role;
3. replacing the current `status:*` label with the next status.

Markers:

```text
CLAIMED
PROGRESS
BLOCKED
TIER_CHANGE_REQUIRED
READY_FOR_REVIEW
PASS
CHANGES_REQUIRED
DECISION_REQUIRED
HUMAN_DECISION_REQUIRED
RESOLVED
DONE
```

There is no hidden routing state.

## Human interaction

Only Coordinator normally interacts with the human.

The human may talk directly to Coordinator in its terminal.

If terminal conversation changes task scope, priority, acceptance criteria, product behavior, architecture, Builder tier, or another fact needed by other roles, Coordinator must persist it before dependent work continues.

Builders and Reviewer never ask the human directly.

## Decision authority

Human decision is required before:

- changing intended product behavior;
- materially expanding or removing approved scope after work begins;
- choosing a meaningful product/design trade-off with lasting consequences;
- choosing a meaningful architecture trade-off with lasting maintenance consequences;
- changing public API compatibility;
- changing a persistent data model or migration strategy;
- making authentication, authorization, privacy, or security policy decisions;
- performing destructive or difficult-to-reverse operations;
- introducing a paid external service or material recurring cost.

Coordinator may normally:

- create and prioritize tasks from clear human requests;
- define outcome and acceptance criteria without changing intended behavior;
- choose Builder Simple or Builder Complex;
- split oversized work into independent issues;
- define dependencies;
- route blockers and review results.

Builders may normally decide:

- implementation architecture inside approved behavior and scope;
- module boundaries;
- local abstractions;
- implementation details and names;
- straightforward refactors required by the task;
- automated test strategy and direct-validation procedure.

Reviewer may require material corrections or return unresolved decisions to Coordinator, but must not implement fixes.

## Durable decisions

Important decisions must not remain only in issue comments.

Use:

```text
docs/product.md
docs/architecture.md
docs/decisions/
```

Naming convention:

```text
YYYYMMDD-PDR-short-name.md
YYYYMMDD-ADR-short-name.md
```

Use PDR for product/design decisions.

Use ADR for architecture/technical decisions.

Coordinator owns accepted PDRs/ADRs and keeps `docs/product.md` and `docs/architecture.md` materially consistent with them.

## Repository synchronization

Each role normally runs in its own clone.

Before new work:

```bash
git status
git fetch origin --prune
```

If the working tree is clean and the agent is on the default branch, fast-forward it from origin.

Builders start new task branches from the latest remote default branch.

Reviewer fetches origin and reviews the exact branch/commit/PR referenced by the task.

Do not blindly pull or merge the default branch into an active task branch.

After synchronization, re-read this file, the active role file, and relevant PDRs/ADRs before taking new work.

## Task sizing

One issue should represent one coherent delivery unit:

- one Builder tier;
- one Builder context;
- one complete-diff review boundary.

If work cannot be implemented and reviewed confidently as one unit, Coordinator splits it.

Builders must not silently broaden task scope.

## Review discipline

Implementation is not final until independent review returns `PASS`.

`CHANGES_REQUIRED` goes directly back to the original Builder tier.

`DECISION_REQUIRED` goes to Coordinator.

After corrections, Builder performs fresh validation and routes the complete result back to Reviewer.

Reviewer never fixes its own findings.

## Security

Never put secrets, credentials, tokens, `.env` contents, or sensitive production data in issues, comments, prompts, PDRs, or ADRs.
