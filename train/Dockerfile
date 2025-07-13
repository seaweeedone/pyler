FROM python:3.10-slim

WORKDIR /app

RUN pip install torch torchvision

COPY train.py .

ENV EXPORT_DIR=/mnt/models/resnet
CMD ["python", "train.py"]