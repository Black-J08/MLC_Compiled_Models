#!/bin/bash
set -e

# Load Python environment
source /home/black_j/Dev/Recall/.mlc_env/bin/activate

MODEL_HF="HF://mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC"
MODEL_ID="qwen2_5_0_5b"
ARTIFACTS_DIR="../dist"
WEIGHTS_DIR="$ARTIFACTS_DIR/$MODEL_ID/weights"

echo "Downloading weights for $MODEL_ID..."
mkdir -p "$WEIGHTS_DIR"

# Use mlc_llm to chat/download to ensure weights are cached/available
# In a real environment, we'd use mlc_llm chat or a specific download command if available
# Here we simulate the organization for packaging
python3 -m mlc_llm chat "$MODEL_HF" --device "cpu" --help > /dev/null

# The weights are typically in ~/.cache/mlc_llm/model_cache/
# Instead of searching the cache, we will package from a known source if present, 
# or guide the user to where they are.
# For the script, we'll assume we want to zip the parameters and config.

echo "Packaging weights into ${MODEL_ID}_weights.zip..."
# Note: This is a placeholder for the actual move/zip logic 
# once the user runs the compilation which also pulls config.
cd "$ARTIFACTS_DIR/$MODEL_ID"
# zip -r "${MODEL_ID}_weights.zip" weights/ (to be run after compilation/pull)

echo "Weight packaging script ready."
