# 06 — Class Challenges

[Português do Brasil](./06-class-challenges-pt-BR.md)

Hands-on exercises, grouped by level. Pick the track that fits you — or do all
three. Each challenge lists *what to change* and *where*.

> Use `ai.klever.org` to plan and review your changes (see `docs/05`), but
> always run `./scripts/test.sh` and `./scripts/build.sh` to verify.

---

## 🟢 Beginner

Goal: get comfortable running the project and making safe edits.

1. **Connect a wallet**
   - Run `cd app/web && npm install && npm run dev`.
   - Connect the Klever Web Extension and confirm your address shows up.

2. **Change app labels**
   - In `app/web/src/App.tsx` and the components, change the headings/labels
     (e.g. translate them, or rename "Verify" to "Check certificate").
   - Watch the page hot-reload.

3. **Query an existing certificate**
   - Deploy the contract (or use one provided by the instructor).
   - Set `CONTRACT_ADDRESS` in `app/web/src/klever.ts`.
   - Use the "Verify Certificate" panel to query ID `1`.

✅ Success: you connected a wallet and read a certificate's status.

---

## 🟡 Intermediate

Goal: modify the contract and scripts confidently.

1. **Add certificate expiration**
   - Add an `expires_at: u64` field to `Certificate` in `lib.rs`.
   - Accept a `validity_seconds` argument in `issueCertificate` and compute
     `expires_at = issued_at + validity_seconds`.
   - Update `isValid` to also return `false` once
     `get_block_timestamp() > expires_at`.
   - Update the ABI (`ksc all build` regenerates it) and the frontend display.

2. **Add better validation**
   - Reject empty `metadata_uri`.
   - Reject issuing to the zero/empty address.
   - Add a clear `require!` message for each.

3. **Improve frontend state handling**
   - In `CertificateViewer.tsx`, distinguish "not found" from "revoked" from
     "expired" with different messages.
   - Disable the issue button while a transaction is pending (already partially
     done — make the UX clearer, add a success toast).

✅ Success: tests still pass, and the new rules are visible in the UI.

---

## 🔴 Advanced

Goal: improve architecture, security, tests, and integrations.

1. **Add issuer roles (multi-issuer)**
   - Replace the single `issuer` with a `SetMapper<ManagedAddress>` (a set of
     authorized issuers).
   - Add `addIssuer` / `removeIssuer` (owner-only) and update the access check.

2. **Add batch certificate issuance**
   - Add `issueCertificateBatch` taking a list of `(student, course, uri)`.
   - Mind gas: cap the batch size with a `require!` and document the limit.

3. **Add index/query improvements**
   - Maintain a per-student index (`MapMapper<ManagedAddress, ManagedVec<u64>>`)
     so you can list all certificates for a student.
   - Add a `getCertificatesByStudent(student)` view.

4. **Add stronger testing**
   - Cover the revoke flow, expiration, access-control failures, and batch
     limits with `klever-sc-scenario` tests.
   - Add a negative test that a non-issuer cannot add issuers.

✅ Success: a richer, safer contract with meaningful test coverage and updated
docs/frontend.

---

## Stretch ideas

- Emit richer events and subscribe to them in the frontend (auto-refresh).
- Add a small backend using `NodeWallet` that issues certificates from a server.
- Write a `.scen.json` black-box scenario for the full lifecycle.
