#!/bin/bash
cd $HOME/gits/neu-comfyui-podman && \
if git status --porcelain Containerfile | grep -q .; then
    echo "Containerfile has uncommitted changes - exiting"
    exit 1
fi

commit_hash=$(git log -1 --pretty=format:"%h" --abbrev=8 Containerfile) && \
echo "$commit_hash" > commit_hash && \
echo "Building ComfyUI image with commit hash: $commit_hash" && \
podman build -t comfyui-v0.25.0:commit-$commit_hash-gguf . && \
echo "comfyui-v0.25.0:commit-$commit_hash-gguf" > .image_tag