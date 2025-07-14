#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/settings.sh"

cd "$SCRIPT_DIR/../../"

write_log "Installing or upgrading client chart..."
if ! helm upgrade --install "$releaseClient" ./client -n "$namespace"; then
    write_log "Client chart installation failed." "ERROR"
    exit 1
fi
write_log "Client chart installed successfully." "SUCCESS"

write_log "To check pod logs, run: kubectl logs -f -n "$namespace" "$clientPodName"" "INFO"

cd "$SCRIPT_DIR"
