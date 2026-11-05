# Zen Handoff Repository Instructions

This repository contains the Zen Handoff workflow and the template intended to be installed into other software projects.

## Repository structure

The root of this repository contains Zen Handoff itself.

Files under:

```text
template/
```

are **template artifacts for user projects**, not active Zen Handoff runtime configuration.

In particular:

```text
template/AGENTS-template.md
```

contains instructions intended to be inserted into a user's project-level `AGENTS.md`.

Do not interpret `AGENTS-template.md` as instructions governing development of the Zen Handoff repository itself.

## When modifying Zen Handoff

Preserve the core philosophy:

- reduce cognitive load rather than creating more agent activity;
- prefer explicit handoffs over hidden coordination;
- use GitHub Issues as durable workflow state;
- keep the system understandable without a custom orchestration service;
- keep roles few and responsibilities clear;
- run one persistent human-facing primary agent in one repository clone;
- use a fresh isolated Builder context for each new task and a fresh Reviewer context for each review pass;
- allow the Builder to retain context through iterations of the same task when useful;
- let the primary agent manage subagent assignments and handoffs;
- prefer repository state and GitHub over conversational memory;
- avoid adding infrastructure unless it solves a demonstrated problem.

## Template changes

When changing files under `template/`:

- treat them as user-facing artifacts;
- keep them tool-agnostic where practical;
- keep `README.md` consistent with the template;
- preserve the documented installation model;
- ensure `AGENTS-template.md` can be merged into an existing project `AGENTS.md` rather than assuming it owns the whole file;
- avoid instructions that depend on Zen Handoff's own repository structure unless they are explicitly part of the installed template.

## Scope

Do not add scripts, daemons, message buses, databases, dashboards, or orchestration services by default.

Zen Handoff should remain a small convention-based workflow built primarily from:

- GitHub Issues;
- Git;
- repository documentation;
- role instructions;
- interactive coding-agent harnesses;
- isolated subagents.

More infrastructure should only be introduced when the simpler model has a concrete limitation that justifies it.
