# Zen Handoff instructions

Merge this section into the project's existing `AGENTS.md`. Project-specific instructions still apply.

## One primary agent

Run one persistent, human-facing primary agent in one repository clone. It owns coordination, issue scope and priority, dependencies, decisions, and final completion. It may delegate bounded implementation and review work to fresh isolated subagents, but it manages their lifecycle, sequencing, and handoffs. No launcher, second role session, or additional clone is required. Do not let concurrent subagents edit or switch the shared worktree.

Keep the primary context for human conversation and coordination. Use GitHub Issues and repository files for durable state. Record team-relevant outcomes from terminal conversations in the issue or decision record before dependent work continues. Do not rely on conversational memory or private subagent messages as the only record.

The primary agent should delegate actual implementation to a Builder subagent and each complete-diff review pass to a separate fresh Reviewer subagent. It focuses on coordination, human interaction, and verifying handoffs rather than doing the Builder's work itself. Start a fresh Builder context for a new issue. If isolated subagents are unavailable, tell the human that independent review cannot run as specified.

## Assigning subagents

Read `.agents/models.md` and choose a model and reasoning level for each task. These are preferences, not harness-specific definitions. Use the nearest available setting if the harness cannot honor them; use defaults if per-subagent selection is unavailable. Do not create static subagent configurations merely to select models.

For each assignment, include the issue number, scope, acceptance criteria, constraints, branch/base or exact review diff, and the applicable role file in the prompt. Instruct the subagent to read `AGENTS.md`, its `.agents/roles/` file, relevant docs/decisions, and the full issue history. Quote essential role boundaries in the prompt if the harness may not load local files. Give repository and GitHub access as needed. Wait for its handoff and verify durable results before starting another shared-worktree task. The primary agent handles status changes and human communication.

Keep a Builder subagent available during an active issue when the harness supports it and continuity helps: send follow-up instructions to the same subagent for clarification, iterative implementation, and corrections after review. During a Reviewer pass, the Builder must be idle and must not edit the shared worktree. Give every review pass a fresh Reviewer context, independent of the Builder and previous review passes. End the Builder context when the issue is completed or parked for a long time. If the Builder cannot be retained, start a fresh one and reconstruct context from the issue, branch, and repository; never make its private conversation the only source of task state.

Use Builder Simple for localized, clear, low-risk work; Builder Complex for cross-cutting, uncertain, high-risk, or domain-heavy work. Record `Builder tier: simple | complex` in the issue so corrections use the same tier. Reviewer is independent and read-only with respect to implementation. No role label or role-specific session is needed.

## Startup configuration check

On startup, check that GitHub Issues are enabled, the required labels below exist, and a task request form is present under `.github/ISSUE_TEMPLATE/` on the default branch. The form should collect an outcome, acceptance criteria, context/constraints, and dependencies, require only the outcome, and apply `status:triage`. An equivalent existing form is sufficient.

If configuration is missing, briefly list the gaps and offer to complete setup. Only after human approval, enable Issues, create missing labels, and add a **Task request** form where needed, preserving existing settings and forms. Follow project policy for committing and merging the form onto the default branch. Report access or authentication failures separately; do not treat them as missing configuration. If setup is complete, continue without a setup announcement.

## Planning

When starting an application or planning a release, the primary agent clarifies the goal, constraints, and what is out of scope with the human. Propose a short task list with expected outcomes, dependencies, and suggested order. Plan the whole effort broadly and detail the nearest tasks; do not design everything up front.

After the human confirms the plan, create GitHub Issues using the task body structure below and record dependencies. These issues start in `status:triage`; approval of the plan is not approval to implement it. The human starts selected tasks by changing them to `status:ready`. A parent issue or milestone is optional, not required. This planning path does not change the existing rule for child tasks within an already approved parent's scope.

## Workflow state and approval

GitHub Issues are the source of truth. Use issue bodies and comments, status labels, native dependencies, and linked branches/commits/PRs. Required labels:

```text
status:triage
status:ready
status:in-progress
status:review
status:blocked
human-needed
priority:high
```

Exactly one `status:*` label should normally be present on an open issue. Labels describe stages of open work; GitHub's closed state and reason record its end. `status:triage` wins over every other label: do not claim, analyze, scope, comment on, route, implement, or review a triaged issue. Only the human may remove it. The human approves an issue by replacing `status:triage` with `status:ready`. A terminal request or comment does not bypass this gate. If triage appears during work, stop issue actions and safely preserve local work. New speculative issues start in triage. Approved child tasks may be created within an approved parent's scope.

Check labels and dependencies before every action and handoff. Record dependencies with GitHub Issues' native **blocked by** relationship and in the issue body. Keep a task `status:blocked` until blockers deliver their required result; closure as duplicate or not planned is not proof of delivery. If native dependencies are unavailable, document `Blocked by #...` and check manually.

The primary agent scopes approved issues as one coherent delivery unit with acceptance criteria, Builder tier, dependencies, and constraints. It changes `status:ready` to `status:in-progress` before implementation, then to `status:review` after a validated Builder handoff. A Reviewer `PASS` returns the issue to the primary agent for verification, merge under project policy, a completion comment, and closure as **completed**. `CHANGES_REQUIRED` returns the same branch to the Builder when still available, or a fresh Builder otherwise, followed by a fresh review. `DECISION_REQUIRED` or a blocker moves the issue to `status:blocked` until resolved. Recheck current state before each transition.

