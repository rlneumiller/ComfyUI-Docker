
# podman build -t comfyui-neu:latest . <-- Don't forget the dot at the end of the command to build the image from the current directory.
# STEP 1/19
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# 1. Environment & Arguments (Static Metadata)
# STEP 2/19
ARG UID=1000

# STEP 3/19
ARG GID=1000

# STEP 4/19
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    COMFYUI_USE_XFORMERS=1 \
    TORCH_BACKEND_ENABLE_CUDA_FLASH_ATTENTION=1 \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256 \
    NVIDIA_TF32_OVERRIDE=1 \
    TORCH_ALLOW_TF32_CUBLAS=1 \
    TORCH_ALLOW_TF32_CUDNN=1 \
    PATH=/home/appuser/venv/bin:$PATH

# 2. System Setup (All Root Tasks Grouped)
# STEP 5/19
USER root

# STEP 6/19
RUN groupadd -g ${GID} appuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash appuser

# System dependencies
# STEP 7/19
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-venv \
    python3-pip \
    python3.10-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clean conflicting elements & handle Triton's link compilation setup
# STEP 8/19
RUN rm -f /usr/lib/x86_64-linux-gnu/libnccl.so* /usr/local/cuda/lib64/libnccl.so* && \
    mkdir -p /usr/lib/x86_64-linux-gnu && \
    ln -sf /usr/lib/x86_64-linux-gnu/libcuda.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so

# Project Directory setup
# STEP 9/19
WORKDIR /workspace

# STEP 10/19
RUN git clone https://github.com/Comfy-Org/ComfyUI.git && \
    cd ComfyUI && \
    git checkout v0.24.0 && \
    mkdir -p temp models/checkpoints output user custom_nodes

# Scripts setup
# STEP 11/19
COPY entrypoint.sh /entrypoint.sh

# STEP 12/19
COPY auto_models.sh /auto_models.sh

# STEP 13/19
RUN chmod +x /entrypoint.sh /auto_models.sh && \
    chown -R appuser:appuser /workspace /home/appuser

# 3. Application Setup (All Non-Privileged Tasks Grouped)
# STEP 14/19
USER appuser

# STEP 15/19
WORKDIR /workspace/ComfyUI

# Python Virtual Environment and packages
# STEP 16/19
RUN python3 -m venv /home/appuser/venv && \
    pip install --upgrade pip && \
    pip install --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/cu130 && \
    pip install -r requirements.txt

# STEP 17/19
EXPOSE 8188

# STEP 18/19
ENTRYPOINT ["/entrypoint.sh"]

# STEP 19/19
CMD ["python", "main.py", "--listen", "0.0.0.0"]
