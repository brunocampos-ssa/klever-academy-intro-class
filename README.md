# Klever Academy Intro Class: Build, Deploy and Connect Your First Smart Contract

_Learn Web3 by shipping: build, test, deploy, and connect a real smart contract on Klever Blockchain._

[Português do Brasil](./README-pt-BR.md)

> A class-ready repository that takes you from zero to a deployed, connected
> smart contract on **Klever Blockchain**.
>
> **This README is written as the class slide deck.**
> Present it top to bottom. Each `---` is a slide break.

```txt
What you'll do today:
  build  ─▶  test  ─▶  deploy  ─▶  connect  ─▶  verify
  (Rust)    (cargo)   (koperator) (Klever Connect)  (on-chain)
```

---

## Welcome

Welcome to the **Klever Academy Intro Class**.

By the end of this session you will have:

- Understood Klever Blockchain from a developer's point of view.
- Built and tested a real smart contract (a **Certificate Registry**).
- Deployed it to Klever testnet.
- Connected a web app to it with **Klever Connect**.

> Beginner focus: follow the flow and run the commands.
> Intermediate focus: read the architecture and modify it.
> Advanced focus: find the extension points and harden them.

---

## What we are building

A **Certificate Registry**: an on-chain registry where an issuer (Klever
Academy) creates verifiable certificates for students.

```txt
        Issuer (Klever Academy)
                │ issueCertificate(student, course, uri)
                ▼
        ┌───────────────────────────┐
        │   Certificate Registry     │   <- smart contract on Klever VM
        │   id → {student, course,   │
        │         uri, issued_at,    │
        │         revoked}           │
        └───────────────────────────┘
                ▲                 ▲
   getCertificate(id)        isValid(id)
                │                 │
            Web app  ◀── Klever Connect ──▶  Anyone verifying
```

---

## Why Klever Blockchain?

From a developer's perspective, Klever gives you:

- **Klever VM** — run WebAssembly smart contracts written in Rust.
- **First-class tooling** — `ksc` (build) and `koperator` (deploy/invoke) from
  `install.klever.org`.
- **Klever Connect** — a TypeScript SDK to wire apps to the chain.
- **A Klever-aware AI** — `ai.klever.org` / Klever MCP that knows the real
  commands and docs.
- **Clear docs** — `docs.klever.org` as the single source of truth.

---

## Class overview

| | |
| --- | --- |
| **Format** | hands-on, ~60–90 min |
| **Theme** | on-chain Certificate Registry |
| **You leave with** | a deployed contract + a connected web app |
| **Repo** | `klever-academy-intro-class` |

The loop we'll repeat: **build → test → deploy → connect → verify.**

---

## Target audience

This class is designed for **all levels**:

- **Beginners** — new to blockchain and/or Rust. You follow the flow.
- **Intermediate** — comfortable coding; you'll modify the contract and scripts.
- **Advanced** — you'll spot the extension points and improve architecture,
  security, and tests.

---

## What students will build

1. A Rust smart contract for Klever VM (`contracts/certificate-registry`).
2. A test suite that runs in a simulated chain.
3. A deployment on Klever testnet.
4. A React + TypeScript app (`app/web`) using **Klever Connect**.
5. CLI scripts to build, deploy, issue, and query (`scripts/`).

---

## Prerequisites

- A laptop with a terminal (Linux/macOS/WSL).
- **Rust + Cargo**, **Node.js 18+**, `jq`, `curl`.
- The **Klever SDK** from `install.klever.org` (`ksc`, `koperator`).
- The **Klever Web Extension** (browser) with a testnet wallet + faucet KLV.

➡️ Full steps in [`docs/01-setup.md`](docs/01-setup.md).

---

## Klever Blockchain developer overview

Mental model for app developers:

```txt
Your app ──(reads/queries)──▶  Klever node API   ──▶ chain state
Your app ──(writes/txs)─────▶  sign with wallet  ──▶ broadcast ──▶ block
Smart contract ── lives on ──▶ Klever VM (WASM)
```