On closure, remove all `status:*` labels and `human-needed`; do not use a done label. Close delivered work as **completed**. When work is cancelled or closed as a duplicate under project policy, explain why and close it as **not planned**, not completed. Closure alone does not prove that a dependency delivered its required result.

Use this task body structure so a fresh subagent can reconstruct the assignment:

```markdown
## Outcome
<one coherent result>

## Builder tier
simple | complex

## Acceptance
- <observable condition>

## Dependencies
<issue numbers or None>

## Context
<relevant background>

## Constraints
<constraints or None>

## Builder notes
Pending

## Validation
Pending

## Review
Pending
```

When a task is too large for one implementation and review boundary, split it into independently deliverable issues. A Builder that finds its tier unsuitable or a protected decision unresolved reports this to the primary agent; it does not silently expand scope. For a review handoff, record the branch/commit/PR, validation results, files changed, and known risks. The Reviewer records specific actionable findings or evidence for `PASS`. The primary agent checks the handoff before updating labels.

Every handoff has a substantive issue comment and corresponding status label change. Labels express lifecycle state; comments should not start with `CLAIMED`, `PROGRESS`, `BLOCKED`, `READY_FOR_REVIEW`, `RESOLVED`, or `DONE`. When useful, place `Outcome: PASS`, `CHANGES_REQUIRED`, `DECISION_REQUIRED`, `TIER_CHANGE_REQUIRED`, or `HUMAN_DECISION_REQUIRED` after the explanation. Every agent-authored GitHub issue or PR comment, including subagent comments, ends with exactly:

```text
— Agent
```

Post meaningful updates, not idle polling comments.

## Writing for humans

All agents should keep issue and PR titles, descriptions, comments, documentation, and human-facing messages concise and easy to understand. Lead with the result, question, or needed action. Use plain language and omit repetition and process narration without losing information needed to act, implement, or review. Use short paragraphs and simple Markdown; add headings, lists, or code blocks only when they improve readability.

Before publishing or sending, always make a final readability pass: remove unnecessary words, check that the meaning and any next action are clear to a human, and verify readable formatting. Preserve required task sections, evidence, and comment signatures.

## Continuous coordination

The primary agent reassesses the project on startup, after task completion or handoffs, when polling detects changes, and after human messages. Resume active work or start eligible approved work according to priorities and dependencies. Resolve routine blockers within existing authority; when human action is needed, briefly explain the blockers and concrete next steps.

If there are no open issues, suggest planning the next tasks. If all open issues are in triage, explain that selected tasks need human approval through `status:ready`, without analyzing or acting on their contents. If all remaining work is blocked, summarize what would unblock it. Never bypass approval or expand scope. Give a useful update before waiting, but do not repeat unchanged advice or post idle reminders; notify the human again only when the situation materially changes or they ask.

## Idle waiting

Start the autonomous loop after reading instructions and assessing the project. When idle, after any needed human update, use `.agents/scripts/wait-for-issues.sh` with one private snapshot file outside the repository:

```bash
poll_snapshot=$(mktemp)
bash .agents/scripts/wait-for-issues.sh "$poll_snapshot"
```

The script checks immediately, then silently polls every 60 seconds until the eligible queue, open/triage issue counts, or a native blocker changes. Reuse the same snapshot for later waits. Treat its output as notification: reassess the situation, and read full issue history and recheck labels/dependencies before acting on an approved issue. Keep the wait interruptible for human input. Report API/authentication errors; do not treat them as an empty queue. `ZEN_HANDOFF_POLL_SECONDS` may override the interval when explicitly configured.

## Human interaction and decisions

Only the primary agent talks to the human. The human may communicate entirely through GitHub Issues and comments; treat relevant comments on approved issues as input and respond there. Direct terminal conversation is optional. Subagents report questions and findings to the primary agent. Ask for a human decision before changing intended product behavior, materially expanding or removing approved scope, making lasting product or architecture trade-offs, changing public API compatibility or persistent data/migration strategy, deciding authentication/authorization/privacy/security policy, performing destructive or difficult-to-reverse work, or introducing a paid service or material recurring cost.

The primary agent may scope clear requests, prioritize and split tasks, select a Builder tier, set dependencies, route review outcomes, and resolve routine blockers. Builders choose implementation details within approved scope. Reviewer can require material corrections but does not implement them.

When human input is required, explain the decision in an issue comment with `Outcome: HUMAN_DECISION_REQUIRED`, add `human-needed`, and set `status:blocked`. After the reply, record the decision and rationale, remove `human-needed`, update lasting documentation, and resume work.

Accepted product/design decisions use PDRs; architecture/technical decisions use ADRs. Create them under `docs/decisions/` from `.agents/templates/` with names `YYYYMMDD-PDR-short-name.md` and `YYYYMMDD-ADR-short-name.md`. Keep `docs/product.md` and `docs/architecture.md` consistent.

## One repository clone

Before new work, inspect `git status` and fetch origin. Fast-forward a clean default branch when safe. Create a task branch from the latest remote default branch, or resume its existing branch for corrections. Complete or safely park one task before switching branches. Reviewer inspects the exact branch/commit/PR against its intended base after Builder finishes; it does not edit the worktree. Do not blindly pull or merge the default branch into an active task branch. Re-read changed instructions and relevant decisions after synchronization.

## Security

Never put secrets, credentials, tokens, `.env` contents, or sensitive production data in issues, comments, prompts, PDRs, or ADRs.
