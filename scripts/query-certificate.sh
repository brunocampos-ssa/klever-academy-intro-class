#!/usr/bin/env bash
#
# query-certificate.sh — Read a certificate from the contract (free, no signing).
#
# What it does:
#   Calls the read-only `getCertificate(id)` and `isValid(id)` views through the
#   Klever public API `/sc/query` endpoint. Queries do NOT cost fees and do NOT
#   need a wallet — they just read state.
#
# Usage:
#   ./scripts/query-certificate.sh <certificate_id>
#
# Example:
#   ./scripts/query-certificate.sh 1
#
# Adjust the network and contract address according to your environment.

set -euo pipefail

# Shared helpers + load config from .env (CONTRACT_ADDRESS, API_URL, ...).
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
load_dotenv

# --- Configuration (from .env above, or environment, or these defaults) ------
# API base for queries (note: this is the API host, not the node host).
#   mainnet: https://api.mainnet.klever.org
#   testnet: https://api.testnet.klever.org
API_URL="${API_URL:-https://api.testnet.klever.org}"
CONTRACT_ADDRESS="${CONTRACT_ADDRESS:-klv1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq_REPLACE_ME}"

# Reads are free (no wallet), but they still need a real contract address.
require_contract_address "$CONTRACT_ADDRESS"

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "Usage: $0 <certificate_id>"
  exit 1
fi

# The /sc/query API expects each argument BASE64-encoded (not hex). Encode the
# u64 id with the shared helper (8-byte big-endian -> base64).
ID_ARG="$(sc_arg_u64 "$ID")"

echo "==> Querying certificate id=$ID on $API_URL"

query() {
  local func="$1"
  curl -s -X POST "$API_URL/v1.0/sc/query" \
    -H "Content-Type: application/json" \
    -d "{\"ScAddress\":\"$CONTRACT_ADDRESS\",\"FuncName\":\"$func\",\"Arguments\":[\"$ID_ARG\"]}"
}

echo "--- isValid ---"
query "isValid" | (jq '.' 2>/dev/null || cat)

echo "--- getCertificate (returnData is base64; decode to read fields) ---"
query "getCertificate" | (jq '.' 2>/dev/null || cat)

echo "==> Tip: for human-readable decoding, use the ABI with scripts/interact.ts"
echo "    or the Contract class from @klever/connect."
