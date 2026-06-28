#!/usr/bin/env bash
#
# _common.sh — Shared helpers for the Klever Academy class scripts.
#
# Not run directly — source it near the top of a script, right after
# `set -euo pipefail`:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
#   load_dotenv "$(dirname "${BASH_SOURCE[0]}")/../.env"
#
# Keeping config-loading and the pre-flight checks here means every script
# behaves the same way (single source of truth).

# Load KEY=VALUE settings from a .env file into the environment so the
# documented "configure .env" workflow actually takes effect. Call this BEFORE
# resolving `${VAR:-default}` config lines. `$HOME`-style values and `#` comment
# lines are handled (the file is parsed line-by-line, not executed).
#
# Precedence: explicit environment variables WIN over .env. So
# `KLEVER_NODE=... ./scripts/deploy.sh` is never silently overridden by .env —
# .env only fills in values you did not already set. (For each line we skip the
# key if it is already present in the environment, so pre-set variables win.)
load_dotenv() {
  local env_file="${1:-.env}" line key val
  [ -f "$env_file" ] || return 0
  echo "==> Loading config from $env_file"
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"        # trim leading whitespace
    case "$line" in ''|'#'*) continue ;; esac      # skip blanks and comments
    case "$line" in *=*) ;; *) continue ;; esac    # require KEY=VALUE
    key="${line%%=*}"
    case "$key" in ''|[0-9]*|*[!A-Za-z0-9_]*) continue ;; esac   # valid shell identifier only
    [ -n "${!key+x}" ] && continue                 # already set? environment wins
    val="${line#*=}"                               # value = everything after first =
    case "$val" in                                 # strip one pair of surrounding quotes
      \"*\") val="${val#\"}"; val="${val%\"}" ;;
      \'*\') val="${val#\'}"; val="${val%\'}" ;;
    esac
    val="${val/#\~/$HOME}"                         # expand a leading ~
    val="${val//\$HOME/$HOME}"; val="${val//\$\{HOME\}/$HOME}"  # expand $HOME refs
    export "$key=$val"                             # no eval -> no command substitution
  done < "$env_file"
}

# Abort with an actionable message if the wallet PEM is missing. koperator's own
# error for this ("KeyLoaded not found") is cryptic, so we check up front.
require_key_file() {
  local key_file="$1"
  [ -f "$key_file" ] && return 0
  {
    echo "ERROR: wallet key file (PEM) not found: $key_file"
    echo
    echo "Create a dedicated TESTNET wallet:"
    echo "  ~/klever-sdk/koperator account create --key-file=\"$key_file\""
    echo "or import your Klever Web Extension key:"
    echo "  ~/klever-sdk/koperator account import-sk <HEX_PRIVATE_KEY> --path \"$key_file\""
    echo
    echo "Then fund it from the faucet. Full steps: docs/01-setup.md (section 6)."
  } >&2
  exit 1
}

# Encode a u64 as a Klever VM `/sc/query` argument. The query API expects each
# argument as BASE64-encoded bytes (NOT hex). We encode the id as 8-byte
# big-endian and base64 it (the VM top-decodes it back into a u64).
#   sc_arg_u64 1  ->  AAAAAAAAAAE=
sc_arg_u64() {
  local hex esc
  hex="$(printf '%016x' "$1")"
  esc="$(printf '%s' "$hex" | sed 's/../\\x&/g')"
  # shellcheck disable=SC2059  # $esc is a controlled \xNN byte string used as the format
  printf "$esc" | base64
}

# Abort if the contract address is still the placeholder or empty.
require_contract_address() {
  local addr="$1"
  case "$addr" in
    ''|*_REPLACE_ME)
      {
        echo "ERROR: CONTRACT_ADDRESS is not set (still the placeholder)."
        echo "Deploy first (./scripts/deploy.sh), then set CONTRACT_ADDRESS in .env"
        echo "(or pass it inline). See docs/03-build-test-deploy.md."
      } >&2
      exit 1 ;;
  esac
}
