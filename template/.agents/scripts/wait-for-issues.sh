#!/usr/bin/env bash
set -euo pipefail

# Usage: bash .agents/scripts/wait-for-issues.sh ROLE SNAPSHOT_FILE
# Keep SNAPSHOT_FILE outside the repository and reuse it within this session.
role=${1:?Provide a role}
snapshot_file=${2:?Provide a session-local snapshot file}
interval=${ZEN_HANDOFF_POLL_SECONDS:-60}
if [[ $# != 2 || ! $interval =~ ^[1-9][0-9]*$ ]]; then
    echo 'Expected ROLE SNAPSHOT_FILE and a positive integer poll interval.' >&2
    exit 1
fi
case $role in
    coordinator) statuses='["status:ready","status:blocked"]' ;;
    builder-simple|builder-complex) statuses='["status:ready"]' ;;
    reviewer) statuses='["status:review"]' ;;
    *) echo "Unknown role: $role" >&2; exit 1 ;;
esac

repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
previous=''
if [[ -s $snapshot_file ]]; then
    previous=$(cat -- "$snapshot_file")
fi

while true; do
    # Paginate rather than silently truncating the queue. API failures exit;
    # they must never be treated as an empty queue or retried in a hot loop.
    issues=$(gh api --paginate --slurp \
        "repos/$repo/issues?state=open&labels=role%3A$role&per_page=100")
    queue=$(jq -cS --arg role "role:$role" --argjson statuses "$statuses" '
        [ .[][] | select(.pull_request == null)
          | .labels = ([.labels[].name] | sort)
          | select((.labels | index("status:triage")) == null)
          | select(([.labels[] | select(startswith("role:"))]) == [$role])
          | select(([.labels[] | select(startswith("status:"))] | length) == 1)
          | select(any(.labels[]; . as $label | $statuses | index($label)))
          | {number, title, url: .html_url, updatedAt: .updated_at,
             comments, labels} ] | sort_by(.number)
    ' <<< "$issues")

    dependencies='[]'
    if [[ $role == coordinator ]]; then
        # A blocker can change without updating the dependent issue itself.
        for number in $(jq -r '.[] | select(.labels | index("status:blocked")) | .number' <<< "$queue"); do
            blockers=$(gh api --paginate --slurp \
                "repos/$repo/issues/$number/dependencies/blocked_by?per_page=100")
            blockers=$(jq -cS '[.[][] | {number, url: .html_url, state,
                state_reason, labels: ([.labels[].name] | sort)}] | sort_by(.url)' <<< "$blockers")
            dependencies=$(jq -cS --argjson number "$number" --argjson blockers "$blockers" \
                '. + [{issue: $number, blockedBy: $blockers}]' <<< "$dependencies")
        done
    fi

    current=$(jq -ncS --arg repo "$repo" --arg role "$role" \
        --argjson queue "$queue" --argjson dependencies "$dependencies" \
        '{repo: $repo, role: $role, queue: $queue, dependencies: $dependencies}')
    if [[ $queue != '[]' && $current != "$previous" ]]; then
        printf '%s\n' "$current" > "$snapshot_file"
        printf '%s\n' "$current"
        exit 0
    fi
    previous=$current
    sleep "$interval"
done
