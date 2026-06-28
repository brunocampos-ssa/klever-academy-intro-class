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
| Rust **wasm target** | compile the contract to WebAssembly (Klever VM is wasm-based) | `rustup` |
| Node.js 20.19+ / 22.12+ | run the frontend and `interact.ts` | https://nodejs.org |
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

## 3. Add the WebAssembly build target

**Klever VM runs WebAssembly**, so the contract compiles to a `.wasm`. You
cannot build a Klever smart contract without a Rust **wasm target** installed.

```bash
# Rust 1.85+ (what `ksc` uses by default):
rustup target add wasm32v1-none

# Older Rust (< 1.85):
rustup target add wasm32-unknown-unknown
```

> Not sure which? Installing **both** is harmless — `./scripts/build.sh` picks
> whichever your toolchain uses. If you skip this, the build fails with
> `error[E0463]: can't find crate for 'core'` (the wasm target is missing).

---

## 4. Check your environment

```bash
# Klever tools
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version

# Rust
rustc --version
cargo --version

# Rust wasm target (at least one of these must be listed)
rustup target list --installed | grep wasm32

# Node.js (needs 20.19+ or 22.12+)
node --version
npm --version

# Helpers used by scripts
jq --version
curl --version
```

If any command is "not found" (or the wasm target line is empty), install that
tool/target before continuing.

---

## 5. Node.js requirement for the frontend

The web app uses Vite + React and needs **Node.js 20.19+ (or 22.12+)**.

```bash
cd app/web
npm install
npm run dev   # starts the dev server (don't worry if the contract isn't deployed yet)
```

---

## 6. Wallet & network preparation

For class we use **testnet** (free, safe, disposable). There are **two places**
that sign transactions, and they use **different** credentials:

| Where | Signs with | Used by |
| --- | --- | --- |
| The web app (`app/web`) | the **Klever Web Extension** | the frontend (BrowserWallet) |
| The CLI scripts (deploy/issue) | a **PEM key file** (`koperator`) | `./scripts/deploy.sh`, etc. |

### 6.1 Browser extension (for the web app)

1. Install and unlock the **Klever Web Extension**.
2. Create a fresh wallet (do NOT reuse a wallet that holds real funds).
3. Switch the extension network to **Testnet**.

### 6.2 CLI wallet key file (PEM) — for `koperator`

The CLI scripts deploy and invoke via `koperator`, which signs with a **PEM key
file**. The `KEY_FILE` setting in `.env` points to it. You have two options:

**Option A — generate a fresh CLI wallet (simplest, recommended for class):**

```bash
# Creates a new wallet and writes the PEM (with 0600 permissions).
# It prints the new klv1... address.
~/klever-sdk/koperator account create --key-file=./walletKey.pem
```

**Option B — reuse your extension account (import its private key):**

Use this if you want the CLI to sign as the **same account** as your browser
extension. In the Klever Web Extension, reveal/export that account's **hex
private key** (account settings → export private key), then:

```bash
# <HEX_PRIVATE_KEY> is the 64-char hex secret key exported from the extension.
~/klever-sdk/koperator account import-sk <HEX_PRIVATE_KEY> --path ./walletKey.pem
```

> If the extension only gives you a **mnemonic/seed phrase** (not a hex key),
> just use Option A — for class you don't need the CLI to share the extension's
> account.

Point the scripts at the PEM in `.env` (see `.env.example`):

```bash
KEY_FILE=./walletKey.pem        # or an absolute path like $HOME/klever-sdk/walletKey.pem
```

Check the address of a PEM at any time:

```bash
~/klever-sdk/koperator account address --key-file=./walletKey.pem
```

### 6.3 Fund the CLI wallet from the testnet faucet

Deploys cost a small fee, so the **PEM wallet's** address needs test KLV:

```bash
# Grab the address from your PEM, then ask the faucet to fund it.
ADDR=$(~/klever-sdk/koperator account address --key-file=./walletKey.pem | grep -oE 'klv1[0-9a-z]+' | tail -1)
curl -X POST \
  "https://api.testnet.klever.org/v1.0/transaction/send-user-funds/$ADDR" \
  -H "Content-Type: application/json"
```

> ⚠️ **Security.** `import-sk` takes the key as a command-line argument, so it
> lands in your shell history and process list. Use a **dedicated testnet
> wallet**, never one with real funds, and clear that history line afterward
> (e.g. `history -d <n>`).
>
> ⚠️ Never commit a key file or a mnemonic. The `.gitignore` already excludes
> `*.pem`, but stay careful.

---

## 7. Editor setup (VS Code + rust-analyzer)

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
