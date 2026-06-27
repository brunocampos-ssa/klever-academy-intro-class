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
# Note: the included tests run the contract in-process (the test registers the
# Rust contract object directly), so NO prior build is required. If you later add
# file-based scenario tests that load `output/*.kleversc.json`, run
# ./scripts/build.sh first to produce that artifact.

set -euo pipefail

CONTRACT_DIR="${CONTRACT_DIR:-contracts/certificate-registry}"

echo "==> Running tests in: $CONTRACT_DIR"

if ! command -v cargo >/dev/null 2>&1; then
  echo "ERROR: cargo (Rust) is not installed. See docs/01-setup.md"
  exit 1
fi

( cd "$CONTRACT_DIR" && cargo test )

echo "==> Tests finished."
