#![no_std]

//! # Certificate Registry — Klever Academy Intro Class
//!
//! A simple, classroom-friendly smart contract for Klever VM that lets an
//! **issuer** create on-chain certificates for students and lets **anyone**
//! query and validate them.
//!
//! Teaching goals:
//! - See how a Klever smart contract is structured (init, endpoints, views, storage, events).
//! - Understand storage mappers and custom struct types.
//! - Understand access control (`only_owner` / issuer checks) and `require!` validation.
//!
//! > Beginner focus: read the comments top to bottom — each annotation maps to one concept.
//! > Intermediate focus: notice how storage mappers model the data and how events are emitted.
//! > Advanced focus: see the `Challenges` in `docs/06-class-challenges.md` to extend this safely.
//!
//! NOTE: This contract targets the `klever-sc` framework. If a macro or type name
//! differs in your installed framework version, align it with the official template
//! and reference at https://docs.klever.org. We avoid inventing unsupported APIs.

#[allow(unused_imports)]
use klever_sc::imports::*;

/// The on-chain representation of a single certificate.
///
/// The derive macros make the struct serializable into contract storage and
/// decodable by clients (the `#[type_abi]` attribute also exports it to the ABI
/// so tools like Klever Connect can decode it automatically).
#[type_abi]
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, Clone, PartialEq, Debug)]
pub struct Certificate<M: ManagedTypeApi> {
    /// Sequential identifier assigned by the contract.
    pub id: u64,
    /// The student's wallet address (who the certificate belongs to).
    pub student: ManagedAddress<M>,
    /// Course or class name, e.g. "Klever Academy Intro Class".
    pub course: ManagedBuffer<M>,
    /// A metadata hash or URI pointing to off-chain details (e.g. IPFS CID).
    pub metadata_uri: ManagedBuffer<M>,
    /// Block timestamp (seconds) when the certificate was issued.
    pub issued_at: u64,
    /// Whether the certificate has been revoked by the issuer.
    pub revoked: bool,
}

/// The Certificate Registry contract.
///
/// Everything inside this trait annotated with `#[klever_sc::contract]` becomes
/// part of the deployed contract: storage, endpoints (writes), and views (reads).
#[klever_sc::contract]
pub trait CertificateRegistry {
    // ---------------------------------------------------------------------
    // 1. INITIALIZATION
    // ---------------------------------------------------------------------

    /// Runs exactly once, when the contract is deployed.
    ///
    /// The deployer becomes the contract owner automatically. Here we also
    /// record the deployer as the first authorized issuer and start IDs at 0.
    #[init]
    fn init(&self) {
        let owner = self.blockchain().get_caller();
        self.issuer().set(&owner);
        // last_id starts unset (0). The first certificate will be id = 1.
    }

    /// Called when the contract is upgraded. Kept empty on purpose so an
    /// upgrade does not reset state. Add migration logic here if you ever
    /// change the storage layout.
    #[upgrade]
    fn upgrade(&self) {}

    // ---------------------------------------------------------------------
    // 2. WRITE ENDPOINTS (state-changing transactions)
    // ---------------------------------------------------------------------

    /// Issue a new certificate for a student.
    ///
    /// Only the configured issuer can call this. Returns the new certificate ID
    /// so the caller (script or frontend) knows what to query next.
    ///
    /// > Intermediate focus: this is where you would add expiration or roles.
    #[endpoint(issueCertificate)]
    fn issue_certificate(
        &self,
        student: ManagedAddress,
        course: ManagedBuffer,
        metadata_uri: ManagedBuffer,
    ) -> u64 {
        self.require_caller_is_issuer();

        // Basic input validation. `require!` aborts the transaction with a
        // readable error message if the condition is false.
        require!(!course.is_empty(), "course must not be empty");

        // Compute the next sequential ID.
        let new_id = self.last_id().get() + 1;

        let certificate = Certificate {
            id: new_id,
            student: student.clone(),
            course,
            metadata_uri,
            issued_at: self.blockchain().get_block_timestamp(),
            revoked: false,
        };

        // Persist: store the certificate and bump the counter.
        self.certificates().insert(new_id, certificate);
        self.last_id().set(new_id);

        // Emit an event so off-chain indexers / dApps can react.
        self.certificate_issued_event(new_id, &student);

        new_id
    }

