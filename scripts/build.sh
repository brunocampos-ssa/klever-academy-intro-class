#!/usr/bin/env bash
#
# build.sh — Compile the Certificate Registry contract to WebAssembly.
#
# What it does:
#   Runs the Klever Smart Contract compiler (`ksc`) which produces the .wasm
#   binary and the ABI JSON inside the contract's `output/` directory.
#
# Usage:
#   ./scripts/build.sh
#
# Adjust the network, wallet, and contract path according to your environment.

set -euo pipefail

# --- Configuration (override via environment if needed) ----------------------
# Path to the Klever SDK installed from https://install.klever.org
KLEVER_SDK_PATH="${KLEVER_SDK_PATH:-$HOME/klever-sdk}"
KSC_BIN="${KSC_BIN:-$KLEVER_SDK_PATH/ksc}"

# Where the contract lives, relative to the repo root.
CONTRACT_DIR="${CONTRACT_DIR:-contracts/certificate-registry}"

# --- Build -------------------------------------------------------------------
echo "==> Building contract in: $CONTRACT_DIR"

if [ ! -x "$KSC_BIN" ]; then
  echo "ERROR: ksc not found at $KSC_BIN"
  echo "Install the Klever developer tools first: see docs/01-setup.md"
  exit 1
fi

# `ksc all build` is the CORRECT Klever build command.
# (Do NOT use sc-meta / mxpy / cargo build directly — those are other chains.)
( cd "$CONTRACT_DIR" && "$KSC_BIN" all build )

echo "==> Build complete. Artifacts:"
find "$CONTRACT_DIR/output" -name "*.wasm" -exec ls -lh {} \; 2>/dev/null || \
  echo "   (no output/ dir found — check the build logs above)"
