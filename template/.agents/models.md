# Subagent model preferences

The primary agent reads this file when assigning work. These are preferences, not harness configuration. Replace the example model IDs and reasoning levels with models available in your coding-agent harness. Use the nearest available option if an exact model or reasoning level cannot be selected; continue the workflow and mention the limitation only when it affects quality or cost materially.

| Task | Model | Reasoning level |
| --- | --- | --- |
| Localized implementation (Builder Simple) | `gpt-6-luna` | `low` |
| Complex implementation (Builder Complex) | `gpt-6.1-sol` | `high` |
| Independent review (Reviewer) | `gpt-6-astra` | `high` |

Choose a model and reasoning level for each subagent by the actual task. Do not create persistent harness-specific agent definitions or launch scripts for these roles. If the harness cannot select models or reasoning levels per subagent, use its defaults.
