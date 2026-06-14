# STEP 1/43
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# STEP 2/43
ARG UID=1000

# STEP 3/43
ARG GID=1000

# STEP 4/43
ENV DEBIAN_FRONTEND=noninteractive

# STEP 5/43
ENV PYTHONUNBUFFERED=1

# For SDXL / Flux optimized attention
# STEP 6/43
ENV COMFYUI_USE_XFORMERS=1

# STEP 7/43
ENV TORCH_BACKEND_ENABLE_CUDA_FLASH_ATTENTION=1

# STEP 8/43
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256

# STEP 9/43
ENV NVIDIA_TF32_OVERRIDE=1

# STEP 10/43
ENV TORCH_ALLOW_TF32_CUBLAS=1

# STEP 11/43
ENV TORCH_ALLOW_TF32_CUDNN=1

# STEP 12/43
RUN groupadd -g ${GID} appuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash appuser

# STEP 13/43
USER root

# STEP 14/43
RUN rm -f /usr/lib/x86_64-linux-gnu/libnccl.so* \
       /usr/local/cuda/lib64/libnccl.so*


# STEP 15/43
USER appuser

# STEP 16/43
WORKDIR /workspace

# STEP 17/43
USER root

# STEP 18/43
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-venv \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# STEP 19/43
USER appuser

# STEP 20/43
RUN python3 -m venv /home/appuser/venv

# STEP 21/43
ENV PATH=/home/appuser/venv/bin:$PATH

# STEP 22/43
USER root

# STEP 23/43
RUN git clone https://github.com/Comfy-Org/ComfyUI.git && cd ComfyUI && git checkout v0.24.0

# STEP 24/43
RUN mkdir -p /workspace/ComfyUI/temp && chown -R appuser:appuser /workspace

# STEP 25/43
USER appuser

# STEP 26/43
WORKDIR /workspace/ComfyUI

# STEP 27/43
USER root

#RUN git checkout v0.24.0

# STEP 28/43
USER appuser

# STEP 29/43
RUN pip install --upgrade pip

# pytorch provides cuda 13.0 and 13.2 wheels, but not 13.1
# We use 13.0 as it is stable for Ada hardware and is compatible with the latest PyTorch versions.
# --index-url forces pip to install the NVIDIA‑optimized wheels - otherwise it would install the default PyPI (CPU only) wheels.
# STEP 30/43
RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130

# STEP 31/43
RUN pip install --pre xformers --index-url https://download.pytorch.org/whl/nightly/cu130

# Install ComfyUI deps
# STEP 32/43
RUN pip install -r requirements.txt

# STEP 33/43
USER root

# STEP 34/43
RUN mkdir -p models/checkpoints output user custom_nodes

# STEP 35/43
USER appuser

# STEP 36/43
COPY entrypoint.sh /entrypoint.sh

# STEP 37/43
COPY auto_models.sh /auto_models.sh

# STEP 38/43
USER root

# STEP 39/43
RUN chmod +x /entrypoint.sh /auto_models.sh

# STEP 40/43
USER appuser

# STEP 41/43
EXPOSE 8188

# STEP 42/43
ENTRYPOINT ["/entrypoint.sh"]

# STEP 43/43
CMD ["python", "main.py", "--listen", "0.0.0.0"]
