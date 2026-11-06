# Zen Handoff

Zen Handoff's goal is to **reduce cognitive load, not create more of it**, while keeping you in control of software development.

You describe the work; one coding agent coordinates implementation and review. Project knowledge stays in your repository, while GitHub Issues describe tasks and track their progress.

![Zen Handoff workflow: you and the primary agent communicate directly or through GitHub Issues; the primary agent coordinates implementation with the Builder and independent review with the Reviewer.](zen-handoff-workflow.svg)

> **Security warning:** Zen Handoff is not yet ready for use with public issues. Use it only in private repositories where everyone who can post or edit issues and comments is trusted. The workflow does not yet define how agents verify who may approve work or make decisions; untrusted content could be mistaken for instructions or approval.

## How it works

- **Primary agent:** your point of contact. It scopes tasks, tracks dependencies, and brings important decisions to you.
- **Builder subagent:** implements a task. It can keep its context through revisions of that task.
- **Reviewer subagent:** independently checks the complete result in a fresh context.

The primary agent manages these handoffs in one repository clone. You run only one agent session. Models and reasoning levels for subagent tasks are configured in `.agents/models.md`.

## Install in a project

1. Copy `template/` into your project, including the hidden `.agents/` and `.github/` directories.
2. Merge [AGENTS-template.md](template/AGENTS-template.md) into the project's `AGENTS.md`, or create that file if it does not exist. Do not install `AGENTS-template.md` as a separate file. Keep existing project instructions and GitHub configuration.
3. Enable GitHub Issues, create the labels listed in `AGENTS.md`, and commit the installed files to the default branch.

The agent needs Git, Bash, authenticated GitHub CLI (`gh`), `jq`, and a coding harness with isolated subagents and interruptible shell commands.

## Start working

Open one interactive coding-agent session in the project clone and start it with:

```text
Start Zen Handoff.
```

Adjust the preferred models in `.agents/models.md` to those available in your harness.

On startup, the agent checks GitHub Issues, required labels, and the request form. If anything is missing, it offers to complete setup with your approval.

## Plan an application or release

Ask the primary agent to help define the goal and scope, then propose a short task list with outcomes, dependencies, and suggested order. Plan broadly and detail the nearest tasks. After you confirm the plan, the agent creates issues in `status:triage`; move selected tasks to `status:ready` when you want implementation to start. A parent issue or milestone is optional.

## Work through GitHub

You can run the workflow entirely through GitHub Issues and comments; direct terminal conversation is optional.

1. On GitHub, open the repository's **Issues → New issue**, choose **Task request**, and fill in the form. Use this form for new tasks; only **Outcome** is required. Submitted issues start in `status:triage`.
2. When you want the agent to act, replace `status:triage` with `status:ready`. No role label or GitHub assignee is needed.
3. Add context, answer questions, and follow progress in the issue comments. The agent records handoffs and decisions there.

Moving an issue from `status:triage` to `status:ready` is the only label change you need to make. After approval, the agent manages workflow labels. When an issue needs your input (`status:blocked` and `human-needed`), simply reply in a comment; leave the labels unchanged. The agent checks your answer, records the decision, removes `human-needed` once your input is sufficient, and resumes work if no other blockers remain. Otherwise, it asks for clarification or keeps the issue blocked.

Issues move through `ready → in-progress → review → closed (completed)`. An issue marked `blocked` needs a dependency or decision. Labels describe only open work: on closure, the agent removes `status:*` and `human-needed`. Cancelled or duplicate issues close as **not planned**, with an explanation; this does not mean their work was delivered. Lasting product and architecture decisions are also recorded under `docs/`.

Detailed agent rules live in the installed `AGENTS.md` and `.agents/` files.

## License

[MIT](LICENSE).
