Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$settingsPath = "$PSScriptRoot\settings.ps1"
if (-Not (Test-Path $settingsPath)) {
    Write-Error "settings.ps1 not found at: $settingsPath"
    exit 1
}

. $settingsPath

Write-Log "Checking train job status..."
kubectl get job/$trainJobName -n $namespace

Write-Log "Tailing logs from train job..."
kubectl logs -f job/$trainJobName -n $namespace


Write-Host ""
Write-Log "Training job completed successfully." "SUCCESS"