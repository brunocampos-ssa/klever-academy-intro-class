# Certificate Registry — Smart Contract

[Português do Brasil](./README-pt-BR.md)

A minimal, classroom-friendly Klever VM smart contract that stores academic
certificates on-chain. Part of the **`klever-academy-intro-class`** repository.

## What it does

| Action | Who | Endpoint |
| --- | --- | --- |
| Issue a certificate | Issuer only | `issueCertificate(student, course, metadata_uri)` |
| Revoke a certificate | Issuer only | `revokeCertificate(id)` |
| Change the issuer | Owner only | `setIssuer(new_issuer)` |
| Read a certificate | Anyone | `getCertificate(id)` (view) |
| Validate a certificate | Anyone | `isValid(id)` (view) |
| Count certificates | Anyone | `getTotalCertificates()` (view) |
| Read the issuer | Anyone | `getIssuer()` (view) |

## Data model

Each certificate is a `Certificate` struct:

```rust
struct Certificate {
    id: u64,                 // sequential, assigned by the contract
    student: ManagedAddress, // who the certificate belongs to
    course: ManagedBuffer,   // course / class name
    metadata_uri: ManagedBuffer, // hash or URI to off-chain details
    issued_at: u64,          // block timestamp
    revoked: bool,           // revocation flag (history is preserved)
}
```

Storage:

- `issuer` → `SingleValueMapper<ManagedAddress>`
- `lastId` → `SingleValueMapper<u64>` (auto-increment counter)
- `certificates` → `MapMapper<u64, Certificate>`

## Files

```txt
certificate-registry/
├── Cargo.toml          # contract crate manifest
├── src/lib.rs          # the contract (read this first, top to bottom)
├── tests/              # cargo tests using klever-sc-scenario
├── meta/               # build/ABI tooling (rarely edited)
├── abi/                # reference ABI used by the frontend + scripts
└── README.md           # this file
```

## Build & test

From the repository root:

```bash
./scripts/build.sh   # ~/klever-sdk/ksc all build  -> output/*.wasm + ABI
./scripts/test.sh    # cargo test
```

> Adjust the `klever-sc` version in `Cargo.toml` to match your installed
> toolchain (`~/klever-sdk/ksc --version`). See `docs/03-build-test-deploy.md`.

For the full walkthrough, see [`docs/02-smart-contract.md`](../../docs/02-smart-contract.md).
