Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$settingsPath = "$PSScriptRoot\settings.ps1"
if (-Not (Test-Path $settingsPath)) {
    Write-Error "settings.ps1 not found at: $settingsPath"
    exit 1
}

. $settingsPath

cd ../
Write-Log "Installing client chart..."
$output = helm upgrade --install $releaseClient ./client -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Client chart installed successfully." "SUCCESS"
} else {
    Write-Log "Client chart installation failed:`n$output" "ERROR"
    Set-Location $PSScriptRoot
    exit 1
}

# Write-Log "Tailing logs from Triton client..."
# kubectl logs -f $clientPodName -n $namespace

Write-Log "All client Kubernetes resources applied successfully." "SUCCESS"
Write-Log "To check pod logs, run: kubectl logs -f -n $namespace $clientPodName" "INFO"

Set-Location $PSScriptRoot