- **Reads** (views) are free and need no wallet.
- **Writes** (endpoints) require a signed transaction and a small fee.
- **Networks**: mainnet (real), testnet (free practice), local (your machine).

---

## Klever VM and smart contracts

- Contracts are **Rust**, compiled to **WebAssembly** for **Klever VM**.
- The `klever-sc` framework gives you annotations:
  - `#[init]` — constructor, runs once at deploy.
  - `#[endpoint]` — a state-changing function (a write).
  - `#[view]` — a read-only function (a free query).
  - `#[storage_mapper(...)]` — persistent state.
  - `#[event(...)]` — structured logs.

```rust
#[endpoint(issueCertificate)]
fn issue_certificate(&self, student: ManagedAddress, course: ManagedBuffer, metadata_uri: ManagedBuffer) -> u64 {
    self.require_caller_is_issuer();
    // ... store the certificate, bump the counter, emit an event
}
```

➡️ Full walkthrough in [`docs/02-smart-contract.md`](docs/02-smart-contract.md).

---

## Tooling overview

| Tool | Role | From |
| --- | --- | --- |
| `ksc` | build contract → wasm + ABI | `install.klever.org` |
| `koperator` | deploy + invoke contracts | `install.klever.org` |
| `@klever/connect` | connect apps to the chain | npm |
| `ai.klever.org` / Klever MCP | AI dev assistant | `ai.klever.org` |
| `docs.klever.org` | the reference | web |

> Important: Klever uses `ksc all build` and `koperator sc create/invoke` —
> **not** `sc-meta`, `mxpy`, `hardhat`, or `foundry`. A Klever-aware AI helps you
> avoid copying the wrong chain's commands.

---

## Installing Klever developer tools

```bash
# Install the Klever SDK (review the script at install.klever.org first).
curl -sSf https://install.klever.org | bash

# Verify
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version
```

This installs `ksc` and `koperator` under `~/klever-sdk/`.

➡️ Details + troubleshooting in [`docs/01-setup.md`](docs/01-setup.md).

---

## Using AI with `ai.klever.org`

Use a **Klever-aware** assistant to move faster:

- **Explain** the contract → [`prompts/ai-explain-contract.md`](prompts/ai-explain-contract.md)
- **Review** the contract → [`prompts/ai-review-contract.md`](prompts/ai-review-contract.md)
- **Debug** an error → [`prompts/ai-debug-contract.md`](prompts/ai-debug-contract.md)
- **Generate tests** and **improve docs**.

➡️ How-to in [`docs/05-ai-assisted-development.md`](docs/05-ai-assisted-development.md).

---

## Project architecture

```txt
klever-academy-intro-class/
├── contracts/certificate-registry/   # Rust smart contract (Klever VM)
│   ├── src/lib.rs                     #   the contract
│   ├── tests/                         #   cargo tests (simulated chain)
│   ├── abi/                           #   reference ABI (frontend/scripts use it)
│   └── meta/                          #   build tooling
├── app/web/                          # React + TS frontend (Klever Connect)
│   └── src/klever.ts                  #   ← all chain config lives here
├── scripts/                          # build / deploy / issue / query / interact
├── docs/                             # step-by-step class docs
└── prompts/                          # ready-to-use AI prompts
```

> Beginner focus: you mostly touch `app/web` and run `scripts/`.
> Intermediate focus: you edit `contracts/.../lib.rs` and `scripts/`.
> Advanced focus: you reshape storage, add roles, and expand `tests/`.

---

## Smart contract walkthrough

The contract has six labelled sections in `src/lib.rs`:

1. **Init** — deployer becomes issuer.
2. **Write endpoints** — `issueCertificate`, `revokeCertificate`, `setIssuer`.
3. **Views** — `getCertificate`, `isValid`, `getTotalCertificates`, `getIssuer`.
4. **Storage** — `issuer`, `lastId`, `certificates`.
5. **Events** — `certificateIssued`, `certificateRevoked`.
6. **Helpers** — issuer check, fetch-or-panic.

