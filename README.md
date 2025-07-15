# Pyler: Minikube 기반 CPU 모델 학습 및 추론 워크플로우

# 1. Overview

본 프로젝트는 로컬 Kubernetes 환경(Minikube)에서 CPU를 사용하여 머신러닝 모델을 학습하고, NVIDIA Triton Inference Server를 통해 서비스하며, 클라이언트에서 추론을 요청하는 전체 MLOps 워크플로우를 시연합니다.

주요 과정은 다음과 같습니다.
- **모델 학습**: PyTorch와 ResNet18을 사용하여 MNIST 데이터셋으로 이미지 분류 모델을 학습합니다.
- **모델 저장**: 학습된 모델을 Persistent Volume에 저장하여 Triton 서버가 접근할 수 있도록 합니다.
- **모델 서빙**: Triton Inference Server를 통해 저장된 모델을 배포합니다.
- **모델 추론**: 별도의 클라이언트 애플리케이션에서 Triton 서버로 추론 요청을 보내고 결과를 확인합니다.

# 2. Project Structure

```
pyler/
├── client/              # 추론 클라이언트 관련 파일
│   ├── client.py
│   ├── Dockerfile
│   └── build_image.ps1  # Docker 이미지 빌드 스크립트
│   └── build_image.sh   # Docker 이미지 빌드 스크립트
├── k8s/                 # 쿠버네티스 매니페스트 및 스크립트
│   ├── client/          # 클라이언트 Pod 관련 리소스
│   ├── train/           # 학습 Job 관련 리소스
│   ├── triton/          # Triton 서버 관련 리소스
│   └── scripts/         # 배포 자동화 스크립트
│       ├── linux        # Linux 전용 배포 스크립트(.sh)
│       └── windows      # Windows 전용 배포 스크립트(.ps1)
├── train/               # 모델 학습 관련 파일
│   ├── train.py
│   ├── Dockerfile
│   └── build_image.ps1  # Docker 이미지 빌드 스크립트
│   └── build_image.sh   # Docker 이미지 빌드 스크립트 
├── INFRA.md             # Minikube 환경 설정 가이드
└── README.md            # 프로젝트 설명 파일
```

- **`train/`**: 모델 학습(`train.py`) 및 Docker 이미지 생성을 위한 `Dockerfile`이 위치합니다.
- **`client/`**: Triton 서버에 추론을 요청하는 클라이언트(`client.py`) 및 Docker 이미지 생성을 위한 `Dockerfile`이 위치합니다.
- **`k8s/`**: 모든 Kubernetes 리소스가 정의되어 있습니다. `scripts` 디렉토리의 스크립트를 통해 Helm 차트를 배포하고 관리할 수 있습니다.
- **`INFRA.md`**: 프로젝트 실행에 필요한 Minikube, Kubectl 등 개발 환경 설정 방법을 상세히 설명합니다.

# 3. Environment Setup

본 프로젝트를 실행하기 전, `INFRA.md` 파일을 참고하여 Minikube 클러스터 및 관련 도구들을 설정해야 합니다.

- **[INFRA.md](./INFRA.md)를 참고하여 Minikube 환경 설정을 완료해주세요.**

# 4. How to Run

> 모델 학습 epoch 의 기본 값은 5로 설정되어 있습니다. 
>
> 이를 조정하고 싶은 경우 train/train.py 코드 내의 NUM_EPOCHS 변수를 수정하세요.
> 
> 서비스 배포 및 도커 이미지 빌드 스크립트는 Windows / Linux 로 나누어져있습니다.
> 
> Windows PowerShell 을 사용하는 환경에서는 .ps1 파일을, WLS 혹은 Linux 환경의 경우 .sh 파일을 실행하세요.
> 
> Helm Chart 내의 값을 변경하신 경우 settings.ps1 / settings.sh 파일에도 이를 반영해주시길 바랍니다.



아래 단계들을 순서대로 실행하여 전체 워크플로우를 진행합니다.

## Step 0: Create Namespace and Build Docker Images

프로젝트 루트 디렉토리에서 train 및 client 디렉토리로 이동한 뒤 빌드 스크립트를 실행하여 학습 및 클라이언트 Docker 이미지를 빌드합니다.

