# Zen Handoff setup with OpenCode V2

Use this guide to configure Zen Handoff for another repository with four OpenCode sessions in tmux. This is an optional harness-specific setup, not part of the project files installed from `template/`.

## Configuration

1. Check whether [Zen Handoff](https://github.com/mateuszkowalczyk/zen-handoff) is already installed in the target repository. Only if it is missing, read the latest `README.md` from the Zen Handoff repository and follow its installation instructions.
2. Check that Bash, Git, GitHub CLI (`gh`), tmux, jq, and OpenCode V2 are available. Report missing tools or authentication requirements to the user; do not install tools or initiate authentication automatically.
3. Read the current Zen Handoff `README.md` and configure the target GitHub repository, even if Zen Handoff is already installed:
   - Ensure Issues are enabled and create all labels listed in the Zen Handoff `README.md`, including `status:triage`. Preserve unrelated labels and existing label settings; create only missing labels. Roles are labels, not GitHub user assignees.
   - Install or update `.github/ISSUE_TEMPLATE/zen-handoff-request.yml` from `template/`, preserving other issue templates. It must apply `role:coordinator` and `status:triage` so human requests enter Coordinator's queue only after human approval.
   - Ensure the shared/role instructions and `.agents/scripts/wait-for-issues.sh` match the current workflow, merging rather than replacing project-specific instructions.
   - Verify GitHub permissions for issue/label management and repository changes. Report missing access instead of initiating authentication. Do not change branch protection or other unrelated repository settings.
4. Ensure these installed files, including the issue form and polling script, are committed and available in the target repository's default branch before cloning, following its normal PR/merge policy. If access or required approval prevents this, report the blocker and stop. In an empty parent folder, create four independent clones:

   ```bash
   repo=OWNER/REPO
   for role in coordinator builder-simple builder-complex reviewer; do
       gh repo clone "$repo" "$role"
   done
   ```

5. Copy this setup's [`start-agents.sh`](start-agents.sh) into that parent folder and run `chmod +x start-agents.sh`. Edit its four model entries using valid OpenCode catalog IDs and model-supported reasoning variants: `provider/model#variant` (for example, `openai/gpt-6.1-sol#high`; use `medium`, not `mid`). Omit `#variant` to use the model's default. Confirm provider access is configured; do not initiate authentication automatically.

The configured layout should be:

```text
my-project/
├── start-agents.sh
├── coordinator/
├── builder-simple/
├── builder-complex/
└── reviewer/
```

Stop after configuration. Do not run `start-agents.sh` or start agents; the user will launch it themselves.

## Launching manually

When ready, open a single-pane tmux window in the parent folder and run:

```bash
./start-agents.sh
```

The script creates four tiled panes, creates a fresh OpenCode session with the configured model for each role, and opens its interactive CLI in the corresponding clone. Each agent reads `AGENTS.md` and its role instructions, then starts its autonomous work loop immediately, without waiting for confirmation. Idle GitHub polling runs in Bash every 60 seconds, not through repeated model calls. `status:triage` issues remain untouched until a human replaces that label with `status:ready`.
