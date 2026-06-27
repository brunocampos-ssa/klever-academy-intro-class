#!/usr/bin/env bash
#
# deploy.sh — Deploy the Certificate Registry contract to a Klever network.
#
# What it does:
#   1. Builds the contract (so the .wasm is fresh).
#   2. Uses `koperator sc create` to deploy it and waits for the result.
#   3. Prints the resulting contract address.
#
# Usage:
#   ./scripts/deploy.sh
#
# Adjust the network, wallet, and contract path according to your environment.
# NEVER commit your real key file. Use a dedicated testnet wallet for class.

set -euo pipefail

# --- Configuration (override via environment or .env) ------------------------
KLEVER_SDK_PATH="${KLEVER_SDK_PATH:-$HOME/klever-sdk}"
KSC_BIN="${KSC_BIN:-$KLEVER_SDK_PATH/ksc}"
KOPERATOR_BIN="${KOPERATOR_BIN:-$KLEVER_SDK_PATH/koperator}"

# Network node URL. testnet is recommended for class.
#   mainnet: https://node.mainnet.klever.org
#   testnet: https://node.testnet.klever.org
#   local:   http://localhost:8080
KLEVER_NODE="${KLEVER_NODE:-https://node.testnet.klever.org}"

# Path to your wallet key file (PEM). Placeholder — point this at YOUR wallet.
KEY_FILE="${KEY_FILE:-$KLEVER_SDK_PATH/walletKey.pem}"

CONTRACT_DIR="${CONTRACT_DIR:-contracts/certificate-registry}"

# --- Build first -------------------------------------------------------------
echo "==> Building before deploy..."
( cd "$CONTRACT_DIR" && "$KSC_BIN" all build )

WASM_FILE="$(find "$CONTRACT_DIR/output" -name "*.wasm" | head -1)"
if [ -z "$WASM_FILE" ]; then
  echo "ERROR: No .wasm found. Did the build succeed?"
  exit 1
fi

echo "==> Deploying $WASM_FILE"
echo "    Node:   $KLEVER_NODE"
echo "    Wallet: $KEY_FILE"

# `sc create` is the CORRECT Klever deploy command.
#   --upgradeable --readable --payable : contract metadata flags
#   --await --sign --result-only       : sign, broadcast, wait, print JSON result
KLEVER_NODE="$KLEVER_NODE" "$KOPERATOR_BIN" \
  --key-file="$KEY_FILE" \
  sc create \
  --wasm="$WASM_FILE" \
  --upgradeable --readable --payable \
  --await --sign --result-only

echo "==> Deploy submitted. Copy the contract address (klv1...) from the output above."
echo "    Save it in your .env as CONTRACT_ADDRESS for the other scripts."
