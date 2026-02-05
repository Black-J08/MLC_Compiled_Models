#!/bin/bash
set -e

# =============================================================================
# MLC LLM Android Model Compiler & Packager
# =============================================================================
# This script downloads model weights, compiles them for Android (CPU/OpenCL/Vulkan),
# and packages them into separate artifacts for efficient distribution.
#
# Environment Variables (Optional override):
#   ANDROID_NDK: Path to Android NDK (default: tries to find it)
#   TVM_NDK_CC: Path to NDK clang compiler
#   MLC_LLM_SOURCE_DIR: Path to MLC LLM source (optional)
# =============================================================================

# --- 1. Environment Setup ---

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$REPO_ROOT/dist"
BUILD_DIR="$REPO_ROOT/build"

mkdir -p "$DIST_DIR"
mkdir -p "$BUILD_DIR"

# Try to detect NDK if not set
if [ -z "$ANDROID_NDK" ]; then
    # Common NDK locations or locally hardcoded fallback for dev
    if [ -d "$ANDROID_NDK_HOME" ]; then
        export ANDROID_NDK="$ANDROID_NDK_HOME"
    elif [ -d "$HOME/Android/Sdk/ndk/27.0.11718014" ]; then
        export ANDROID_NDK="$HOME/Android/Sdk/ndk/27.0.11718014"
    else
        echo "Error: ANDROID_NDK not set and not found in standard locations."
        exit 1
    fi
fi

# Set compiler path
if [ -z "$TVM_NDK_CC" ]; then
    export TVM_NDK_CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"
fi

if [ ! -f "$TVM_NDK_CC" ]; then
    echo "Error: NDK Compiler not found at $TVM_NDK_CC"
    exit 1
fi

export CC="$TVM_NDK_CC"
export CXX="$TVM_NDK_CC"

echo "Using NDK: $ANDROID_NDK"
echo "Using Compiler: $CC"

# --- 2. Build Function ---

