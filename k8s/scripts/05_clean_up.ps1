Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$settingsPath = "$PSScriptRoot\settings.ps1"
if (-Not (Test-Path $settingsPath)) {
    Write-Error "settings.ps1 not found at: $settingsPath"
    exit 1
}

. $settingsPath

# Helm release list
$releases = @($releaseClient, $releaseTriton, $releaseTrain)

# 1. Delete helm release
foreach ($release in $releases) {
    Write-Log "Uninstalling Helm release: $release ..."
    $output = helm uninstall $release -n $namespace 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Successfully uninstalled $release" "SUCCESS"
    } else {
        Write-Log "Failed to uninstall $release (maybe already deleted):`n$output" "ERROR"
    }
}

# 2. Delete PVC
Write-Log "Deleting PVC: $pvcName ..."
$output = kubectl delete pvc $pvcName -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Successfully deleted PVC: $pvcName" "SUCCESS"
} else {
    Write-Log "Failed to delete PVC (maybe already deleted):`n$output" "ERROR"
}


# 3. Delete Namespace
Write-Log "Deleting namespace: $namespace ..."
$output = kubectl delete namespace $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Successfully deleted namespace: $namespace" "SUCCESS"
} else {
    Write-Log "Failed to delete namespace (maybe already deleted):`n$output" "ERROR"
}


Write-Log "All cleanup tasks completed." "SUCCESS"