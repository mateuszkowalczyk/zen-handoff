#!/usr/bin/env bash
set -euo pipefail

# Usage: bash .agents/scripts/wait-for-issues.sh SNAPSHOT_FILE
# Keep SNAPSHOT_FILE outside the repository and reuse it within this session.
snapshot_file=${1:?Provide a session-local snapshot file}
interval=${ZEN_HANDOFF_POLL_SECONDS:-60}
if [[ $# != 1 || ! $interval =~ ^[1-9][0-9]*$ ]]; then
    echo 'Expected SNAPSHOT_FILE and a positive integer poll interval.' >&2
    exit 1
fi
statuses='["status:ready","status:in-progress","status:review","status:blocked"]'

repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
previous=''
if [[ -s $snapshot_file ]]; then
    previous=$(cat -- "$snapshot_file")
fi

while true; do
    # Paginate rather than silently truncating the queue. API failures exit;
    # they must never be treated as an empty queue or retried in a hot loop.
    issues=$(gh api --paginate --slurp \
        "repos/$repo/issues?state=open&per_page=100")
    queue=$(jq -cS --argjson statuses "$statuses" '
        [ .[][] | select(.pull_request == null)
          | .labels = ([.labels[].name] | sort)
          | select((.labels | index("status:triage")) == null)
          | select(([.labels[] | select(startswith("status:"))] | length) == 1)
          | select(any(.labels[]; . as $label | $statuses | index($label)))
          | {number, title, url: .html_url, updatedAt: .updated_at,
             comments, labels} ] | sort_by(.number)
    ' <<< "$issues")

    dependencies='[]'
    # A blocker can change without updating the dependent issue itself.
    for number in $(jq -r '.[] | select(.labels | index("status:blocked")) | .number' <<< "$queue"); do
        blockers=$(gh api --paginate --slurp \
            "repos/$repo/issues/$number/dependencies/blocked_by?per_page=100")
        blockers=$(jq -cS '[.[][] | {number, url: .html_url, state,
            state_reason, labels: ([.labels[].name] | sort)}] | sort_by(.url)' <<< "$blockers")
        dependencies=$(jq -cS --argjson number "$number" --argjson blockers "$blockers" \
            '. + [{issue: $number, blockedBy: $blockers}]' <<< "$dependencies")
    done

    current=$(jq -ncS --arg repo "$repo" \
        --argjson queue "$queue" --argjson dependencies "$dependencies" \
        '{repo: $repo, queue: $queue, dependencies: $dependencies}')
    if [[ $queue != '[]' && $current != "$previous" ]]; then
        printf '%s\n' "$current" > "$snapshot_file"
        printf '%s\n' "$current"
        exit 0
    fi
    previous=$current
    sleep "$interval"
done
