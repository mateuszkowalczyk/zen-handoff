# Zen Handoff

Zen Handoff lets you develop software through one coding agent. You describe the work; the agent coordinates implementation and review. GitHub Issues and the repository keep the shared record.

> request → issue → implementation → independent review → completion

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

## Work through GitHub

You can run the workflow entirely through GitHub Issues and comments; direct terminal conversation is optional.

1. Submit an issue with the **Zen Handoff request** form. It starts in `status:triage`.
2. When you want the agent to act, replace `status:triage` with `status:ready`. No role label or GitHub assignee is needed.
3. Add context, answer questions, and follow progress in the issue comments. The agent records handoffs and decisions there.

Issues move through `ready → in-progress → review → done`. An issue marked `blocked` needs a dependency or decision. Lasting product and architecture decisions are also recorded under `docs/`.

Detailed agent rules live in the installed `AGENTS.md` and `.agents/` files.
