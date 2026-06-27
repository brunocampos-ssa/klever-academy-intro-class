# AI Prompt — Debug a Build / Deploy / Runtime Error

Use this with **https://ai.klever.org** (or a Klever-aware AI / MCP client) when
something fails while building, deploying, or calling the contract.

> The more exact context you give (full command + full error), the better the
> diagnosis.

---

## Prompt

```text
You are a Klever VM troubleshooting expert. Help me fix an error. Be precise and
prioritize the single most likely cause first.

Context:
- Stage: <build | deploy | invoke/query | test>   (pick one)
- Command I ran:
<PASTE the exact command, e.g. `~/klever-sdk/ksc all build` or
 `koperator ... sc create ...`>

- Full error output:
---
<PASTE the COMPLETE error / stack trace>
---

- Relevant files (paste only what's needed):
  - Cargo.toml (contract):
  <PASTE if the error is build/version related>
  - The function involved:
  <PASTE the relevant part of src/lib.rs if runtime/invoke related>

- Environment:
  - ksc version: <output of `~/klever-sdk/ksc --version`>
  - rustc/cargo version: <output of `rustc --version`>
  - Network: <testnet | mainnet | local>

Please respond with:
1. Most likely cause (one clear sentence).
2. The exact fix (commands to run or lines to change). Smallest change first.
3. How to verify it worked (which command/test to re-run).
4. 1–2 alternative causes if the first fix doesn't resolve it.

Rules:
- Use the CORRECT Klever tooling (`ksc all build`, `koperator sc create/invoke`,
  `KLEVER_NODE`, `--key-file`). Do NOT suggest commands from other chains
  (no sc-meta, mxpy, hardhat, foundry).
- Don't invent klever-sc APIs; if unsure, point me to the relevant page on
  https://docs.klever.org.
```
