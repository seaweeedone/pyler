import os

import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torchvision.models import resnet18


def main():
    # Use CPU for training
    device = torch.device("cpu")
    print(f"Using device: {device}")

    export_dir = os.environ.get("EXPORT_DIR", "/mnt/models/resnet")
    os.makedirs(export_dir, exist_ok=True)

    # Preprocessing: resize MNIST images to match ResNet input size
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor()
    ])

    # Load MNIST training dataset
    trainset = torchvision.datasets.MNIST(
        root="./data", train=True, download=True, transform=transform
    )
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=64, shuffle=True)

    # Initialize ResNet-18 model
    model = resnet18(pretrained=False)
    model.conv1 = nn.Conv2d(1, 64, kernel_size=7, stride=2, padding=3, bias=False)
    model.fc = nn.Linear(512, 10)
    model.to(device)

    # Loss and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    # Training loop
    for epoch in range(10):
        for batch_idx, (inputs, labels) in enumerate(trainloader):
            inputs, labels = inputs.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            print(f"[Epoch {epoch + 1}, Batch {batch_idx + 1}] Loss: {loss.item() / 100:.4f}")

    # Switch to evaluation mode and export to TorchScript
    model.eval()
    example_input = torch.randn(1, 1, 224, 224)
    traced = torch.jit.trace(model, example_input)
    traced.save(f"{export_dir}/model.pt")
    print(f"Model saved to {export_dir}/model.pt")


if __name__ == "__main__":
    main()
