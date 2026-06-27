# AI Prompt — Review the Contract

Use this with **https://ai.klever.org** (or a Klever-aware AI / MCP client) to
get a focused review of the Certificate Registry contract for common smart
contract and Klever VM issues.

---

## Prompt

```text
You are a smart contract security reviewer specialized in Klever VM (the
klever-sc Rust framework). Review the contract below for REAL, actionable issues
only — no generic advice, no padding.

Here is the contract:

---
<PASTE contracts/certificate-registry/src/lib.rs HERE>
---

Review it across these dimensions and report findings as a table with columns:
[Severity] [Location (function/line)] [Issue] [Recommended fix].

Dimensions to check:
1. Access control — can the wrong caller issue, revoke, or change the issuer?
   Are `require!` checks and `#[only_owner]` placed correctly?
2. Input validation — empty buffers, zero/empty addresses, duplicate IDs.
3. State integrity — counter (lastId) correctness, map insert/overwrite,
   revocation flag handling, upgrade safety (no accidental state reset).
4. Arithmetic — overflow/underflow on the ID counter or any math.
5. Storage cost / gas — anything that grows unboundedly or is wasteful.
6. Events — are issue/revoke events emitted with the right indexed topics?
7. ABI/return types — do views return sensible, decodable types?
8. Klever VM idioms — anything that is NOT idiomatic klever-sc or that copies a
   pattern from a different chain incorrectly.

Rules:
- Severity is one of: Critical / High / Medium / Low / Info.
- Only report issues you can point to a specific line for.
- If the contract is fine on a dimension, say "OK" with one sentence why.
- Prefer the smallest correct fix. Show the exact replacement line(s).
- Do not invent framework APIs; if unsure about a klever-sc symbol, say so and
  reference https://docs.klever.org.
```
