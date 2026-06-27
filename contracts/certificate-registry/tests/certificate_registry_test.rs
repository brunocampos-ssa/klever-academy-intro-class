//! Unit / integration tests for the Certificate Registry contract.
//!
//! These tests use the `klever-sc-scenario` testing framework, which runs the
//! contract logic in a simulated blockchain environment — no real network and
//! no real KLV required. Run them with `cargo test` (or `./scripts/test.sh`).
//!
//! > Beginner focus: read the test names — they describe the expected behavior.
//! > Intermediate focus: add a test for the revoke flow (see the challenges doc).
//! > Advanced focus: convert these into `.scen.json` scenario files for full
//! >   black-box coverage, and test the access-control failure paths.
//!
//! NOTE: The exact testing API (whitebox vs blackbox, helper names) can vary
//! between framework versions. If a symbol below does not resolve, check the
//! testing chapter at https://docs.klever.org and align the imports. The intent
//! and structure of each test stays the same.

use certificate_registry::*;
use klever_sc::types::{ManagedBuffer, ManagedAddress};
use klever_sc_scenario::imports::*;

// Address aliases used inside the simulated world.
const OWNER: TestAddress = TestAddress::new("owner");
const STUDENT: TestAddress = TestAddress::new("student");
const CODE_PATH: KleverscPath = KleverscPath::new("output/certificate-registry.kleversc.json");
const SC_ADDRESS: TestSCAddress = TestSCAddress::new("certificate-registry");

/// Build the simulated world and register the compiled contract code.
fn world() -> ScenarioWorld {
    let mut blockchain = ScenarioWorld::new();
    blockchain.register_contract(CODE_PATH, certificate_registry::ContractBuilder);
    blockchain
}

/// Deploy a fresh contract with `owner` as the deployer/issuer.
fn deploy(world: &mut ScenarioWorld) {
    world.account(OWNER).nonce(1);
    world.account(STUDENT).nonce(1);

    world
        .tx()
        .from(OWNER)
        .typed(certificate_registry_proxy::CertificateRegistryProxy)
        .init()
        .code(CODE_PATH)
        .new_address(SC_ADDRESS)
        .run();
}

#[test]
fn deploy_sets_issuer_to_owner() {
    let mut world = world();
    deploy(&mut world);

    // After deploy, total certificates should be zero.
    world
        .query()
        .to(SC_ADDRESS)
        .typed(certificate_registry_proxy::CertificateRegistryProxy)
        .get_total_certificates()
        .returns(ExpectValue(0u64))
        .run();
}

#[test]
fn issuer_can_issue_certificate() {
    let mut world = world();
    deploy(&mut world);

    // The issuer (owner) issues a certificate for the student.
    world
        .tx()
        .from(OWNER)
        .to(SC_ADDRESS)
        .typed(certificate_registry_proxy::CertificateRegistryProxy)
        .issue_certificate(
            ManagedAddress::from(STUDENT.eval_to_array()),
            ManagedBuffer::from(b"Klever Academy Intro Class"),
            ManagedBuffer::from(b"ipfs://example-cid"),
        )
        .returns(ExpectValue(1u64)) // first id is 1
        .run();

    // The certificate should now be valid.
    world
        .query()
        .to(SC_ADDRESS)
        .typed(certificate_registry_proxy::CertificateRegistryProxy)
        .is_valid(1u64)
        .returns(ExpectValue(true))
        .run();
}

#[test]
fn non_issuer_cannot_issue_certificate() {
    let mut world = world();
    deploy(&mut world);

    // The student is NOT the issuer, so this must fail.
    world
        .tx()
        .from(STUDENT)
        .to(SC_ADDRESS)
        .typed(certificate_registry_proxy::CertificateRegistryProxy)
        .issue_certificate(
            ManagedAddress::from(STUDENT.eval_to_array()),
            ManagedBuffer::from(b"Self Issued"),
            ManagedBuffer::from(b"ipfs://nope"),
        )
        // 57 is the Klever VM status code for a user error raised by `require!`.
        .returns(ExpectError(57, "only the issuer can do this"))
        .run();
}

// TODO (Intermediate challenge): add a test that revokes a certificate and
// asserts `is_valid` returns false afterwards. See docs/06-class-challenges.md.
