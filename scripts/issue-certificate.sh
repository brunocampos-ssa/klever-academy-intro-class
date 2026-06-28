#!/usr/bin/env bash
#
# issue-certificate.sh — Issue a certificate by invoking the contract.
#
# What it does:
#   Calls the `issueCertificate(student, course, metadata_uri)` endpoint using
#   `koperator sc invoke`. Only the issuer wallet can do this successfully.
#
# Usage:
#   ./scripts/issue-certificate.sh <student_klv_address> "<course>" "<metadata_uri>"
#
# Example:
#   ./scripts/issue-certificate.sh klv1abc... "Klever Academy Intro Class" "ipfs://cid"
#
# Adjust the network, wallet, and contract address according to your environment.

set -euo pipefail

# Shared helpers + load config from .env (KEY_FILE, CONTRACT_ADDRESS, ...).
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_dotenv "$(dirname "${BASH_SOURCE[0]}")/../.env"

# --- Configuration (from .env above, or environment, or these defaults) ------
KLEVER_SDK_PATH="${KLEVER_SDK_PATH:-$HOME/klever-sdk}"
KOPERATOR_BIN="${KOPERATOR_BIN:-$KLEVER_SDK_PATH/koperator}"
KLEVER_NODE="${KLEVER_NODE:-https://node.testnet.klever.org}"
KEY_FILE="${KEY_FILE:-$KLEVER_SDK_PATH/walletKey.pem}"

# The deployed contract address (klv1...). Placeholder — set CONTRACT_ADDRESS.
CONTRACT_ADDRESS="${CONTRACT_ADDRESS:-klv1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq_REPLACE_ME}"

# Resolve a relative KEY_FILE (e.g. ./walletKey.pem from .env) against the repo
# root so the check works regardless of the current working directory.
KEY_FILE="$(resolve_path "$KEY_FILE")"

# Writing requires a signed transaction — both a wallet and a real contract.
require_key_file "$KEY_FILE"
require_contract_address "$CONTRACT_ADDRESS"

# --- Arguments ---------------------------------------------------------------
STUDENT="${1:-}"
COURSE="${2:-Klever Academy Intro Class}"
METADATA_URI="${3:-ipfs://replace-with-real-cid}"

if [ -z "$STUDENT" ]; then
  echo "Usage: $0 <student_klv_address> \"<course>\" \"<metadata_uri>\""
  exit 1
fi
# Light sanity check so an obvious mistake fails here with a clear message
# rather than as a cryptic koperator decode error. (Not full bech32 validation.)
case "$STUDENT" in
  klv1*) ;;
  *)
    echo "ERROR: student address should be a Klever address starting with 'klv1' (got: $STUDENT)" >&2
    exit 1 ;;
esac

echo "==> Issuing certificate"
echo "    Contract: $CONTRACT_ADDRESS"
echo "    Student:  $STUDENT"
echo "    Course:   $COURSE"
echo "    Metadata: $METADATA_URI"

# `sc invoke` calls a contract endpoint. Arguments are typed:
#   Address:<klv1...>  for addresses
#   String:<text>      for strings / byte buffers
KLEVER_NODE="$KLEVER_NODE" "$KOPERATOR_BIN" \
  --key-file="$KEY_FILE" \
  sc invoke "$CONTRACT_ADDRESS" issueCertificate \
  --args "Address:$STUDENT" \
  --args "String:$COURSE" \
  --args "String:$METADATA_URI" \
  --await --sign --result-only

echo "==> Done. The new certificate ID is in the result above (returnData)."
echo "    Query it with: ./scripts/query-certificate.sh <id>"
