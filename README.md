# MLC LLM Compiled Models for Android

[![Build and Release Models](https://github.com/Black-J08/MLC_Compiled_Models/actions/workflows/build_models.yml/badge.svg)](https://github.com/Black-J08/MLC_Compiled_Models/actions/workflows/build_models.yml)

This repository hosts the compiled **Qwen** and other MLC-compatible LLM models for the **Recall** Android app.

> [!NOTE]
> This repository is decoupled from the Recall app source code. The app consumes these models via **GitHub Releases**.

## Repository Structure

- `scripts/`: Build and release automation scripts.
- `.github/workflows`: CI/CD automation for cloud builds.
- `dist/`: Generated artifacts (ZIP bundles) ready for release.

## CI/CD & Automation

This repository uses **GitHub Actions** to automatically:
1.  **Fetch Weights**: Downloads model parameters from Hugging Face.
2.  **Compile Engines**: Builds native Android libraries (`.so`) for CPU, Vulkan, and OpenCL.
3.  **Package**: Creates separate optimized ZIP files for distribution.
4.  **Release**: Uploads assets to GitHub Releases when a tag (e.g., `v*`) is pushed.

## 📱 Android Integration Guide

The Recall app should fetch models from the [Releases Page](https://github.com/Black-J08/MLC_Compiled_Models/releases).

### 1. Artifact Strategy (Split Download)
To minimize bandwidth, artifacts are split into **Weights** and **Engines**.

| Artifact Type | Filename Pattern | Content | Size |
| :--- | :--- | :--- | :--- |
| **Weights** | `{model}-weights.zip` | `params/`, `config.json` | ~1GB+ |
| **Engine (CPU)** | `{model}-lib-cpu.zip` | `{model}_cpu.so` | ~5MB |
| **Engine (OpenCL)** | `{model}-lib-opencl.zip` | `{model}_opencl.so` | ~5MB |
| **Engine (Vulkan)** | `{model}-lib-vulkan.zip` | `{model}_vulkan.so` | ~5MB |

### 2. Integration Logic (Kotlin)
The app should download the **Weights** + **One Best Engine**.

```kotlin
// 1. Download Weights
val weightsUrl = "$RELEASE_URL/qwen2_5_0_5b-weights.zip"
downloadAndUnzip(weightsUrl, modelDir)

// 2. Select & Download Engine
val engineZip = when {
    deviceSupportsOpenCL() -> "qwen2_5_0_5b-lib-opencl.zip"
    deviceSupportsVulkan() -> "qwen2_5_0_5b-lib-vulkan.zip"
    else -> "qwen2_5_0_5b-lib-cpu.zip"
}
downloadAndUnzip("$RELEASE_URL/$engineZip", modelDir)

// 3. Initialize
val engine = MLCEngine()
engine.reload(modelDir.absolutePath, "qwen2_5_0_5b")
```

### 3. File Structure on Device
After unzipping both files into the same directory:
```
mlc_models/qwen2_5_0_5b/
├── mlc-chat-config.json
├── params/               # From weights.zip
│   └── ...
└── qwen2_5_0_5b_opencl.so # From lib-opencl.zip
```

---
*Maintained by the Recall Development Team.*
