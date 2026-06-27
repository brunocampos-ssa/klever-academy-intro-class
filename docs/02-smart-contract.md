# 02 — The Smart Contract

[Português do Brasil](./02-smart-contract-pt-BR.md)

A beginner-friendly walkthrough of the Certificate Registry contract
(`contracts/certificate-registry/src/lib.rs`).

---

## Purpose

Store academic certificates **on-chain** so anyone can verify them without
trusting a central server. An **issuer** (e.g. Klever Academy) creates
certificates for students; **anyone** can read and validate them.

---

## Annotations: the macros that define behavior

In `klever-sc`, you don't call a special function to "register an endpoint." You
**annotate** a method, and the framework macros turn it into the right kind of
contract member. These attributes are the decoder ring for the whole contract —
every example below is taken directly from `src/lib.rs`.

| Annotation | Category | What it marks | In this contract |
| --- | --- | --- | --- |
| `#[klever_sc::contract]` | Contract | the trait whose contents become the deployed contract | `trait CertificateRegistry` |
| `#[init]` | Lifecycle | the constructor — runs **once** at deploy | `init()` |
| `#[upgrade]` | Lifecycle | runs on contract upgrade (keep state intact) | `upgrade()` |
| `#[endpoint(name)]` | **Write** | a public state-changing function (a signed transaction) | `issueCertificate`, `revokeCertificate`, `setIssuer` |
| `#[view(name)]` | **Read** | a public read-only query (free, no wallet) | `getCertificate`, `isValid`, `getTotalCertificates`, `getIssuer` |
| `#[storage_mapper("key")]` | **Storage** | a persistent state accessor stored under `"key"` | `issuer`, `lastId`, `certificates` |
| `#[only_owner]` | Access control | restricts a call to the contract owner/deployer | `setIssuer` |
| `#[event("name")]` | Events | a structured on-chain log | `certificateIssued`, `certificateRevoked` |
| `#[indexed]` | Events | marks an event parameter as a **searchable topic** | `id`, `student` on the events |
| `#[type_abi]` + `#[derive(...)]` | Types | make a custom struct storable + ABI-visible (see *Encoding & ABI* below) | the `Certificate` struct |
| *(no annotation)* | Private helper | a plain trait method — internal, **not** in the ABI | `require_caller_is_issuer`, `get_certificate_or_panic` |

**Web mental model:** `#[endpoint]` ≈ a `POST` (changes state, costs a fee),
`#[view]` ≈ a `GET` (free read), `#[storage_mapper]` ≈ a database table that
lives on-chain.

> Note the **two names**: `#[endpoint(issueCertificate)]` is written above the
> Rust function `fn issue_certificate(...)`. The annotation argument
> (`issueCertificate`, camelCase) is the **public ABI name** that scripts and the
> frontend call; the Rust function keeps idiomatic snake_case. The same applies to
> `#[view(name)]`, `#[storage_mapper("key")]`, and `#[event("name")]`.

> Beginner focus: an endpoint is a write, a view is a read — that's the whole map.
> Intermediate focus: a `storage_mapper`'s `"key"` is the literal on-chain storage key; its return type (`SingleValueMapper`, `MapMapper`) decides the data shape.
> Advanced focus: methods with no annotation are private helpers excluded from the ABI — use them to keep access-control logic in one place.

---

## Data model

Each certificate is a struct:

```rust
struct Certificate {
    id: u64,                      // sequential ID assigned by the contract
    student: ManagedAddress,      // who it belongs to
    course: ManagedBuffer,        // course / class name
    metadata_uri: ManagedBuffer,  // hash or URI to off-chain details
    issued_at: u64,               // block timestamp
    revoked: bool,                // revocation flag
}
```

---

## Encoding & ABI (the attributes above the struct)

In `src/lib.rs` the struct is preceded by two attributes:

```rust
#[type_abi]
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, Clone, PartialEq, Debug)]
pub struct Certificate<M: ManagedTypeApi> { /* ... */ }
```

A blockchain only stores **bytes**, so the struct needs machine-generated code to
turn itself into bytes (and back), plus a description so off-chain tools
understand it. That is exactly what these two lines provide — you write one line,
the compiler writes the boilerplate.

**`#[type_abi]`** exports the struct's *shape* (field names + types) into the
contract **ABI** (the JSON under `abi/`). Because of it, Klever Connect and the
scripts know a `Certificate` has an `id: u64`, a `student` address, and so on, so
they can decode what the contract returns automatically.

**`#[derive(...)]`** auto-implements a set of capabilities:

| Derived trait | What it gives the struct | Why it's needed |
| --- | --- | --- |
| `TopEncode` / `TopDecode` | encode/decode the **whole** value as bytes | how a `Certificate` is stored and returned standalone |
| `NestedEncode` / `NestedDecode` | encode/decode when the value sits **inside** something else (a field, a list element) | the codec picks "nested" when a `Certificate` is embedded in a bigger structure |
| `Clone` | make an in-memory copy | so contract logic can duplicate the value |
| `PartialEq` | compare two with `==` | handy in logic and especially in tests |
| `Debug` | print with `{:?}` | readable output when testing/debugging |

