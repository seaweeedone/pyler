#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/settings.sh"

write_log "Checking train job status..."
if ! kubectl get job/"$trainJobName" -n "$namespace"; then
    write_log "Could not retrieve job status." "ERROR"
    exit 1
fi

write_log "Tailing logs from train job. Press Ctrl+C to exit."
if ! kubectl logs -f job/"$trainJobName" -n "$namespace"; then
    write_log "Failed to tail logs. The job may not have started yet." "ERROR"
    exit 1
fi

write_log "Log tailing finished. The job might be complete." "SUCCESS"
