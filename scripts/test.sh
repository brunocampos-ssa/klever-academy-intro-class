#!/usr/bin/env bash
#
# test.sh — Run the contract's unit/integration tests.
#
# What it does:
#   Runs `cargo test` for the Certificate Registry contract. Tests execute in a
#   simulated blockchain (klever-sc-scenario) — no network or real KLV needed.
#
# Usage:
#   ./scripts/test.sh
#
# Tip: some scenario tests need the compiled wasm first. If a test complains
# about a missing .mxsc.json / .wasm, run ./scripts/build.sh before testing.

set -euo pipefail

CONTRACT_DIR="${CONTRACT_DIR:-contracts/certificate-registry}"

echo "==> Running tests in: $CONTRACT_DIR"

if ! command -v cargo >/dev/null 2>&1; then
  echo "ERROR: cargo (Rust) is not installed. See docs/01-setup.md"
  exit 1
fi

( cd "$CONTRACT_DIR" && cargo test )

echo "==> Tests finished."
