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

# 1. Create pvc for train job
Write-Log "Applying Kubernetes resources in .\base ..."
Get-ChildItem -Path .\base\*.yaml | ForEach-Object {
    Write-Log "Applying $($_.FullName) ..."
    $output = kubectl apply -f $_.FullName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Applied $($_.Name)" "SUCCESS"
    } else {
        Write-Log "Failed to apply $($_.Name):`n$output" "ERROR"
        exit 1
    }
}

# 2. Create train job
Write-Log "Applying job-train.yaml in .\train ..."
$output = kubectl apply -f .\train\job-train.yaml 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "Applied job-train.yaml" "SUCCESS"
} else {
    Write-Log "Failed to apply job-train.yaml:`n$output" "ERROR"
    exit 1
}

# 3. Check job logs and status
Write-Log "All train Kubernetes resources applied successfully." "SUCCESS"
Write-Log "To check job logs, run: kubectl logs -f -n pyler-mlops job/train-model-job" "INFO"

Write-Host ""
Write-Log "To inspect result model files in volume, run the following:" "INFO"
Write-Host "  kubectl apply -f .\train\pod-debug.yaml"
Write-Host "  kubectl exec -it debug-shell -n pyler-mlops -- /bin/sh"
Write-Host "  ls /models/resnet"
Write-Host "  kubectl delete -f .\train\pod-debug.yaml"

cd .\scripts