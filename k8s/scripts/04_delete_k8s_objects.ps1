$ErrorActionPreference = "Stop"

function Write-Log {
    param (
        [string]$Text,
        [string]$Type = "INFO"
    )
    switch ($Type) {
        "INFO"    { $color = "Gray" }
        "SUCCESS" { $color = "Green" }
        "ERROR"   { $color = "Red" }
        default   { $color = "White" }
    }
    Write-Host "[$Type] $Text" -ForegroundColor $color
}

$namespace = "pyler-mlops"
cd ../

# 1. Delete client pod
Write-Log "Deleting pod-client.yaml ..."
$output = kubectl delete -f .\client\pod-client.yaml -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted client pod" "SUCCESS"
} else {
    Write-Log "Failed to delete client pod:`n$output" "ERROR"
}

# 2. Delete client configmap
Write-Log "Deleting configmap-client.yaml ..."
$output = kubectl delete -f .\client\configmap-client.yaml -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted client configmap" "SUCCESS"
} else {
    Write-Log "Failed to delete client configmap:`n$output" "ERROR"
}

# 3. Delete training job
Write-Log "Deleting job-train.yaml ..."
$output = kubectl delete -f .\train\job-train.yaml -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted training job" "SUCCESS"
} else {
    Write-Log "Failed to delete training job:`n$output" "ERROR"
}

# 4. Delete Triton deployment
Write-Log "Deleting deploy-triton.yaml ..."
$output = kubectl delete -f .\triton\deploy-triton.yaml -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted Triton deployment" "SUCCESS"
} else {
    Write-Log "Failed to delete Triton deployment:`n$output" "ERROR"
}

# 5. Delete prepare-model job
Write-Log "Deleting job-prepare-model.yaml ..."
$output = kubectl delete -f .\triton\job-prepare-model.yaml -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted prepare-model job" "SUCCESS"
} else {
    Write-Log "Failed to delete prepare-model job:`n$output" "ERROR"
}

# 6. Delete Triton configmap
$cfgName = "triton-config"
Write-Log "Deleting configmap '$cfgName' ..."
$output = kubectl delete configmap $cfgName -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Deleted configmap '$cfgName'" "SUCCESS"
} else {
    Write-Log "Failed to delete configmap '$cfgName':`n$output" "ERROR"
}

# 7. Delete base resources (PVCs etc.)
Write-Log "Deleting base resources in .\\base ..."
Get-ChildItem -Path .\base\*.yaml | ForEach-Object {
    Write-Log "Deleting $($_.FullName) ..."
    $output = kubectl delete -f $_.FullName -n $namespace 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Deleted $($_.Name)" "SUCCESS"
    } else {
        Write-Log "Failed to delete $($_.Name):`n$output" "ERROR"
    }
}

cd .\scripts
