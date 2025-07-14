import datetime
import logging
import os

import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
from torchvision.models import resnet18

# Hyperparameters
NUM_EPOCHS = 5
BATCH_SIZE = 64
LEARNING_RATE = 0.001


# Set log format (KST)
class KSTFormatter(logging.Formatter):
    converter = lambda *args: datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).timetuple()

    def formatTime(self, record, datefmt=None):
        return super().formatTime(record, datefmt)


formatter = KSTFormatter(fmt="%(asctime)s [%(levelname)s] %(message)s")
handler = logging.StreamHandler()
handler.setFormatter(formatter)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(handler)
logger.propagate = False


def main():
    # Use CPU for training
    device = torch.device("cpu")
    logger.info(f"Using device: {device}")

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
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=BATCH_SIZE, shuffle=True)

    # Initialize ResNet-18 model
    model = resnet18(weights=None)
    model.conv1 = nn.Conv2d(1, 64, kernel_size=7, stride=2, padding=3, bias=False)
    model.fc = nn.Linear(512, 10)
    model.to(device)

    # Loss and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=LEARNING_RATE)

    # Training loop
    logger.info("Starting training...")
    for epoch in range(NUM_EPOCHS):
        logger.info(f"Epoch {epoch + 1} started.")
        running_loss = 0.0
        log_interval = max(1, len(trainloader) // 5)

        for batch_idx, (inputs, labels) in enumerate(trainloader):
            inputs, labels = inputs.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()

            if (batch_idx + 1) % log_interval == 0:
                avg_loss = running_loss / log_interval
                logger.info(f"[Epoch {epoch + 1}, Batch {batch_idx + 1}] Avg Loss: {avg_loss:.4f}")
                running_loss = 0.0
        logger.info(f"Epoch {epoch + 1} finished.")

    logger.info("Training completed. Exporting model...")

    # Switch to evaluation mode and export to TorchScript
    model.eval()
    example_input = torch.randn(1, 1, 224, 224).to(device)
    traced = torch.jit.trace(model, example_input)
    traced.save(f"{export_dir}/model.pt")
    logger.info(f"Model saved to {export_dir}/model.pt")


if __name__ == "__main__":
    main()
