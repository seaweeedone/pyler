## 🧾 Infrastructure Overview

### 1. Cluster Environment
- **Operating System**: Windows 11 / Ubuntu(WSL)
- **Cluster Tool:**: Minikube (v1.36.0)
- **Minikube Driver**: Hyper-V(Windows) / Docker(Linux)
  - 사용 가능한 Minikube 드라이버에 대한 자세한 정보는 아래 공식문서를 참고하세요.
  - Minikube Driver 공식 문서 : https://minikube.sigs.k8s.io/docs/drivers/
- **Kubernetes Setup**: Single-node cluster (single control plane)


### 2. Version Info
- **Minikube**: v1.36.0
- **Kubernetes Server**: v1.33.1
- **Kubernetes Client**: v1.30.2
- **Container Runtime(Docker)**: v28.0.4
- **Helm**: v3.18.3


## ⚙️ Minikube Cluster Setup (Windows)
Widows PowerShell 을 이용한 환경 구성 방법입니다.

반드시 PowerShell 을 관리자 권한으로 실행하세요.

### 1. Install Minikube
최신의 Minikube 를 설치합니다.
```powershell
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
```

### 2. Add Minikube to the System PATH
시스템의 PATH 환경변수에 Minikube를 추가합니다.
```powershell
$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
}
```

### 3. Enable Hyper-V
Hyper-V 기능을 활성화합니다.
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### 4. Configure Minikube Resources
Minikube 클러스터 리소스를 설정합니다. 
```powershell
# Change resource value if you wnat 
minikube config set memory 32768
minikube config set cpus 8
minikube config set disk-size 100g
```

### 5. Start the Minikube Cluster
Minikube 드라이버를 hyperv로 설정하여 Minikube를 시작합니다.

가상 머신 기반의 클러스터를 보다 안정적으로 운영하기 위함입니다.
```powershell
minikube start --driver=hyperv
```

### 6. Verify Cluster Status
Minikube 상태 및 정보를 확인합니다. 

kubectl 명령어로 K8s 클러스터 정보를 확인할 수 있습니다.
```powershell
# Check minkube status
minikube status

# Check minikube versio
minikube version

# Check minikube IP
minikube ip

# Check pod list
kubectl get po -A

# Start minikube dashboard
minikube dashboard
```

### 7. Install Helm
Windows 용 패키지 매니저인 chocolatey를 사용하여 Helm 을 설치합니다. 
```powershell
# Install chocolatey(if not installed yet)
Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Helm : use --version option if you want specific version
choco install kubernetes-helm -y

# Check Helm version
helm version

# Check Helm list
helm list -A
```


## ⚙️ Minikube Cluster Setup (WSL: Ubuntu 22.04)
WSL 을 이용한 환경 구성 방법입니다.

WSL 환경 내에 Docker가 설치되어있음을 전제로 합니다. 


### 1. Set up user with sudo permissions
root 계정으로 실행합니다.

유저를 생성하고, minikube 설치를 위한 sudo 권한을 부여합니다. 
```powershell
adduser pyler
usermod -aG sudo pyler
```

### 2. Add user to docker group
root 계정으로 실행합니다.

유저를 docker 그룹에 추가합니다. 
```powershell
# Add user to docker group
usermod -aG docker pyler 
newgrp docker

# Check docker permission
docker info 
```


### 3. Install Minikube  
해당 단계부터는 pyler 계정으로 실행합니다. 

최신 버전의 Minikube 실행 파일을 다운로드하고 Minikube를 설치합니다. 
```powershell
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### 3. Configure Minikube Resources
Minikube 클러스터 리소스를 설정합니다. 
```powershell
# Change resource value if you wnat 
minikube config set memory 32768
minikube config set cpus 8
minikube config set disk-size 100g
```

### 4. Start the Minikube Cluster
Minikube 드라이버를 docker로 설정하여 Minikube를 시작합니다.

```powershell
minikube start --driver=docker
```

### 5. Verify Cluster Status
Minikube 상태 및 정보를 확인합니다. 

kubectl 명령어로 K8s 클러스터 정보를 확인할 수 있습니다.

```powershell
# Check minkube status
minikube status

# Check minikube versio
minikube version

# Check minikube IP
minikube ip

# Check pod list
kubectl get po -A

# Start minikube dashboard
minikube dashboard
```

### 6. Install Helm
Helm 설치 스크립트를 실행하여 최신 버전의 Helm을 설치합니다.
```powershell
# Install Helm 
 curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Check Helm version
helm version

# Check Helm list
helm list -A
```


---
Install 관련 추가 정보는 Minikube 공식 문서를 확인하세요.

https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download
