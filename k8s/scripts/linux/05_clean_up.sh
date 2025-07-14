#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/settings.sh"

releases=("$releaseClient" "$releaseTriton" "$releaseTrain")

for release in "${releases[@]}"; do
    write_log "Uninstalling Helm release: $release ..."
    if helm uninstall "$release" -n "$namespace" >/dev/null 2>&1; then
        write_log "Successfully uninstalled $release." "SUCCESS"
    else
        write_log "Helm release '$release' not found or failed to uninstall." "INFO"
    fi
done

write_log "Deleting PVC: $pvcName ..."
if kubectl delete pvc "$pvcName" -n "$namespace" >/dev/null 2>&1; then
    write_log "Successfully deleted PVC '$pvcName'." "SUCCESS"
else
    write_log "PVC '$pvcName' not found or failed to delete." "INFO"
fi

write_log "Deleting namespace: $namespace ..."
if kubectl delete namespace "$namespace" >/dev/null 2>&1; then
    write_log "Successfully deleted namespace '$namespace'." "SUCCESS"
else
    write_log "Namespace '$namespace' not found or failed to delete." "INFO"
fi

write_log "Cleanup complete." "SUCCESS"
