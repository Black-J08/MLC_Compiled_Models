# MLC LLM Compiled Models for Android

This repository serves as the central documentation and automation hub for the compiled MLC LLM models used in the **Recall** Android app.

## Repository Overview

To maintain a clean and lightweight git history, this repository does not host binary model files directly in the `main` branch. Instead, all compiled models, weights, and configuration files are hosted as **GitHub Release Assets**.

### 🚀 Quick Start for App Integration

If you are developing the Recall app:
1. Ensure your model definitions in `AIModel.kt` point to the latest Release URLs.
2. The app's `ModelManager` handles the detection of device capabilities (Vulkan, OpenCL, or CPU).
3. Optimized backends are automatically downloaded and initialized by the engine.

## Multi-Backend Strategy

We prioritize hardware acceleration while ensuring universal compatibility:

| Backend | Capability | Status |
|---------|------------|--------|
| **Vulkan** | Native Android GPU (API 24+) | Primary Target |
| **OpenCL** | Adreno/Mali GPU acceleration | Secondary Target |
| **LLVM (CPU)** | Universal ARMv8-A compatibility | Reliable Fallback |

## Compilation & Automation

The `scripts/` directory contains automation utilities for model compilation.

### Prerequisites
- [MLC LLM](https://llm.mlc.ai/docs/get_started/introduction.html)
- Android NDK (r27+)
- TVM with Vulkan/OpenCL support

### Build Commands
To compile a model library for multiple backends:
```bash
./scripts/compile_models.sh
```

## Hosting & Distribution

We use **GitHub Releases** to distribute:
- **Weights Bundle**: `[model_id]_weights.zip` (Configs + Shards)
- **Native Libraries**: `[model_id]_[backend].tar` (Compiled libraries)

---
*Maintained by the Recall Development Team.*