Lifecycle of one certificate:

```txt
issueCertificate ─▶ require issuer ─▶ store + lastId++ ─▶ emit event
                                                            │
anyone ─▶ isValid(id) ─▶ true (until revoked)  ◀───────────┘
```

➡️ Read it line-by-line in [`docs/02-smart-contract.md`](docs/02-smart-contract.md).

---

## Build process

```bash
./scripts/build.sh        # runs: ~/klever-sdk/ksc all build
```

Produces `contracts/certificate-registry/output/`:
- `certificate-registry.wasm` (deployable)
- `certificate-registry.abi.json` (for the frontend/scripts)

---

## Test process

```bash
./scripts/test.sh         # runs: cargo test
```

Tests run in a **simulated blockchain** — no network, no fees. They cover
deploy, issuing, and access control. Extend them in the challenges.

> Beginner focus: just run it and read the green output.
> Advanced focus: add revoke/expiration/role tests.

---

## Deploy process

```bash
# 1) Fund your testnet wallet (faucet) — see docs/01
# 2) Configure .env (KEY_FILE, KLEVER_NODE)
./scripts/deploy.sh       # runs: koperator sc create ... --await --sign
```

Copy the printed `klv1...` contract address into:
- `.env` → `CONTRACT_ADDRESS`
- `app/web/src/klever.ts` → `CONTRACT_ADDRESS`

➡️ Details in [`docs/03-build-test-deploy.md`](docs/03-build-test-deploy.md).

---

## Interacting with the contract

**From the CLI:**

```bash
# Issue (write) — only the issuer wallet succeeds
./scripts/issue-certificate.sh klv1student... "Klever Academy Intro Class" "ipfs://cid"

# Query (read) — free, no wallet
./scripts/query-certificate.sh 1
```

**From Node.js (Klever Connect):**

```bash
PRIVATE_KEY=... CONTRACT_ADDRESS=klv1... npx tsx scripts/interact.ts
```

---

## Connecting with Klever Connect

The web app wires everything through one file: `app/web/src/klever.ts`.

```ts
const provider = new KleverProvider({ network: "testnet" });
const wallet   = new BrowserWallet(provider);   // Klever Web Extension
await wallet.connect();

const contract = new Contract(CONTRACT_ADDRESS, ABI, wallet);
await contract.invoke("issueCertificate", student, course, uri); // write
const valid = await contract.call("isValid", id);                // read
```

Run it:

```bash
cd app/web && npm install && npm run dev
```

➡️ Full guide in [`docs/04-klever-connect.md`](docs/04-klever-connect.md).

---

## Suggested live demo flow

1. `./scripts/build.sh` — show the wasm appear.
2. `./scripts/test.sh` — show green tests.
3. `./scripts/deploy.sh` — copy the contract address.
4. Paste the address into `app/web/src/klever.ts`.
5. `cd app/web && npm run dev` — connect the wallet.
6. Issue a certificate in the UI; sign in the extension.
7. Query the ID; show **VALID ✅**.
8. (Optional) `revokeCertificate`, re-query, show **INVALID ❌**.

---

## Challenges for beginner, intermediate, and advanced developers

- 🟢 **Beginner** — connect wallet, change app labels, query a certificate.
- 🟡 **Intermediate** — add expiration, stronger validation, better UI state.
- 🔴 **Advanced** — issuer roles, batch issuance, per-student index, more tests.

➡️ Full briefs in [`docs/06-class-challenges.md`](docs/06-class-challenges.md).

---

## References and next steps

- **Docs:** https://docs.klever.org
- **Install tools:** https://install.klever.org
- **AI assistant:** https://ai.klever.org
- This repo: `docs/`, `prompts/`, `scripts/`, `contracts/`, `app/web/`.

Next steps:
1. Finish a challenge from `docs/06`.
2. Deploy your own variant to testnet.
3. Share what you built with the Klever Academy community.

---

## License

MIT — see [`LICENSE`](LICENSE).
