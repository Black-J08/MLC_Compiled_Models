#!/bin/bash
set -e

# Load Python environment
source /home/black_j/Dev/Recall/.mlc_env/bin/activate

# Environment Variables
export ANDROID_NDK="/home/black_j/Android/Sdk/ndk/27.0.11718014"
export TVM_NDK_CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"
export MLC_LLM_SOURCE_DIR="/home/black_j/Dev/mlc-llm"

# Local artifact directory within the repo for decoupling
ARTIFACTS_DIR="../dist"
mkdir -p "$ARTIFACTS_DIR"

compile_model() {
    local model_hf=$1
    local model_id=$2
    local backend=$3
    local target=$4
    
    echo "Compiling $model_id for $backend..."
    
    output_dir="$ARTIFACTS_DIR/$model_id/$backend"
    mkdir -p "$output_dir"
    
    python3 -m mlc_llm compile "$model_hf" \
        --device "$target" \
        --host aarch64-linux-android \
        --system-lib-prefix "$model_id" \
        -o "$output_dir/${model_id}_${backend}.tar"
        
    echo "Done with $model_id $backend"
}

# Qwen 0.5B MVP
MODEL_HF="HF://mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC"
MODEL_ID="qwen2_5_0_5b"

compile_model "$MODEL_HF" "$MODEL_ID" "cpu" "llvm" || echo "Failed 0.5B CPU"
compile_model "$MODEL_HF" "$MODEL_ID" "vulkan" "vulkan" || echo "Failed 0.5B Vulkan"
compile_model "$MODEL_HF" "$MODEL_ID" "opencl" "opencl" || echo "Failed 0.5B OpenCL"

echo "Compilation complete. Artifacts are in $ARTIFACTS_DIR"
