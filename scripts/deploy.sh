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

# Shared helpers + load config from .env (KEY_FILE, KLEVER_NODE, ...).
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_dotenv "$(dirname "${BASH_SOURCE[0]}")/../.env"

# --- Configuration (from .env above, or environment, or these defaults) ------
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

# Resolve relative paths (e.g. KEY_FILE=./walletKey.pem from .env) against the
# repo root so the script works regardless of the current working directory.
KEY_FILE="$(resolve_path "$KEY_FILE")"
CONTRACT_DIR="$(resolve_path "$CONTRACT_DIR")"

# Fail early with a clear message if the wallet PEM is missing (koperator's own
# error, "KeyLoaded not found", does not explain what to do).
require_key_file "$KEY_FILE"

# Resolve this script's directory so we can reuse the project's build logic.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Build first (single source of truth: scripts/build.sh) ------------------
# Reuse the EXACT same build as `./scripts/build.sh` — including the
# Rust 1.82+ wasm-link fallback — so deploy never diverges from build. Env
# overrides are passed through so a custom SDK path / contract dir still works.
echo "==> Building before deploy..."
CONTRACT_DIR="$CONTRACT_DIR" KLEVER_SDK_PATH="$KLEVER_SDK_PATH" KSC_BIN="$KSC_BIN" \
  "$SCRIPT_DIR/build.sh"

# Prefer the canonical artifact build.sh produces; fall back to a search only
# if it's missing (avoids picking the wrong file when output/ has several).
WASM_FILE="$CONTRACT_DIR/output/certificate-registry.wasm"
if [ ! -f "$WASM_FILE" ]; then
  # `-print -quit` (not `| head -1`) avoids find being killed by SIGPIPE under
  # `set -o pipefail` when head closes the pipe early.
  WASM_FILE="$(find "$CONTRACT_DIR/output" -name '*.wasm' -print -quit)"
fi
if [ -z "${WASM_FILE:-}" ] || [ ! -f "$WASM_FILE" ]; then
  echo "ERROR: No .wasm found after build. Re-read the build output above."
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
