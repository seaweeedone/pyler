#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/settings.sh"

cd "$SCRIPT_DIR/../../"

write_log "Waiting for train job to complete before deploying Triton..."
#if ! kubectl wait --for=condition=complete job/"$trainJobName" -n "$namespace" --timeout=3600s; then
#    write_log "Train job did not complete within the timeout period." "ERROR"
#    exit 1
#fi
#write_log "Train job completed." "SUCCESS"

write_log "Installing or upgrading Triton chart..."
if ! helm upgrade --install "$releaseTriton" ./triton -n "$namespace"; then
    write_log "Triton chart installation failed." "ERROR"
    exit 1
fi
write_log "Triton chart installed successfully." "SUCCESS"

write_log "Waiting for Triton pod to be ready..."
if ! kubectl wait --for=condition=ready pod -l app=triton -n "$namespace" --timeout=600s; then
    write_log "Triton pod did not become ready within the timeout period." "ERROR"
    exit 1
fi
write_log "Triton is ready." "SUCCESS"

write_log "To check pod status, run: kubectl get po -n "$namespace" -l app=$releaseTriton" "INFO"

cd "$SCRIPT_DIR"
