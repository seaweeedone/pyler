# Pyler: Minikube 기반 CPU 모델 학습 및 추론 워크플로우

## 1. 개요

본 프로젝트는 로컬 Kubernetes 환경(Minikube)에서 CPU를 사용하여 머신러닝 모델을 학습하고, NVIDIA Triton Inference Server를 통해 서비스하며, 클라이언트에서 추론을 요청하는 전체 MLOps 워크플로우를 시연합니다.

주요 과정은 다음과 같습니다.
- **모델 학습**: PyTorch와 ResNet18을 사용하여 MNIST 데이터셋으로 이미지 분류 모델을 학습합니다.
- **모델 저장**: 학습된 모델을 Persistent Volume에 저장하여 Triton 서버가 접근할 수 있도록 합니다.
- **모델 서빙**: Triton Inference Server를 통해 저장된 모델을 배포합니다.
- **모델 추론**: 별도의 클라이언트 애플리케이션에서 Triton 서버로 추론 요청을 보내고 결과를 확인합니다.

## 2. 프로젝트 구조

```
pyler/
├── client/              # 추론 클라이언트 관련 파일
│   ├── client.py
│   ├── Dockerfile
│   └── build_image.ps1  # Docker 이미지 빌드 스크립트
├── k8s/                 # 쿠버네티스 매니페스트 및 스크립트
│   ├── base/            # PVC 등 기본 리소스
│   ├── client/          # 클라이언트 Pod 관련 리소스
│   ├── train/           # 학습 Job 관련 리소스
│   ├── triton/          # Triton 서버 관련 리소스
│   └── scripts/         # 배포 자동화 스크립트
├── train/               # 모델 학습 관련 파일
│   ├── train.py
│   ├── Dockerfile
│   └── build_image.ps1  # Docker 이미지 빌드 스크립트
├── INFRA.md             # Minikube 환경 설정 가이드
└── README.md            # 프로젝트 설명 파일
```

- **`train/`**: 모델 학습(`train.py`) 및 Docker 이미지 생성을 위한 `Dockerfile`이 위치합니다.
- **`client/`**: Triton 서버에 추론을 요청하는 클라이언트(`client.py`) 및 Docker 이미지 생성을 위한 `Dockerfile`이 위치합니다.
- **`k8s/`**: 모든 Kubernetes 리소스가 정의되어 있습니다. `scripts` 디렉토리의 셸 스크립트를 통해 각 단계를 순차적으로 실행할 수 있습니다.
- **`INFRA.md`**: 프로젝트 실행에 필요한 Minikube, Kubectl 등 개발 환경 설정 방법을 상세히 설명합니다.

## 3. 실행 환경 준비

본 프로젝트를 실행하기 전, `INFRA.md` 파일을 참고하여 Minikube 클러스터 및 관련 도구들을 설정해야 합니다.

- **[INFRA.md](./INFRA.md)를 참고하여 Minikube 환경 설정을 완료해주세요.**

## 4. 실행 방법

아래 단계들을 순서대로 실행하여 전체 워크플로우를 진행합니다.

> **Windows 사용자 참고**: Git Bash 또는 WSL(Windows Subsystem for Linux)을 사용하여 아래의 `.sh` 스크립트를 실행하세요.

### 1단계: Namespace 생성 및 Docker 이미지 빌드

먼저, Kubernetes 클러스터에 Namespace를 생성합니다.

```shell
kubectl create ns pyler-mlops
```

다음으로, 프로젝트 루트 디렉토리에서 train 및 client 디렉토리로 이동한 뒤 빌드 스크립트를 실행하여 학습 및 클라이언트 Docker 이미지를 빌드합니다.

스크립트 내부에서 Mnikube의 Docker 데몬을 사용하도록 설정합니다.

반드시 Windows PowerShell 을 관리자 권한으로 실행하세요.

```shell
# Windows PowerShell 관리자 권한 실행
# train 이미지 빌드
cd train
./build_image.ps1
cd ../

# client 이미지 빌드 
cd client
./build_image.ps1
cd ../
```

모델 학습 epoch 를 조정하고 싶은 경우 train/train.py 코드 내의 num_epochs 변수를 수정하세요.

### 2단계: 모델 학습 Job 실행

`k8s/scripts` 디렉토리로 이동하여 학습 스크립트를 실행합니다. 

이 스크립트는 모델을 저장할 Persistent Volume Claim(PVC)을 생성하고, `train-model:pyler` 이미지를 사용하여 모델 학습 Job을 실행합니다. 

학습된 모델은 PVC에 저장됩니다.

```shell
# k8s/scripts 디렉토리로 이동
cd k8s/scripts

# 학습 Job 실행
./01_deploy_train.ps1
```

학습 로그는 다음 명령어로 확인할 수 있습니다.
```shell
kubectl logs -f -n pyler-mlops job/train-model-job
```

학습 모델 파일을 확인하고 싶은 경우 k8s/train/pod-debug.yaml 파일을 활용할 수 있습니다.

디버깅 파드 활용 방법은 01_deploy_train.ps1 스크립트 실행 로그를 확인하세요.

### 3단계: Triton Inference Server 배포

학습이 완료되면, Triton 서버를 배포하여 모델을 서비스합니다. 

이 스크립트는 Triton이 모델을 인식할 수 있도록 모델 저장소 구조를 준비하는 Job을 실행한 뒤, Triton Deployment와 Service를 생성합니다.

```shell
# Triton 서버 배포 (k8s/scripts 디렉토리에서 실행)
./02_deploy_triton_server.ps1
```

Triton 서버가 정상적으로 실행되었는지 확인합니다.
```shell
kubectl get po -n pyler-mlops -l app=triton
```

### 4단계: 추론 클라이언트 실행

마지막으로, 클라이언트 Pod을 실행하여 Triton 서버로 추론 요청을 보냅니다. 

클라이언트는 서버에 MNIST 샘플 이미지를 보내고, 추론 결과와 지연 시간을 출력합니다.

```shell
# 클라이언트 실행 (k8s/scripts 디렉토리에서 실행)
./03_deploy_client.ps1
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

## 5. 리소스 정리

실행한 모든 Kubernetes 리소스를 삭제하려면 다음 명령어를 사용하세요.

```shell
./04_delete_k8s_objects.ps1
kubectl delete ns pyler-mlops
```