> Why two encode pairs? Encoding a value *on its own* (top-level) differs from
> encoding it *embedded* in a larger blob (nested, where length metadata
> matters). You derive both so the framework can always pick the correct one.

A useful mental model: `#[derive(...)]` is like `JSON.stringify` / `JSON.parse`
for the blockchain, generated automatically — and `#[type_abi]` is like exporting
the TypeScript type so the frontend knows the shape.

> Beginner focus: "these attributes let the struct be stored on-chain and read by our app."
> Intermediate focus: note the top-vs-nested split and that the ABI bridges Rust ↔ TypeScript.
> Advanced focus: these are derive macros expanding at compile time; know the wire format (nested encoding adds length metadata) when optimizing storage.

---

## The typed proxy (calling the contract from Rust)

The same ABI that describes the contract is also used to **generate a typed
proxy** — `src/certificate_registry_proxy.rs`. A proxy is a small Rust struct
whose methods mirror the contract's endpoints and views one-to-one
(`issue_certificate`, `is_valid`, …), with the correct argument and return types
baked in.

**Why it exists:** without it, calling the contract means sending a raw function
name plus hand-encoded byte arguments — easy to get wrong and invisible to the
compiler. With the proxy, a call like
`tx().typed(CertificateRegistryProxy).is_valid(1u64)` is checked at compile time:
wrong argument types or a misspelled endpoint simply won't build. It's the same
idea as a generated API client from an OpenAPI spec — the interface description
produces a type-safe client.

In this repo the **tests** use the proxy to talk to the contract. Because it is
derived from the interface, it must be **regenerated whenever you change the
endpoints**; the how-to lives in
[`03-build-test-deploy.md`](03-build-test-deploy.md).

> Beginner focus: the proxy is a type-safe "remote control" for the contract.
> Intermediate focus: it's generated from the ABI — change the interface, regenerate the proxy.
> Advanced focus: the same proxy works in tests, scripts, and real clients; it's how Rust callers stay in sync with the deployed ABI.

---

## Storage

The contract keeps three pieces of persistent state:

| Mapper | Type | Meaning |
| --- | --- | --- |
| `issuer` | `SingleValueMapper<ManagedAddress>` | who may issue/revoke |
| `lastId` | `SingleValueMapper<u64>` | auto-increment counter |
| `certificates` | `MapMapper<u64, Certificate>` | the registry itself |

> Think of `MapMapper` like a key→value table that lives on the blockchain.

---

## Endpoints (writes) and views (reads)

| Name | Kind | Access | Purpose |
| --- | --- | --- | --- |
| `init` | constructor | deployer | runs once; sets issuer = deployer |
| `issueCertificate` | endpoint | issuer | create a certificate, returns its ID |
| `revokeCertificate` | endpoint | issuer | flip `revoked = true` |
| `setIssuer` | endpoint | owner | hand the issuer role to another address |
| `getCertificate` | view | anyone | read the full struct by ID |
| `isValid` | view | anyone | `true` if it exists and is not revoked |
| `getTotalCertificates` | view | anyone | how many were issued |
| `getIssuer` | view | anyone | current issuer address |

**Endpoints** change state and require a signed transaction (and fees).
**Views** are free reads — no wallet needed.

---

## Events

The contract emits events so off-chain apps/indexers can react:

```rust
#[event("certificateIssued")]
fn certificate_issued_event(&self, #[indexed] id: u64, #[indexed] student: &ManagedAddress);

#[event("certificateRevoked")]
fn certificate_revoked_event(&self, #[indexed] id: u64);
```

`#[indexed]` fields become searchable topics — e.g. "show me all certificates
for student X".

---

## Access control

Two guards keep things safe:

- `require_caller_is_issuer()` — used by `issueCertificate` / `revokeCertificate`.
- `#[only_owner]` on `setIssuer` — only the deployer/owner can transfer the role.

`require!(condition, "message")` aborts the whole transaction with a readable
error if the condition is false. Nothing is half-written.

---

## Beginner-friendly walkthrough

Read `src/lib.rs` top to bottom. It is organized into six labelled sections:

1. **Initialization** — `init` / `upgrade`.
2. **Write endpoints** — issue, revoke, set issuer.
3. **Read views** — get, validate, count.
4. **Storage** — the mappers above.
5. **Events** — issued / revoked.
6. **Private helpers** — the access-control checks.

Follow the lifecycle of one certificate:

```txt
issuer calls issueCertificate(student, course, uri)
        │
        ▼
require caller == issuer   ──fail──▶ transaction reverts
        │ ok
        ▼
id = lastId + 1
store Certificate{...}
lastId = id
emit certificateIssued(id, student)
        │
        ▼
anyone calls isValid(id) ──▶ true   (until revoked)
```

---

Next: [`03-build-test-deploy.md`](03-build-test-deploy.md)
