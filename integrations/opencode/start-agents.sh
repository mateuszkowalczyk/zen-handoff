#!/usr/bin/env bash
set -euo pipefail

# Run ./start-agents.sh in a single-pane tmux window.
# Edit each role independently: provider/model#reasoning-effort.
# Example: openai/gpt-6.1-sol#high; supported variants depend on the model.
# Omit #effort to use the model's default.
declare -A models=(
    [coordinator]='openai/gpt-6-luna#high'
    [builder-simple]='openai/gpt-6-luna#high'
    [builder-complex]='openai/gpt-6.1-sol#medium'
    [reviewer]='openai/gpt-6.1-sol#high'
)

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
script="$root/$(basename -- "${BASH_SOURCE[0]}")"

if [[ -z ${TMUX:-} ]]; then
    echo 'Run this script inside tmux.' >&2
    exit 1
fi

# Each new pane runs this script with its role as the argument.
if [[ $# == 1 ]]; then
    role=$1
    model=${models[$role]}
    variant=''
    if [[ $model == *'#'* ]]; then
        variant=${model#*#}
        model=${model%%#*}
    fi
    cd -- "$root/$role"

    # OpenCode V2's full-screen CLI has no --model flag, so set it when
    # creating the session, then open that session in the interactive UI.
    body=$(jq -nc --arg role "$role" --arg directory "$PWD" \
        --arg provider "${model%%/*}" --arg model "${model#*/}" --arg variant "$variant" \
        '{title: ("Zen Handoff — " + $role), location: {directory: $directory},
          model: ({providerID: $provider, id: $model} +
            (if $variant == "" then {} else {variant: $variant} end))}')
    session=$(opencode api post /api/session --data "$body" | jq -er '.data.id')
    prompt="Read AGENTS.md and .agents/roles/$role.md. Act as $role, but wait for user confirmation before starting work."
    tmux select-pane -t "$TMUX_PANE" -T "$role"
    exec opencode "$PWD" --session "$session" --prompt "$prompt"
fi

if [[ $# != 0 || $(tmux display-message -p -t "$TMUX_PANE" '#{window_panes}') != 1 ]]; then
    echo 'Run ./start-agents.sh without arguments in a single-pane tmux window.' >&2
    exit 1
fi

right=$(tmux split-window -h -t "$TMUX_PANE" -c "$root/builder-simple" \
    -P -F '#{pane_id}' bash "$script" builder-simple)
tmux split-window -v -t "$TMUX_PANE" -c "$root/builder-complex" \
    bash "$script" builder-complex
tmux split-window -v -t "$right" -c "$root/reviewer" \
    bash "$script" reviewer
tmux select-layout -t "$TMUX_PANE" tiled >/dev/null
tmux select-pane -t "$TMUX_PANE"
exec bash "$script" coordinator
