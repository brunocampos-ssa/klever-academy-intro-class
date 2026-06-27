# 01 — Setup

[Português do Brasil](./01-setup-pt-BR.md)

Everything you need installed before the class. Budget ~15 minutes.

> Beginner focus: just follow the steps in order.
> Intermediate focus: confirm versions and understand what each tool does.
> Advanced focus: script this into your dotfiles / a devcontainer.

---

## 1. Required tools

| Tool | Why | Source |
| --- | --- | --- |
| Klever SDK (`ksc`, `koperator`) | build, deploy, and call contracts | https://install.klever.org |
| Rust + Cargo | the contract is written in Rust | https://rustup.rs |
| Node.js 18+ | run the frontend and `interact.ts` | https://nodejs.org |
| `jq`, `curl` | used by the shell scripts | your package manager |
| Klever Web Extension | sign transactions in the browser | Chrome/Brave store |

---

## 2. Install the Klever developer tools

The one-line installer from **https://install.klever.org** sets up the Klever
SDK under `~/klever-sdk/` (this is where `ksc` and `koperator` live).

```bash
# Review the script first if you like, then run the installer.
# See https://install.klever.org for the current, official command.
curl -sSf https://install.klever.org | bash
```

After it finishes, the key binaries are:

```txt
~/klever-sdk/ksc         # Klever Smart Contract compiler (build, ABI)
~/klever-sdk/koperator   # CLI to deploy and invoke contracts
```

> If the installer puts the SDK somewhere else, set `KLEVER_SDK_PATH` in your
> `.env` so the scripts can find it.

---

## 3. Check your environment

```bash
# Klever tools
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version

# Rust
rustc --version
cargo --version

# Node.js (needs 18+)
node --version
npm --version

# Helpers used by scripts
jq --version
curl --version
```

If any command is "not found", install that tool before continuing.

---

## 4. Node.js requirement for the frontend

The web app uses Vite + React and needs **Node.js 18 or newer**.

```bash
cd app/web
npm install
npm run dev   # starts the dev server (don't worry if the contract isn't deployed yet)
```

---

## 5. Wallet & network preparation

For class we use **testnet** (free, safe, disposable).

1. Install and unlock the **Klever Web Extension**.
2. Create a fresh wallet (do NOT reuse a wallet that holds real funds).
3. Switch the extension network to **Testnet**.
4. Get free test KLV from the testnet faucet so you can pay deploy fees:

```bash
# Replace <your_address> with your klv1... address
curl -X POST \
  "https://api.testnet.klever.org/v1.0/transaction/send-user-funds/<your_address>" \
  -H "Content-Type: application/json"
```

5. For the CLI scripts, export your wallet key file as a PEM and point the
   scripts at it via `KEY_FILE` in `.env` (see `.env.example`).

> ⚠️ Never commit a key file or a mnemonic. The `.gitignore` already excludes
> `*.pem`, but stay careful.

---

## 6. Editor setup (VS Code + rust-analyzer)

The contract is Rust, but you open this repo at its **root** — and the root has
no `Cargo.toml` (it holds the contract, the web app, scripts, and docs). Because
of that, **rust-analyzer may not auto-detect the contract** and will act like
there is no Rust project.

This repo ships a fix in `.vscode/settings.json`: it points rust-analyzer at the
contract crates explicitly via `rust-analyzer.linkedProjects`:

```jsonc
{
  "rust-analyzer.linkedProjects": [
    "./contracts/certificate-registry/Cargo.toml",
    "./contracts/certificate-registry/meta/Cargo.toml"
  ]
}
```

To get it working:

1. Install the **rust-analyzer** extension (VS Code will recommend it — see
   `.vscode/extensions.json`).
2. Open the **repository root** folder in VS Code (not a subfolder).
3. Run **Command Palette → "rust-analyzer: Restart Server"** (or reload the
   window). First load runs `cargo metadata` and indexes the crate — give it a
   minute.

> If it still shows nothing, open **Output → rust-analyzer** and read the log.
> The most common cause is a `klever-sc` version that doesn't match your
> toolchain — align `contracts/certificate-registry/Cargo.toml` with
> `~/klever-sdk/ksc --version` (see [`03-build-test-deploy.md`](03-build-test-deploy.md)).

---

Next: [`02-smart-contract.md`](02-smart-contract.md)
