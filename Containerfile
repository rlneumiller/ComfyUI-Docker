# STEP 1/23
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu22.04

# STEP 2/23
ARG UID=1000

# STEP 3/23
ARG GID=1000

# STEP 4/23
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256 \
    NVIDIA_TF32_OVERRIDE=1 \
    COMFYUI_RELEASE_BRANCH="release/v0.25"

# Required to workaround a buildah issue involving variable expansion in ENV instructions.
# STEP 5/23
ENV PATH="/home/appuser/venv/bin:/home/appuser/.local/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ROOT BEGIN ############################################################################################
# STEP 6/23
USER root

# STEP 7/23
RUN groupadd -g ${GID} appuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash appuser

# STEP 8/23
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-venv \
    python3-pip \
    python3.10-dev \
    curl \
    nodejs \
    npm \
    ripgrep \
    fd-find \
    && ln -s /usr/bin/fdfind /usr/bin/fd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# STEP 9/23
WORKDIR /workspace

# STEP 10/23
RUN git clone https://github.com/Comfy-Org/ComfyUI.git && \
    cd /workspace/ComfyUI && \
    git checkout -b ${COMFYUI_RELEASE_BRANCH} origin/${COMFYUI_RELEASE_BRANCH} && \
    mkdir -p temp models/checkpoints output user custom_nodes

# STEP 11/23
COPY entrypoint.sh /entrypoint.sh

# STEP 12/23
COPY auto_models.sh /auto_models.sh

# GIVE APPUSER OWNERSHIP of /workspace and /home/appuser ###################################################
# STEP 13/23
RUN chmod +x /entrypoint.sh /auto_models.sh && \
    chown -R appuser:appuser /workspace /home/appuser

# STEP 14/23
RUN mkdir -p /home/appuser/.cache/uv && \
    chown -R appuser:appuser /home/appuser/.cache

# APPUSER BEGIN ############################################################################################    
# STEP 15/23
USER appuser

# STEP 16/23
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# STEP 17/23
WORKDIR /workspace/ComfyUI

# STEP 18/23
RUN --mount=type=cache,target=/home/appuser/.cache/uv,uid=1000,gid=1000,mode=0777 \
    python3 -m venv /home/appuser/venv && \
    uv pip install --python /home/appuser/venv/bin/python --upgrade pip && \
    uv pip install --python /home/appuser/venv/bin/python torch torchvision --index-url https://download.pytorch.org/whl/cu130 && \
    uv pip install --python /home/appuser/venv/bin/python --upgrade gguf && \
    uv pip install --python /home/appuser/venv/bin/python -r requirements.txt && \
    uv pip install --python /home/appuser/venv/bin/python -U --pre comfyui-manager


# Reset ComfyUI database to avoid Alembic migration errors
# STEP 20/23
RUN rm -f /workspace/ComfyUI/comfyui.db

# STEP 21/23
EXPOSE 8188

# STEP 22/23
ENTRYPOINT ["/entrypoint.sh"]

# Provide full path to the appuser's venv so correct environment is used when running ComfyUI's main.py
# STEP 23/23
CMD ["/home/appuser/venv/bin/python", "main.py", "--enable-manager", "--listen", "0.0.0.0"]
