// Entry point for the contract's build/meta tooling.
// `ksc all build` invokes this to compile the wasm and generate the ABI.
// You rarely need to change this file.

fn main() {
    klever_sc_meta::cli_main::<certificate_registry::AbiProvider>();
}
