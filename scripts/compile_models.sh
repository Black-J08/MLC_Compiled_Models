#!/bin/bash
set -e

# Load Python environment
source /home/black_j/Dev/Recall/.mlc_env/bin/activate

# Environment Variables
export ANDROID_NDK="/home/black_j/Android/Sdk/ndk/27.0.11718014"
export TVM_NDK_CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"
export MLC_LLM_SOURCE_DIR="/home/black_j/Dev/mlc-llm"

mkdir -p /home/black_j/Dev/Recall/model_artifacts

compile_model() {
    local model_hf=$1
    local model_id=$2
    local backend=$3
    local target=$4
    
    echo "Compiling $model_id for $backend..."
    
    output_dir="/home/black_j/Dev/Recall/model_artifacts/$model_id/$backend"
    repo_dir="../MLC_Compiled_Models/${model_id}_q4f16_1/$backend"
    mkdir -p "$output_dir"
    mkdir -p "$repo_dir"
    
    python3 -m mlc_llm compile "$model_hf" \
        --device "$target" \
        --host aarch64-linux-android \
        --system-lib-prefix "$model_id" \
        -o "$output_dir/${model_id}_${backend}.tar"
        
    cp "$output_dir/${model_id}_${backend}.tar" "$repo_dir/"
    echo "Done with $model_id $backend"
}

# Qwen 0.5B
compile_model "HF://mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC" "qwen2_5_0_5b" "cpu" "llvm" || echo "Failed 0.5B CPU"
# compile_model "HF://mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC" "qwen2_5_0_5b" "vulkan" "vulkan" || echo "Failed 0.5B Vulkan"
compile_model "HF://mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC" "qwen2_5_0_5b" "opencl" "opencl" || echo "Failed 0.5B OpenCL"

# Qwen 1.5B
compile_model "HF://mlc-ai/Qwen2.5-1.5B-Instruct-q4f16_1-MLC" "qwen2_5_1_5b" "cpu" "llvm" || echo "Failed 1.5B CPU"
# compile_model "HF://mlc-ai/Qwen2.5-1.5B-Instruct-q4f16_1-MLC" "qwen2_5_1_5b" "vulkan" "vulkan" || echo "Failed 1.5B Vulkan"
compile_model "HF://mlc-ai/Qwen2.5-1.5B-Instruct-q4f16_1-MLC" "qwen2_5_1_5b" "opencl" "opencl" || echo "Failed 1.5B OpenCL"

# Qwen 3B
compile_model "HF://mlc-ai/Qwen2.5-3B-Instruct-q4f16_1-MLC" "qwen2_5_3b" "cpu" "llvm" || echo "Failed 3B CPU"
compile_model "HF://mlc-ai/Qwen2.5-3B-Instruct-q4f16_1-MLC" "qwen2_5_3b" "opencl" "opencl" || echo "Failed 3B OpenCL"
