/**
 * interact.ts — Talk to the Certificate Registry from Node.js using Klever Connect.
 *
 * What it does:
 *   - Connects to a Klever network with KleverProvider.
 *   - Loads a NodeWallet from a private key (server-side / scripting only).
 *   - Loads the contract via its ABI (ethers.js-style Contract class).
 *   - Issues a certificate (write) and reads it back (query).
 *
 * Run with (after `npm install` in app/web, or a standalone ts-node setup):
 *   PRIVATE_KEY=... CONTRACT_ADDRESS=klv1... npx tsx scripts/interact.ts
 *
 * SECURITY: never hardcode a private key. This script reads it from the
 * environment. Use a dedicated TESTNET wallet for class. See .env.example.
 *
 * NOTE: package/method names follow @klever/connect. If an import path differs
 * in your installed version, check https://docs.klever.org and the package
 * exports. We avoid inventing unsupported APIs.
 */

import { readFileSync } from "node:fs";
import { KleverProvider } from "@klever/connect-provider";
import { NodeWallet } from "@klever/connect-wallet";
import { Contract } from "@klever/connect-contracts";
import type { ContractABI } from "@klever/connect-contracts";

// --- Configuration (all via environment, with safe placeholders) -------------
const NETWORK = (process.env.NETWORK ?? "testnet") as
  | "mainnet"
  | "testnet"
  | "devnet";
const PRIVATE_KEY = process.env.PRIVATE_KEY ?? ""; // REQUIRED for writes
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS ?? "klv1..._REPLACE_ME";

// Adjust the path if you run this from a different working directory.
const ABI = JSON.parse(
  readFileSync(
    "contracts/certificate-registry/abi/certificate-registry.abi.json",
    "utf-8",
  ),
) as ContractABI;

async function main() {
  const provider = new KleverProvider({ network: NETWORK });

  // --- Read-only example: query with just a provider (no key needed) ---------
  const reader = new Contract(CONTRACT_ADDRESS, ABI, provider);
  const total = await reader.call<bigint>("getTotalCertificates");
  console.log("Total certificates so far:", total.toString());

  // --- Write example: needs a signer (wallet) -------------------------------
  if (!PRIVATE_KEY) {
    console.log("\nNo PRIVATE_KEY set — skipping the write example.");
    console.log("Set PRIVATE_KEY to issue a certificate.");
    return;
  }

  const wallet = new NodeWallet(provider, PRIVATE_KEY);
  await wallet.connect();
  console.log("Issuer wallet:", wallet.address);

  const writer = new Contract(CONTRACT_ADDRESS, ABI, wallet);

  // Issue a certificate for a sample student (replace with a real address).
  const student = process.env.STUDENT_ADDRESS ?? wallet.address;
  console.log(`Issuing certificate for ${student}...`);
  const result = await writer.invoke(
    "issueCertificate",
    student,
    "Klever Academy Intro Class",
    "ipfs://replace-with-real-cid",
  );
  console.log("Issue tx submitted:", result);

  // Read back the latest validity (id 1 for the first certificate).
  const id = 1;
  const valid = await reader.call<boolean>("isValid", id);
  console.log(`Certificate #${id} valid?`, valid);
}

main().catch((err) => {
  console.error("interact.ts failed:", err);
  process.exit(1);
});
