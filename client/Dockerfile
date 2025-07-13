FROM python:3.10-slim

WORKDIR /app

RUN pip install tritonclient[grpc] numpy torch torchvision

COPY client.py .

CMD ["python", "client.py"]