package_model() {
    local model_hf_url=$1
    local model_id=$2
    local model_lib_prefix=$3

    echo "=================================================="
    echo " Processing Model: $model_id"
    echo "=================================================="

    local model_build_dir="$BUILD_DIR/$model_id"
    local params_dir="$model_build_dir/params"
    
    mkdir -p "$params_dir"

    echo "--> [Step A] Fetching Weights..."
    if [ ! -f "$model_build_dir/mlc-chat-config.json" ]; then
        echo "    Cloning from Hugging Face ($model_hf_url)..."
        # Temporarily clone to a temp dir to sort files
        local temp_clone_dir="$model_build_dir/temp_clone"
        
        # Retry logic for transient network errors (like 504)
        local max_retries=3
        local count=0
        local success=false
        while [ $count -lt $max_retries ]; do
            if git clone --depth 1 "$model_hf_url" "$temp_clone_dir"; then
                success=true
                break
            fi
            count=$((count + 1))
            echo "    Download failed (attempt $count). Retrying in 10 seconds..."
            sleep 10
        done

        if [ "$success" = false ]; then
            echo "    Error: Failed to download weights after $max_retries attempts."
            exit 1
        fi

        # Move essential config files to root of build dir
        mv "$temp_clone_dir/mlc-chat-config.json" "$model_build_dir/"
        mv "$temp_clone_dir"/tokenizer*.json "$model_build_dir/" || true
        mv "$temp_clone_dir"/vocab.json "$model_build_dir/" || true
        
        # Move weights to params/
        mv "$temp_clone_dir/ndarray-cache.json" "$params_dir/"
        mv "$temp_clone_dir"/*.bin "$params_dir/" || true

        rm -rf "$temp_clone_dir"
    else
        echo "    Weights appear to be present. Skipping download."
    fi

    # --- Step B: Compile Engines ---
    echo "--> [Step B] Compiling Engines..."
    local lib_dir="$model_build_dir/libs"
    mkdir -p "$lib_dir"

    # CRITICAL CHANGE: Use local directory for compilation to avoid HF timeouts
    local compile_target="$model_build_dir"
    echo "    Using local model path: $compile_target"

    # --- 1. Compile for CPU ---
    local cpu_lib="$lib_dir/${model_id}_cpu.so"
    echo "    Compiling for CPU -> $cpu_lib"
    python3 -m mlc_llm compile "$compile_target" \
        --device "llvm -mtriple=aarch64-linux-android" \
        --system-lib-prefix "$model_lib_prefix" \
        -o "$cpu_lib"

    # --- 2. Compile for OpenCL ---
    local opencl_lib="$lib_dir/${model_id}_opencl.so"
    echo "    Compiling for OpenCL -> $opencl_lib"
    python3 -m mlc_llm compile "$compile_target" \
        --device "opencl" \
        --host "llvm -mtriple=aarch64-linux-android" \
        --system-lib-prefix "$model_lib_prefix" \
        -o "$opencl_lib"

    # --- 3. Compile for Vulkan ---
    local vulkan_lib="$lib_dir/${model_id}_vulkan.so"
    echo "    Compiling for Vulkan -> $vulkan_lib"
    python3 -m mlc_llm compile "$compile_target" \
        --device "vulkan" \
        --host "llvm -mtriple=aarch64-linux-android" \
        --system-lib-prefix "$model_lib_prefix" \
        -o "$vulkan_lib"

    # --- Step C: Package & Split Artifacts ---
    echo "--> [Step C] Packaging Artifacts..."

    local backends=("cpu" "vulkan" "opencl")

    # 1. Weights Bundle {model}-weights.zip
    # Contains: params/, mlc-chat-config.json, tokenizer...
    local weights_zip="${model_id}-weights.zip"
    echo "    Creating Weights Bundle: $weights_zip"
    (
        cd "$model_build_dir"
        zip -r "$DIST_DIR/$weights_zip" \
            params/ \
            mlc-chat-config.json \
            tokenizer*.json \
            vocab.json \
            -x "*.DS_Store"
    )

    # 2. Engine Bundles {model}-lib-{backend}.zip
    # Contains: just the .so file at root (or libs folder? Recall app expects libs/ or flat? 
    # Let's verify Recall app expectation later. For now, flat or known structure effectively.
    # To keep it simple for extraction: we zip the .so file. 
    # If we zip it as "libs/x.so", extraction merges nicely. Let's do that.
    
    for backend in "${backends[@]}"; do
        local lib_zip="${model_id}-lib-${backend}.zip"
        echo "    Creating Engine Bundle: $lib_zip"
        # Be careful with paths. We want the zip to contain the file, maybe named simply 'lib.so' or fully named?
        # Fully named is safer for identifying version.
        # But for the App, does it expect a fixed name? 
        # The App usually loads by explicit path. 
        # Let's zip the full path structure `libs/x.so` or just `x.so`.
        # Decision: Zip `x.so` directly. The App will unzip it and we get the file.
        
        (
            cd "$lib_dir"
            zip "$DIST_DIR/$lib_zip" "${model_id}_${backend}.so"
        )
    done

    # --- Step D: Checksums ---
    echo "--> [Step D] Generating Checksums..."
    (
        cd "$DIST_DIR"
        sha256sum "${model_id}-weights.zip" > "${model_id}-weights.zip.sha256"
        for backend in "${backends[@]}"; do
            sha256sum "${model_id}-lib-${backend}.zip" > "${model_id}-lib-${backend}.zip.sha256"
        done
    )

    echo "=== Completed $model_id ==="
}

# --- 3. Execute ---

# Qwen 2.5 0.5B
package_model "https://huggingface.co/mlc-ai/Qwen2.5-0.5B-Instruct-q4f16_1-MLC" \
              "qwen2_5_0_5b" \
              "qwen2_5_0_5b_q4f16_1"

echo "--------------------------------------------------"
echo "Build Complete. Artifacts located in dist/"
ls -lh "$DIST_DIR"
