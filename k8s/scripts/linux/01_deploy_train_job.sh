#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo $SCRIPT_DIR

# Source settings
source "$SCRIPT_DIR/settings.sh"

# Change to the parent directory
cd "$SCRIPT_DIR/../../"

write_log "Creating namespace '$namespace' if it doesn't exist."
if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
    kubectl create namespace "$namespace"
    write_log "Namespace '$namespace' created." "SUCCESS"
else
    write_log "Namespace '$namespace' already exists." "INFO"
fi

write_log "Installing or upgrading train chart..."
if ! helm upgrade --install "$releaseTrain" ./train -n "$namespace"; then
    write_log "Train chart installation failed." "ERROR"
    exit 1
fi

write_log "Train chart installed successfully." "SUCCESS"
write_log "The train job may take over 30 minutes. Check progress with '02_check_train_status.sh'"
write_log "To view job logs, run: kubectl logs -f -n "$namespace" job/"$trainJobName"" "INFO"

cd "$SCRIPT_DIR"
