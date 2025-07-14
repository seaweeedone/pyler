import datetime
import logging
import os
import sys
import time

import torch
import torchvision.transforms as transforms
import tritonclient.grpc as grpcclient
from torchvision.datasets import MNIST
from tritonclient.utils import InferenceServerException

#  Build Triton server URL from environment variables
SERVICE_NAME = os.getenv("TRITON_SERVICE_NAME", "triton-service")
NAMESPACE = os.getenv("TRITON_SERVICE_NS", "default")
CLUSTER = os.getenv("CLUSTER_NAME", "cluster.local")
PORT = os.getenv("TRITON_SERVICE_PORT", "8001")

TRITON_SERVER_URL = f"{SERVICE_NAME}.{NAMESPACE}.svc.{CLUSTER}:{PORT}"
MODEL_NAME = "resnet"
DATA_BATCH_SIZE = 10


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


# Create gRPC client & # Check server status
def connect_with_retry(url, timeout_sec=300, interval_sec=3):
    start_time = time.time()
    while True:
        try:
            client = grpcclient.InferenceServerClient(url=url, verbose=False)
            if client.is_server_live():
                logger.info("Connected to Triton server.")
                return client
            else:
                raise Exception("Triton server not live yet.")
        except Exception as e:
            elapsed = time.time() - start_time
            if elapsed >= timeout_sec:
                logger.error(f"Connection timed out after {timeout_sec} seconds.")
                raise e
            logger.info(f"Triton not ready, retrying in {interval_sec} sec...")
            time.sleep(interval_sec)


# Load sample MNIST images as inference input
def generate_mnist_batch(batch_size=DATA_BATCH_SIZE):
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
    ])
    dataset = MNIST(root="./data", train=False, download=True, transform=transform)
    loader = torch.utils.data.DataLoader(dataset, batch_size=batch_size, shuffle=True)
    images, _ = next(iter(loader))
    return images.numpy()


# Run inference using Triton gRPC client
def main():
    try:

        client = connect_with_retry(TRITON_SERVER_URL, timeout_sec=300)

        # Check model metadata
        metadata = client.get_model_metadata(model_name=MODEL_NAME)
        input_meta = metadata.inputs[0]
        output_meta = metadata.outputs[0]

        input_name = input_meta.name
        input_dtype = input_meta.datatype
        output_name = output_meta.name

        # Generate input batch
        input_data = generate_mnist_batch(DATA_BATCH_SIZE)

        # Define input for Triton
        inputs = [grpcclient.InferInput(input_name, input_data.shape, input_dtype)]
        inputs[0].set_data_from_numpy(input_data)

        # Define expected output
        outputs = [grpcclient.InferRequestedOutput(output_name)]

        # Measure inference time
        start_time = time.time()
        response = client.infer(model_name=MODEL_NAME, inputs=inputs, outputs=outputs)
        end_time = time.time()

        latency_ms = (end_time - start_time) * 1000
        logger.info(f"Inference latency: {latency_ms:.2f} ms")

        # Parse and print predictions
        predictions = response.as_numpy(output_name)
        logger.info("Sample outputs:")
        for i in range(min(10, len(predictions))):
            print(f"[{i + 1}] → {predictions[i].argmax()} (raw: {predictions[i]})", flush=True)
            sys.stdout.flush()

        logger.info("Client finished successfully.")

    except InferenceServerException as e:
        logger.error(f"Triton error: {str(e)}")
    except Exception as e:
        logger.error(f"Client error: {str(e)}")


if __name__ == "__main__":
    main()
