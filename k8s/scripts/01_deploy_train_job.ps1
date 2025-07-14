Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$settingsPath = "$PSScriptRoot\settings.ps1"
if (-Not (Test-Path $settingsPath)) {
    Write-Error "settings.ps1 not found at: $settingsPath"
    exit 1
}

. $settingsPath

cd ../

Write-Log "Create namespace for pyler."
kubectl create ns $namespace

Write-Log "Installing train chart (PVC + train job)..."
$output = helm upgrade --install $releaseTrain ./train -n $namespace 2>&1
Write-Host $output

if ($LASTEXITCODE -eq 0) {
    Write-Log "Train chart installed successfully." "SUCCESS"
    Write-Log "Train job may take up to +30 minutes. You can check progress using train-status.ps1"
} else {
    Write-Log "Train chart installation failed:`n$output" "ERROR"
    Set-Location $PSScriptRoot
    exit 1
}

Write-Log "To check job logs, run: kubectl logs -f -n $namespace job/$trainJobName" "INFO"
Set-Location $PSScriptRoot
