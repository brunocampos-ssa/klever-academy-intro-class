#!/usr/bin/env bash
#
# build.sh — Compile the Certificate Registry contract to WebAssembly.
#
# What it does:
#   1. Runs `ksc all build`, which generates the ABI + the `wasm/` build crate
#      and (on a fully compatible SDK/toolchain) the deployable .wasm.
#   2. If `ksc` did not emit a .wasm — a known incompatibility between
#      klever-sc 0.45 and Rust 1.82+, see the note below — it builds the
#      generated `wasm/` crate directly with the required linker flag and
#      optimizes it with `wasm-opt` when available.
#   3. Fails loudly if no .wasm is produced (it never reports a false success).
#
# Usage:
#   ./scripts/build.sh
#
# Why the fallback exists:
#   Rust 1.82+ no longer auto-imports *undefined* wasm symbols. The Klever VM
#   host functions (mBufferNew, signalError, ...) are declared by
#   klever-sc-wasm-adapter as undefined imports, so the link fails with
#   "undefined symbol: mBufferNew" unless `--import-undefined` is passed. The
#   installed `ksc` does not pass it (and overrides RUSTFLAGS), so we relink the
#   generated crate ourselves. The flag lives in
#   contracts/certificate-registry/.cargo/config.toml (wasm targets only).
#   The clean long-term fix is an updated Klever SDK — see docs/03.

set -euo pipefail

# --- Configuration (override via environment if needed) ----------------------
KLEVER_SDK_PATH="${KLEVER_SDK_PATH:-$HOME/klever-sdk}"
KSC_BIN="${KSC_BIN:-$KLEVER_SDK_PATH/ksc}"
CONTRACT_DIR="${CONTRACT_DIR:-contracts/certificate-registry}"
WASM_NAME="certificate-registry.wasm"

echo "==> Building contract in: $CONTRACT_DIR"

if [ ! -x "$KSC_BIN" ]; then
  echo "ERROR: ksc not found at $KSC_BIN"
  echo "Install the Klever developer tools first: see docs/01-setup.md"
  exit 1
fi

# --- 1) Official build (also generates ABI + the wasm/ crate) ----------------
# Start clean so the "did we produce a .wasm?" check below reflects THIS run and
# never succeeds on a stale artifact from a previous build.
rm -f "$CONTRACT_DIR"/output/*.wasm 2>/dev/null || true

# `ksc all build` is the CORRECT Klever build command. We tolerate a nonzero
# exit here so the fallback below can take over if only the wasm LINK failed.
( cd "$CONTRACT_DIR" && "$KSC_BIN" all build ) || true

# --- 2) Fallback: relink the generated wasm crate if ksc produced no .wasm ----
if ! ls "$CONTRACT_DIR"/output/*.wasm >/dev/null 2>&1; then
  echo "==> ksc did not emit a .wasm — using the direct wasm-build fallback."
  echo "    (known klever-sc 0.45 + Rust 1.82+ link issue — see docs/03)"

  if [ ! -f "$CONTRACT_DIR/wasm/Cargo.toml" ]; then
    echo "ERROR: ksc did not generate the wasm/ crate. Re-read the ksc output above."
    exit 1
  fi

  # Pick a wasm target the toolchain actually has installed.
  installed_targets="$(rustup target list --installed 2>/dev/null || true)"
  if echo "$installed_targets" | grep -qx "wasm32v1-none"; then
    WASM_TARGET="wasm32v1-none"
  elif echo "$installed_targets" | grep -qx "wasm32-unknown-unknown"; then
    WASM_TARGET="wasm32-unknown-unknown"
  else
    echo "ERROR: no wasm target installed. Install one of:"
    echo "  rustup target add wasm32v1-none            # preferred (ksc default toolchain)"
    echo "  rustup target add wasm32-unknown-unknown   # fallback"
    exit 1
  fi
  echo "    target: $WASM_TARGET"

  # Supply the linker flag explicitly via cargo's PER-TARGET rustflags env var.
  # This is independent of `.cargo/config.toml` discovery (which depends on the
  # invoking directory) and is scoped to the wasm target only, so host build
  # scripts are never passed `--import-undefined` (which `cc` would reject).
  export CARGO_TARGET_WASM32V1_NONE_RUSTFLAGS="${CARGO_TARGET_WASM32V1_NONE_RUSTFLAGS:-} -C link-arg=--import-undefined"
  export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS="${CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS:-} -C link-arg=--import-undefined"

  ( cd "$CONTRACT_DIR" \
      && cargo build --manifest-path wasm/Cargo.toml --release \
           --target "$WASM_TARGET" --target-dir wasm/target )

  built_wasm="$(find "$CONTRACT_DIR/wasm/target/$WASM_TARGET/release" -maxdepth 1 -name '*.wasm' | head -1)"
  if [ -z "$built_wasm" ]; then
    echo "ERROR: fallback build did not produce a .wasm."
    exit 1
  fi

  mkdir -p "$CONTRACT_DIR/output"
  cp "$built_wasm" "$CONTRACT_DIR/output/$WASM_NAME"

  # Optional: shrink the binary if wasm-opt is available.
  if command -v wasm-opt >/dev/null 2>&1; then
    wasm-opt -Oz "$CONTRACT_DIR/output/$WASM_NAME" -o "$CONTRACT_DIR/output/$WASM_NAME" \
      && echo "    optimized with wasm-opt"
  else
    echo "    (wasm-opt not on PATH — skipping size optimization; the .wasm still deploys)"
  fi
fi

# --- 3) Verify and report ----------------------------------------------------
if ls "$CONTRACT_DIR"/output/*.wasm >/dev/null 2>&1; then
  echo "==> Build complete. Artifacts:"
  find "$CONTRACT_DIR/output" -name "*.wasm" -exec ls -lh {} \;
  find "$CONTRACT_DIR/output" -name "*.abi.json" -exec ls -lh {} \;
else
  echo "ERROR: build did not produce a .wasm in $CONTRACT_DIR/output/."
  echo "Check the logs above. See docs/03-build-test-deploy.md (toolchain notes)."
  exit 1
fi
