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

# 1. Create configmap for gRPC connection
Write-Log "Applying configmap-client.yaml ..."
$output = kubectl apply -f .\client\configmap-client.yaml 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Applied configmap-client.yaml" "SUCCESS"
} else {
    Write-Log "Failed to apply configmap-client.yaml:`n$output" "ERROR"
    exit 1
}

# 2. Create client server pod
Write-Log "Applying pod-client.yaml ..."
$output = kubectl apply -f .\client\pod-client.yaml 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Applied pod-client.yaml" "SUCCESS"
} else {
    Write-Log "Failed to apply pod-client.yaml:`n$output" "ERROR"
    exit 1
}

# 3. Check pod status
Write-Log "All client Kubernetes resources applied successfully." "SUCCESS"
Write-Log "To check pod logs, run: kubectl logs triton-client -n pyler-mlops" "INFO"

cd .\scripts