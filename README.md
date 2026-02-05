# MLC LLM Compiled Models for Android (MVP)

This repository serves as the central hub for the compiled **Qwen-0.5B** MLC LLM models used in the **Recall** Android app. 

> [!NOTE]
> This repository is fully decoupled from the Recall mobile app code. The app consumes these models exclusively through GitHub Releases.

## MVP Overview

The current MVP focuses on the **Qwen2.5-0.5B-Instruct** model to ensure a lightweight and efficient local AI experience.

### 🚀 Integration for Recall App
1. Model weights are packaged as `[model_id]_weights.zip`.
2. Native libraries are packaged as `[model_id]_[backend].tar`.
3. The Recall app downloads these assets from GitHub Releases (Version `v1.1.0+`).

## Compilation & Development

The `scripts/` directory contains tools to compile models locally.

### Prerequisites
- [MLC LLM](https://llm.mlc.ai/docs/get_started/introduction.html)
- Android NDK (r27+)
- TVM with Vulkan/OpenCL/LLVM support

### Build Commands
To compile the Qwen-0.5B model for multiple backends:
```bash
./scripts/compile_models.sh
```
Artifacts will be generated in the `dist/` directory (ignored by Git).

## Hosting & Distribution

We use **GitHub Releases** for distribution:
- **Weights Bundle**: `qwen2_5_0_5b_weights.zip`
- **Native Libraries**: 
    - `qwen2_5_0_5b_cpu.tar`
    - `qwen2_5_0_5b_vulkan.tar`
    - `qwen2_5_0_5b_opencl.tar`

---
*Maintained by the Recall Development Team.*
