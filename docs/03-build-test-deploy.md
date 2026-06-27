# 03 — Build, Test & Deploy

[Português do Brasil](./03-build-test-deploy-pt-BR.md)

How to take the contract from source to a live address on Klever.

> Adjust the network, wallet, and contract path according to your environment.

---

## Build

```bash
./scripts/build.sh
```

Under the hood this runs the **correct** Klever build command:

```bash
~/klever-sdk/ksc all build
```

Output lands in `contracts/certificate-registry/output/`:

- `certificate-registry.wasm` — the deployable bytecode
- `certificate-registry.abi.json` — the ABI (used by the frontend/scripts)

> ❌ Do not use `sc-meta all build`, `cargo build`, or `mxpy` — those belong to
> other ecosystems. Klever builds with `ksc`.

### Build requirements & the wasm-link note

Two things the build needs, and one rough edge worth knowing:

1. **`ksc` discovers the contract via a `klever.json` marker** in the contract
   folder (`contracts/certificate-registry/klever.json`). Without it, `ksc all
   build` prints *"Found 0 contract crates"* and silently does nothing — the
   marker is what makes the folder a buildable contract.
2. **A Rust wasm target must be installed** — set up once in
   [`01-setup.md`](01-setup.md) (section 3, "Add the WebAssembly build target").
3. **On Rust 1.82+**, `ksc`'s own wasm link can fail with
   `undefined symbol: mBufferNew` (Rust stopped auto-importing undefined wasm
   symbols, and the installed `ksc` doesn't pass `--import-undefined`).
   `build.sh` **detects this and automatically relinks** the generated `wasm/`
   crate with the right flag — kept in
   `contracts/certificate-registry/.cargo/config.toml` — so you still get a
   deployable `output/certificate-registry.wasm`. The clean long-term fix is to
   update the Klever SDK from https://install.klever.org once a release handles
   this natively.

> `build.sh` never reports a false success: if no `.wasm` is produced (even via
> the fallback), it exits with an error instead of printing "Build complete".

---

## Test

```bash
./scripts/test.sh      # runs cargo test
```

Tests run in a **simulated blockchain** (`klever-sc-scenario`) — no network, no
fees, and **no build step**. The test harness registers the Rust contract object
and runs it in-process, so you do *not* need `./scripts/build.sh` first. The
included tests cover deploy, issuing, and access control. Add more as you extend
the contract (see the challenges doc).

### The typed proxy (and how to regenerate it)

The tests call the contract through a **typed proxy** —
`src/certificate_registry_proxy.rs`, exposed as the `certificate_registry_proxy`
module. It's generated from the contract's ABI and gives type-safe methods like
`.issue_certificate(...)` and `.is_valid(id)` instead of raw, stringly-typed
calls. It is committed to the repo so `cargo test` works out of the box.

**If you change the contract's public interface** (add/rename an endpoint, change
an argument type), the proxy goes stale and the tests stop compiling. Regenerate
it:

```bash
# From the contract's meta crate:
cd contracts/certificate-registry/meta
cargo run -- proxy                 # writes ../output/proxy.rs
cp ../output/proxy.rs ../src/certificate_registry_proxy.rs   # refresh the committed copy
```

> A stale proxy shows up as "cannot find method ..." or a type error in the tests
> right after you edit endpoints — that's your cue to regenerate it. The same ABI
> also drives the frontend, so rebuild (`./scripts/build.sh`) to refresh
> `abi/` when you change the interface.

---

## Deploy

1. Make sure your testnet wallet has KLV (see `docs/01-setup.md` faucet step).
2. Configure `.env` (copy from `.env.example`) with `KEY_FILE`, `KLEVER_NODE`.
3. Deploy:

```bash
./scripts/deploy.sh
```

Under the hood:

```bash
# Adjust the network, KEY_FILE, and paths according to your environment.
KLEVER_NODE=https://node.testnet.klever.org \
  ~/klever-sdk/koperator \
  --key-file="$KEY_FILE" \
  sc create \
  --wasm="contracts/certificate-registry/output/certificate-registry.wasm" \
  --upgradeable --readable --payable \
  --await --sign --result-only
```

The result JSON includes the new **contract address** (`klv1...`). Copy it.

---

## After deploy: wire it up

Put the address everywhere the tools expect it:

```bash
# .env (for scripts)
CONTRACT_ADDRESS=klv1your_contract_address...
```

```ts
// app/web/src/klever.ts (for the frontend)
export const CONTRACT_ADDRESS = "klv1your_contract_address...";
```

---

## Verify the deployment

Query a free view — if the contract answers, it's live:

```bash
CONTRACT_ADDRESS=klv1... ./scripts/query-certificate.sh 1
```

Or check it on the explorer:

- Testnet: `https://testnet.kleverscan.org/account/<contract_address>`

---

## Common issues

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `ksc: not found` | SDK not installed / wrong path | re-run installer; set `KLEVER_SDK_PATH` |
| Build fails on `klever-sc` version | version mismatch | align versions in `Cargo.toml` with `ksc --version` |
| Deploy: "insufficient balance" | no testnet KLV | use the faucet (docs/01) |
| Deploy: "signature/key" error | wrong `KEY_FILE` | point `KEY_FILE` at your PEM |
| Query returns empty | wrong ID or contract address | confirm `CONTRACT_ADDRESS` and that the cert exists |
| Frontend can't read ABI | path moved | check the ABI import in `klever.ts` |

---

Next: [`04-klever-connect.md`](04-klever-connect.md)
