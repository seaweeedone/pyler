Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$settingsPath = "$PSScriptRoot\settings.ps1"
if (-Not (Test-Path $settingsPath)) {
    Write-Error "settings.ps1 not found at: $settingsPath"
    exit 1
}

. $settingsPath

cd ../

Write-Log "Waiting for train job to complete before deploying Triton..."
kubectl wait --for=condition=complete job/$trainJobName -n $namespace --timeout=3600s
if ($LASTEXITCODE -ne 0) {
    Write-Log "Train job did not complete successfully within timeout." "ERROR"
    exit 1
}

Write-Log "Installing Triton chart..."
$output = helm upgrade --install $releaseTriton ./triton -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Triton chart installed successfully." "SUCCESS"
} else {
    Write-Log "Triton chart installation failed:`n$output" "ERROR"
    Set-Location $PSScriptRoot
    exit 1
}

Write-Log "Waiting for Triton pod to be Ready..."
kubectl wait --for=condition=ready pod -l app=triton -n $namespace --timeout=120s
if ($LASTEXITCODE -ne 0) {
    Write-Log "Triton pod did not become ready." "ERROR"
    Set-Location $PSScriptRoot
    exit 1
}
Write-Log "Triton is Ready." "SUCCESS"

Write-Log "All Triton Kubernetes resources applied successfully." "SUCCESS"
Write-Log "To check pod status, run: kubectl get po -n $namespace -l app=$releaseTriton" "INFO"

Set-Location $PSScriptRoot
