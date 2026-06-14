# STEP 1/42
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# STEP 2/42
ARG UID=1000

# STEP 3/42
ARG GID=1000

# STEP 4/42
ENV DEBIAN_FRONTEND=noninteractive

# STEP 5/42
ENV PYTHONUNBUFFERED=1

# For SDXL / Flux optimized attention
# STEP 6/42
ENV COMFYUI_USE_XFORMERS=1

# STEP 7/42
ENV TORCH_BACKEND_ENABLE_CUDA_FLASH_ATTENTION=1

# STEP 8/42
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256

# STEP 9/42
ENV NVIDIA_TF32_OVERRIDE=1

# STEP 10/42
ENV TORCH_ALLOW_TF32_CUBLAS=1

# STEP 11/42
ENV TORCH_ALLOW_TF32_CUDNN=1

# STEP 12/42
RUN groupadd -g ${GID} appuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash appuser

# STEP 13/42
USER root

# STEP 14/42
RUN rm -f /usr/lib/x86_64-linux-gnu/libnccl.so* \
       /usr/local/cuda/lib64/libnccl.so*


# STEP 15/42
USER appuser

# STEP 16/42
WORKDIR /workspace

# STEP 17/42
USER root

# STEP 18/42
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-venv \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# STEP 19/42
USER appuser

# STEP 20/42
RUN python3 -m venv /home/appuser/venv

# STEP 21/42
ENV PATH=/home/appuser/venv/bin:$PATH

# STEP 22/42
USER root

# STEP 23/42
RUN git clone https://github.com/Comfy-Org/ComfyUI.git && cd ComfyUI && git checkout v0.24.0

# STEP 24/42
RUN mkdir -p /workspace/ComfyUI/temp && chown -R appuser:appuser /workspace

# STEP 25/42
USER appuser

# STEP 26/42
WORKDIR /workspace/ComfyUI

# STEP 27/42
USER root

#RUN git checkout v0.24.0

# STEP 28/42
USER appuser

# STEP 29/42
RUN pip install --upgrade pip

# pytorch provides cuda 13.0 and 13.2 wheels, but not 13.1
# We use 13.0 as it is stable for Ada hardware and is compatible with the latest PyTorch versions.
# --index-url forces pip to install the NVIDIA‑optimized wheels - otherwise it would install the default PyPI (CPU only) wheels.
# STEP 30/42
RUN pip install --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/cu130

# Problematic for now, as it is not compatible with the latest PyTorch versions. 
# Maybe re-enable once it is compatible again.
#RUN pip install --pre xformers --index-url https://download.pytorch.org/whl/nightly/cu130

# Install ComfyUI deps
# STEP 31/42
RUN pip install -r requirements.txt

# STEP 32/42
USER root

# STEP 33/42
RUN mkdir -p models/checkpoints output user custom_nodes

# STEP 34/42
USER appuser

# STEP 35/42
COPY entrypoint.sh /entrypoint.sh

# STEP 36/42
COPY auto_models.sh /auto_models.sh

# STEP 37/42
USER root

# STEP 38/42
RUN chmod +x /entrypoint.sh /auto_models.sh

# STEP 39/42
USER appuser

# STEP 40/42
EXPOSE 8188

# STEP 41/42
ENTRYPOINT ["/entrypoint.sh"]

# STEP 42/42
CMD ["python", "main.py", "--listen", "0.0.0.0"]
