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

cd ../

# 1. Create configmap delete if already exists
$cfgName = "triton-config"
Write-Log "Checking if configmap '$cfgName' exists..."

$exists = $false
try {
    kubectl get configmap $cfgName -n pyler-mlops > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $exists = $true
    }
} catch {
    # 무시: 존재하지 않으면 예외 발생 가능
    $exists = $false
}

if ($exists) {
    Write-Log "ConfigMap '$cfgName' already exists. Deleting it..."
    $delOutput = kubectl delete configmap $cfgName -n pyler-mlops 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Deleted existing configmap '$cfgName'" "SUCCESS"
    } else {
        Write-Log "Failed to delete configmap '$cfgName':`n$delOutput" "ERROR"
        exit 1
    }
} else {
    Write-Log "ConfigMap '$cfgName' does not exist. Creating new one..." "INFO"
}

Write-Log "Creating configmap '$cfgName'..."
$output = kubectl create configmap $cfgName `
    --from-file=config.pbtxt=.\triton\config\config.pbtxt `
    -n pyler-mlops 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Log "Created configmap '$cfgName'" "SUCCESS"
} else {
    Write-Log "Failed to create configmap '$cfgName':`n$output" "ERROR"
    exit 1
}

# 2. Create job for model dir in pvc
Write-Log "Applying job-prepare-model.yaml ..."
$output = kubectl apply -f .\triton\job-prepare-model.yaml 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Applied job-prepare-model.yaml" "SUCCESS"
} else {
    Write-Log "Failed to apply job-prepare-model.yaml:`n$output" "ERROR"
    exit 1
}

# 3. Deploy Triton Server
Write-Log "Applying deploy-triton.yaml ..."
$output = kubectl apply -f .\triton\deploy-triton.yaml 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Applied deploy-triton.yaml" "SUCCESS"
} else {
    Write-Log "Failed to apply deploy-triton.yaml:`n$output" "ERROR"
    exit 1
}


# 4. Check job logs
Write-Log "All Triton Kubernetes resources applied successfully." "SUCCESS"
Write-Log "To check pod status, run: kubectl get po -n pyler-mlops -l app=triton" "INFO"

cd .\scripts
