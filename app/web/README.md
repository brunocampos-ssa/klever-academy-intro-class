# Certificate Registry — Web App

[Português do Brasil](./README-pt-BR.md)

A small React + TypeScript frontend that connects to Klever Blockchain with
**Klever Connect** and talks to the Certificate Registry contract.

Part of the **`klever-academy-intro-class`** repository.

## What it demonstrates

1. **Connect a wallet** with the Klever Web Extension (`BrowserWallet`).
2. **Show the connected account** address.
3. **Issue a certificate** (a signed transaction).
4. **Query a certificate** by ID (a free read).
5. **Show certificate status** (valid / revoked / not found).

## Where configuration happens

➡️ **Everything you need to wire up lives in [`src/klever.ts`](src/klever.ts):**

| Setting | What to change |
| --- | --- |
| `NETWORK` | `mainnet` / `testnet` / `devnet` (use `testnet` for class) |
| `CONTRACT_ADDRESS` | the `klv1...` address from `./scripts/deploy.sh` |
| `ABI` | imported from `contracts/certificate-registry/abi/...` |

## Run locally

```bash
cd app/web
npm install
npm run dev
```

Then open the printed URL and make sure the **Klever Web Extension** is
installed and unlocked.

> Beginner focus: change labels and try the connect button.
> Intermediate focus: improve loading/error state handling.
> Advanced focus: subscribe to contract events and auto-refresh the viewer.

## Notes

- This app is intentionally minimal and **not production-ready** — no styling
  framework, no router, no test suite. It is built for teaching clarity.
- The private key never enters this app: signing happens inside the extension.
- See [`docs/04-klever-connect.md`](../../docs/04-klever-connect.md) for the
  full Klever Connect walkthrough.
