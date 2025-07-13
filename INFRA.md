## 🧾 Infrastructure Overview

### 1. Cluster Environment
- **Operating System**: Windows 11
- **Cluster Tool:**: Minikube (v1.36.0)
- **Minikube Driver**: Hyper-V
  - Hyper-V was chosen to ensure stable VM-based cluster operation.
  - For more information on available drivers, refer to the https://minikube.sigs.k8s.io/docs/drivers/
- **Kubernetes Setup**: Single-node cluster (single control plane)


### 2. Version Info
- **Minikube**: v1.36.0
- **Kubernetes Server**: v1.33.1
- **Kubernetes Client**: v1.30.2
- **Container Runtime(Docker)**: v28.0.4


## ⚙️ Minikube Cluster Setup
Make sure to run PowerShell as Administrator.

### 1. Download and run Minikube installer 
```powershell
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
```

### 2. Add Minikube to the System PATH
```powershell
$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
}
```

### 3. Enable Hyper-V
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### 4. Configure Minikube Resources
```powershell
# Change resource value if you wnat 
minikube config set memory 32768
minikube config set cpus 8
minikube config set disk-size 100g
```

### 5. Start the Minikube Cluster
```powershell
minikube start --driver=hyperv
```

### 6. Verify Cluster Status
```powershell
#Check minkube status
minikube status

#Check minikube versio
minikube version

#Check minikube IP
minikube ip

#Check pod list
kubectl get po -A

#Start minikube dashboard
minikube dashboard
```