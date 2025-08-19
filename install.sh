#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090

set -euo pipefail

SWAYDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SWAYDE_DIR/lib/common.sh"
. "$SWAYDE_DIR/lib/dnf.sh"
. "$SWAYDE_DIR/lib/flatpak.sh"
. "$SWAYDE_DIR/lib/webapp.sh"

TASKS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    ## --- Skip comments / blank lines
    [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue
    TASKS+=("$(echo "$line" | xargs)")
done <"$SWAYDE_DIR/install.tasks"

for task in "${TASKS[@]}"; do
    task_file=$"$SWAYDE_DIR/tasks/$task.sh"
    [[ -f "$task_file" ]] || die "Unknown task: $task"
    . "$task_file"
    log ">>> TASK: $task"
    task::run
done
