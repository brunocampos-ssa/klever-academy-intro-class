# 04 — Klever Connect

[Português do Brasil](./04-klever-connect-pt-BR.md)

How your application talks to Klever Blockchain.

---

## What is Klever Connect?

**Klever Connect** (`@klever/connect`) is the official TypeScript/JavaScript SDK
for building on Klever. It handles the things every dApp needs:

- **Provider** — read the chain, send transactions (`KleverProvider`).
- **Wallets** — `BrowserWallet` (extension) and `NodeWallet` (server/scripts).
- **Transactions** — build, sign, broadcast (`TransactionBuilder`, `Transaction`).
- **Contracts** — ethers.js-style `Contract` driven by your ABI.

Install:

```bash
npm install @klever/connect
# or import only the subpackages you need:
npm install @klever/connect-provider @klever/connect-wallet @klever/connect-contracts
```

---

## The core objects

```txt
KleverProvider ──▶ reads the chain (queries, balances, broadcasting)
      │
      ├── BrowserWallet ──▶ signs via the Klever Web Extension (dApps)
      └── NodeWallet    ──▶ signs with a private key (backend / scripts)

Contract(address, abi, signerOrProvider)
      ├── provider only ──▶ free reads (call)
      └── wallet (signer) ──▶ writes (invoke)
```

> Rule of thumb: **provider for reads, wallet for writes.**

---

## Backend / script usage (NodeWallet)

Used in `scripts/interact.ts`. The key comes from an environment variable —
never hardcoded.

```ts
import { KleverProvider } from "@klever/connect-provider";
import { NodeWallet } from "@klever/connect-wallet";
import { Contract } from "@klever/connect-contracts";

const provider = new KleverProvider({ network: "testnet" });
const wallet = new NodeWallet(provider, process.env.PRIVATE_KEY!);
await wallet.connect();

const contract = new Contract(CONTRACT_ADDRESS, ABI, wallet);
await contract.invoke("issueCertificate", student, "Course", "ipfs://cid");
```

> ⚠️ `NodeWallet` is for servers and scripts only. Never ship a private key to a
> browser. In the browser, use `BrowserWallet`.

---

## Frontend usage (BrowserWallet)

Used in `app/web`. The extension holds the key; your code only sees the address
and asks the extension to sign.

```ts
import { KleverProvider } from "@klever/connect-provider";
import { BrowserWallet } from "@klever/connect-wallet";

const provider = new KleverProvider({ network: "testnet" });
const wallet = new BrowserWallet(provider);
await wallet.connect();           // opens the extension prompt
console.log("Connected:", wallet.address);
```

All of this is centralized in [`app/web/src/klever.ts`](../app/web/src/klever.ts).

---

## Wallet connection flow

```txt
User clicks "Connect"
     │
     ▼
BrowserWallet.connect()  ──▶ extension popup ──▶ user approves
     │
     ▼
wallet.address available  ──▶ build a write Contract(address, abi, wallet)
```

---

## Transaction flow (a write)

```txt
contract.invoke("issueCertificate", ...args)
     │  builds the transaction from the ABI
     ▼
wallet signs  (extension popup, or NodeWallet with the key)
     │
     ▼
provider broadcasts  ──▶ node ──▶ included in a block
     │
     ▼
result (tx hash); read back with a view (isValid / getCertificate)
```

For reads, skip signing entirely: `contract.call("isValid", id)`.

---

## Where to configure

| Place | What |
| --- | --- |
| `app/web/src/klever.ts` | network, contract address, ABI (frontend) |
| `.env` | `PRIVATE_KEY`, `CONTRACT_ADDRESS`, `NETWORK` (scripts) |

---

## Run the web app locally

First point the app at your deployed contract. Copy the example env file and set
`VITE_CONTRACT_ADDRESS` to the address printed by `./scripts/deploy.sh`:

```bash
cd app/web
cp .env.example .env
# edit .env: VITE_CONTRACT_ADDRESS=klv1...your contract...
```

Then install and start the dev server:

```bash
npm install
npm run dev
```

Open the printed URL (typically `http://localhost:5173`) in a browser that has the
**Klever Web Extension** installed, unlocked, and set to **Testnet**. In the UI you
can:

1. **Connect** your wallet — the extension popup approves it.
2. **Issue** a certificate — issuer wallet only; a signed transaction.
3. **Verify** a certificate by id — a free read, no signing.

> Requirements: Node.js 20.19+ (or 22.12+) (see [`01-setup.md`](01-setup.md)), the Klever Web
> Extension, and a deployed `CONTRACT_ADDRESS`. The dev server hot-reloads, so edits
> to components show up instantly. The private key never leaves the extension — the
> app only asks it to sign.

---

Next: [`05-ai-assisted-development.md`](05-ai-assisted-development.md)
