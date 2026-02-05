#!/bin/bash
# Wrapper for NDK clang to inject -lm linker flag
# This is required because mlc_llm (via TVM) treats the CC/CXX environment
# variables as direct file paths and doesn't handle appended flags.

# The real compiler path is passed via TVM_NDK_REAL_CC
"$TVM_NDK_REAL_CC" "$@" -lm
