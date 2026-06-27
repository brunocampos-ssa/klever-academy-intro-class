# AI Prompt — Explain the Contract

Use this with **https://ai.klever.org** (or any Klever-aware AI / MCP client) to
get a clear explanation of the Certificate Registry contract.

> Tip: paste the full contents of
> `contracts/certificate-registry/src/lib.rs` where indicated.

---

## Prompt

```text
You are a senior Klever VM engineer and a patient teacher.

Audience: a developer who is comfortable with TypeScript but is NEW to Rust and
to Klever smart contracts. Avoid assuming Rust knowledge.

Here is the contract:

---
<PASTE contracts/certificate-registry/src/lib.rs HERE>
---

Please explain it in this structure:

1. One-paragraph summary of what the contract does and who uses it.
2. A TypeScript-developer's mental model: map Klever/Rust concepts to things I
   already know (e.g. "storage mapper ≈ a persistent key-value map",
   "ManagedBuffer ≈ bytes/string", "endpoint ≈ a POST, view ≈ a GET").
3. Walk through each section in order: init, write endpoints, views, storage,
   events, helpers. For each, explain WHAT it does and WHY it's written that way.
4. Explain the access control: who can call what, and how `require!` /
   `#[only_owner]` enforce it.
5. List 3 things that could go wrong if a caller misuses the contract, and how
   the contract prevents them.

Keep it concrete and reference the actual function names. Use short code
snippets only when they clarify. Do not invent functions that aren't in the
code. If something is a Klever-specific idiom, say so and point to the relevant
area of https://docs.klever.org.
```
