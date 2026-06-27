# 05 — AI-Assisted Development

[Português do Brasil](./05-ai-assisted-development-pt-BR.md)

Use **https://ai.klever.org** and the **Klever MCP** as a developer assistant
while you build. AI is great for explaining, reviewing, debugging, and
generating tests — but you stay the engineer who verifies the result.

> Beginner focus: ask AI to explain code you don't understand.
> Intermediate focus: ask for reviews and test ideas.
> Advanced focus: wire the Klever MCP into your editor and automate checks.

---

## What is `ai.klever.org` / Klever MCP?

- **`ai.klever.org`** — a Klever-aware AI assistant that knows the Klever VM,
  the SDK, and the tooling, so its answers use the *correct* Klever commands
  (e.g. `ksc all build`, `koperator sc create`) instead of other chains'.
- **Klever MCP** — a Model Context Protocol server that exposes Klever knowledge
  and on-chain tools to AI clients (like Claude or your IDE). It can search the
  docs, scaffold projects, and query the chain on your behalf.

> Why it matters: a generic AI often hallucinates commands from other
> blockchains. A Klever-aware assistant grounds its answers in Klever's actual
> tools and docs.

---

## What to use it for

### 1. Explain code
Paste the contract and ask for a plain-language walkthrough.
→ See [`prompts/ai-explain-contract.md`](../prompts/ai-explain-contract.md)

### 2. Review contracts
Ask for a focused review of access control, storage, and Klever VM pitfalls.
→ See [`prompts/ai-review-contract.md`](../prompts/ai-review-contract.md)

### 3. Debug errors
Paste the exact error from `ksc`/`koperator`/`cargo` and ask for likely causes.
→ See [`prompts/ai-debug-contract.md`](../prompts/ai-debug-contract.md)

### 4. Generate tests
> "Write `klever-sc-scenario` tests for the revoke flow: issue a certificate,
> revoke it, then assert `isValid` returns false and re-revoking errors."

### 5. Improve documentation
> "Turn the endpoint table in `docs/02-smart-contract.md` into doc comments
> above each function in `lib.rs`, keeping the wording concise."

---

## Example prompts

**Explain a single concept**
> "In this Klever contract, what does `MapMapper<u64, Certificate>` do, and how
> is it different from `SingleValueMapper`? Answer for someone new to Rust."

**Review for a specific risk**
> "Review `issueCertificate` for access-control and overflow issues on Klever
> VM. Show only real problems and the exact line to change."

**Debug a build error**
> "`ksc all build` fails with `<paste error>`. Given my `Cargo.toml` uses
> klever-sc 0.43, what is the most likely cause and fix?"

---

## Working effectively with AI

1. **Give context** — paste the relevant file, the exact command, and the exact
   error. Vague questions get vague answers.
2. **Ask for the smallest change** — "show only the lines to edit."
3. **Always verify** — re-run `./scripts/test.sh` and `./scripts/build.sh`.
   Treat AI output as a draft, not a guarantee.
4. **Cross-check against the docs** — https://docs.klever.org is the source of
   truth for syntax and tooling.

---

Next: [`06-class-challenges.md`](06-class-challenges.md)
