# Zen Handoff setup with OpenCode V2

Use this guide to configure Zen Handoff for another repository with four OpenCode sessions in tmux. This is an optional harness-specific setup, not part of the project files installed from `template/`.

## Configuration

1. Check whether [Zen Handoff](https://github.com/mateuszkowalczyk/zen-handoff) is already installed in the target repository. Only if it is missing, read the latest `README.md` from the Zen Handoff repository and follow its installation instructions.
2. Check that Bash, Git, GitHub CLI (`gh`), tmux, jq, and OpenCode V2 are available. Report missing tools or authentication requirements to the user; do not install tools or initiate authentication automatically.
3. Ensure the installed Zen Handoff files are committed and available in the target repository's default branch before cloning. In an empty parent folder, create four independent clones:

   ```bash
   repo=OWNER/REPO
   for role in coordinator builder-simple builder-complex reviewer; do
       gh repo clone "$repo" "$role"
   done
   ```

4. Copy this setup's [`start-agents.sh`](start-agents.sh) into that parent folder and run `chmod +x start-agents.sh`. Edit its four model entries using valid OpenCode catalog IDs and model-supported reasoning variants: `provider/model#variant` (for example, `openai/gpt-6.1-sol#high`; use `medium`, not `mid`). Omit `#variant` to use the model's default. Confirm provider access is configured; do not initiate authentication automatically.

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

The script creates four tiled panes, creates a fresh OpenCode session with the configured model for each role, and opens its interactive CLI in the corresponding clone. Each agent reads `AGENTS.md` and its role instructions, then waits for user confirmation before starting work. Confirm in each pane when you want that role to begin its autonomous work loop.