스크립트 내부에서 Mnikube의 Docker 데몬을 사용하도록 설정합니다.
> **사용자 참고**: Windows PowerShell 사용 시 반드시 관리자 권한으로 실행하세요.

```shell
# Build train image
cd train
./build_image.ps1 # If linux user, run ./build_image.sh
cd ../

# Build client image
cd client
./build_image.ps1 # If linux user, run ./build_image.sh
cd ../
```


## Step 1: Deploy Training Job via Helm Chart

`k8s/scripts` 하위의 OS 디렉토리로 이동합니다.(`k8s/scripts/windows` or `k8s/scripts/linux`)  
디렉토리로 이동 후 학습 Job Helm Chart 배포 스크립트를 실행합니다. 

이 스크립트는 Kubernetes 클러스터에 Namespace를 생성하고 `k8s/train` Helm Chart를 배포하여 모델을 저장할 Persistent Volume Claim(PVC)을 생성합니다.

`train-model:pyler` 이미지를 사용하여 모델 학습 Job을 실행하며 학습된 모델은 PVC에 저장됩니다.

```shell
# For Windows user
cd k8s/scripts/windows 
./01_deploy_train_job.ps1

# For linux User 
cd k8s/scripts/linux 
./01_deploy_train_job.sh
```


## Step 2: Check Training Job Status

학습 job 의 상태 및 로그를 확인합니다. 학습이 완료될 때 까지 대기하세요.

```shell
# For Windows user
./02_check_train_status.ps1

# For linux User 
./02_check_train_status.sh
```

학습 완료 시 아래와 같은 완료 로그를 확인하실 수 있습니다.

**예상 출력 결과:**
```commandline
2025-07-13 12:32:28,931 [INFO] Training completed. Exporting model...
2025-07-13 12:32:29,186 [INFO] Model saved to /models/resnet/model.pt
```


## Step 3: Deploy Triton Inference Server via Helm Chart

학습이 완료되면, Triton 서버를 배포 스크립트를 실행하여 모델을 서비스합니다. 

이 스크립트는 `k8s/triton` Helm Chart를 배포하며 Triton이 모델을 인식할 수 있도록 모델 저장소 구조를 설정하는 Job을 실행한 뒤, Triton Deployment와 Service를 생성합니다.

```shell
# For Windows user
./03_deploy_triton_server.ps1

# For linux User 
./03_deploy_triton_server.sh
```

Triton 서버가 정상적으로 실행되었는지 확인하고 조회한 파드 로그를 확인하여 Trion 서버에 모델이 로드되었는지 확인합니다.
```shell
kubectl get po -n pyler-mlops -l app=triton
kubectl logs -f -n pyler-mlops $podName  
```

파드 로그 내에 아래 예시와 같이 모델이 로드되었다는 로그가 존재하여야 합니다.

**예상 출력 결과:**
```
I0715 01:00:37.866501 1 model_lifecycle.cc:835] successfully loaded 'resnet'
```


## Step 4: Deploy and Run Inference Client via Helm Chart

마지막으로, 클라이언트 Pod Helm Chart를 배포하여 Triton 서버로 추론 요청을 보냅니다. 

이 스크립트는 `k8s/client` Helm Chart를 배포하며, 클라이언트는 서버에 MNIST 샘플 이미지를 보내고, 추론 결과와 지연 시간을 출력합니다.

```shell
# For Windows user
./04_deploy_client.ps1

# For linux User 
./04_deploy_client.sh
```

클라이언트의 로그를 확인하여 추론 결과를 볼 수 있습니다.
```shell
kubectl logs -f -n pyler-mlops triton-client
```

**예상 출력 결과:**
```
2025-07-13 14:30:00,123 [INFO] Connected to Triton server.
2025-07-13 14:30:00,456 [INFO] Inference latency: 333.00 ms
2025-07-13 14:30:00,456 [INFO] Sample outputs:
[1] → 5 (raw: [...])
[2] → 2 (raw: [...])
...
2025-07-13 14:30:00,457 [INFO] Client finished successfully.
```

# Step 5: Clean Up Resources

실행한 모든 Kubernetes 리소스를 삭제하려면 다음 명령어를 사용하세요.

```shell
# For Windows user
./05_clean_up.ps1

# For linux User 
./05_clean_up.sh
```
