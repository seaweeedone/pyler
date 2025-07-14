#!/bin/bash

# Set image name
ImageName="triton-client:pyler"

eval $(minikube -p minikube docker-env)

# Build image
echo "[INFO] Starting Docker image build: $ImageName"
docker build -t $ImageName .

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Docker image build completed: $ImageName"
else
    echo "[ERROR] Docker image build failed"
    exit 1
fi

