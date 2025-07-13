# Set image name
$ImageName = "triton-client:pyler"

# Set Minikube Docker daemon
& minikube -p minikube docker-env | Invoke-Expression

# Build image
Write-Host "[INFO] Starting Docker image build: $ImageName"
docker build -t $ImageName .

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Docker image build completed: $ImageName"
} else {
    Write-Host "[ERROR] Docker image build failed"
    exit 1
}