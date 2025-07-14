$namespace = "pyler-mlops"
$releaseTrain = "train"
$releaseTriton = "triton"
$releaseClient = "client"
$trainJobName = "job-train-model"
$clientPodName = "triton-client"
$pvcName = "pyler-model-pvc"

# logging function
function Write-Log {
    param (
        [string]$Text,
        [string]$Type = "INFO"
    )

    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        default   { "Gray" }
    }

    Write-Host "[$Type] $Text" -ForegroundColor $color
}