    /// Revoke an existing certificate. Only the issuer can revoke.
    ///
    /// Revoking does not delete the record — it flips `revoked = true` so the
    /// history stays auditable on-chain.
    #[endpoint(revokeCertificate)]
    fn revoke_certificate(&self, id: u64) {
        self.require_caller_is_issuer();

        let mut certificate = self.get_certificate_or_panic(id);
        require!(!certificate.revoked, "certificate already revoked");

        certificate.revoked = true;
        self.certificates().insert(id, certificate);

        self.certificate_revoked_event(id);
    }

    /// Transfer the issuer role to a new address. Owner-only for safety.
    ///
    /// > Advanced focus: a single issuer is a simplification. The challenges
    /// > doc walks through turning this into a multi-issuer role system.
    #[only_owner]
    #[endpoint(setIssuer)]
    fn set_issuer(&self, new_issuer: ManagedAddress) {
        self.issuer().set(&new_issuer);
    }

    // ---------------------------------------------------------------------
    // 3. READ VIEWS (free queries, no transaction needed)
    // ---------------------------------------------------------------------

    /// Return the full certificate for a given ID, or `None` if it does not exist.
    #[view(getCertificate)]
    fn get_certificate(&self, id: u64) -> OptionalValue<Certificate<Self::Api>> {
        if self.certificates().contains_key(&id) {
            OptionalValue::Some(self.certificates().get(&id).unwrap())
        } else {
            OptionalValue::None
        }
    }

    /// Validate a certificate: returns `true` only if it exists AND is not revoked.
    ///
    /// This is the endpoint a verifier (employer, school) would call to check
    /// whether a certificate is currently valid.
    #[view(isValid)]
    fn is_valid(&self, id: u64) -> bool {
        match self.certificates().get(&id) {
            Some(certificate) => !certificate.revoked,
            None => false,
        }
    }

    /// Total number of certificates ever issued (including revoked ones).
    #[view(getTotalCertificates)]
    fn get_total_certificates(&self) -> u64 {
        self.last_id().get()
    }

    // ---------------------------------------------------------------------
    // 4. STORAGE (the contract's persistent state)
    // ---------------------------------------------------------------------

    /// The address allowed to issue and revoke certificates.
    /// Exposed as a view via `#[view(getIssuer)]`.
    #[view(getIssuer)]
    #[storage_mapper("issuer")]
    fn issuer(&self) -> SingleValueMapper<ManagedAddress>;

    /// Auto-incrementing counter for certificate IDs.
    #[storage_mapper("lastId")]
    fn last_id(&self) -> SingleValueMapper<u64>;

    /// The certificate store: maps `id -> Certificate`.
    #[storage_mapper("certificates")]
    fn certificates(&self) -> MapMapper<u64, Certificate<Self::Api>>;

    // ---------------------------------------------------------------------
    // 5. EVENTS (structured logs for off-chain consumers)
    // ---------------------------------------------------------------------

    /// Emitted whenever a certificate is issued. `#[indexed]` fields become
    /// searchable topics so dApps can filter by ID or student.
    #[event("certificateIssued")]
    fn certificate_issued_event(
        &self,
        #[indexed] id: u64,
        #[indexed] student: &ManagedAddress,
    );

    /// Emitted whenever a certificate is revoked.
    #[event("certificateRevoked")]
    fn certificate_revoked_event(&self, #[indexed] id: u64);

    // ---------------------------------------------------------------------
    // 6. PRIVATE HELPERS (not part of the public ABI)
    // ---------------------------------------------------------------------

    /// Abort unless the caller is the authorized issuer.
    fn require_caller_is_issuer(&self) {
        let caller = self.blockchain().get_caller();
        require!(caller == self.issuer().get(), "only the issuer can do this");
    }

    /// Fetch a certificate or abort with a clear error.
    fn get_certificate_or_panic(&self, id: u64) -> Certificate<Self::Api> {
        self.certificates()
            .get(&id)
            .unwrap_or_else(|| sc_panic!("certificate does not exist"))
    }
}
