/**
 * klever.ts — Central Klever Connect configuration for the frontend.
 *
 * THIS IS THE ONE FILE TO EDIT when wiring the app to your deployment:
 *   1. NETWORK            — which Klever network to talk to.
 *   2. CONTRACT_ADDRESS   — your deployed Certificate Registry address.
 *   3. ABI                — the contract ABI (kept in sync with the contract).
 *
 * Everything else (components) imports the helpers below, so configuration
 * lives in a single place.
 *
 * NOTE: imports follow @klever/connect. If a path differs in your installed
 * version, check https://docs.klever.org.
 */

import {
  KleverProvider,
  BrowserWallet,
  Contract,
  type ContractABI,
} from "@klever/connect";

// 1) Network: "mainnet" | "testnet" | "devnet". Use testnet for class.
export const NETWORK = "testnet" as const;

// 2) Contract address — REPLACE with the address printed by ./scripts/deploy.sh
export const CONTRACT_ADDRESS =
  "klv1qqqqqqqqqqqqqpgqa75cfz2hgw2fucqf4cf9ewrv432av26zn00syfsnn9";

// 3) ABI — import the generated/reference ABI. After `ksc all build`, you can
//    point this at contracts/certificate-registry/output/*.abi.json instead.
import abiJson from "../../../contracts/certificate-registry/abi/certificate-registry.abi.json";
export const ABI = abiJson as unknown as ContractABI;

// A single shared provider instance for the whole app.
export const provider = new KleverProvider({ network: NETWORK });

/**
 * Connect the Klever Web Extension wallet.
 * The private key NEVER touches our code — the extension signs on the user's behalf.
 */
export async function connectWallet(): Promise<BrowserWallet> {
  const wallet = new BrowserWallet(provider);
  await wallet.connect(); // opens the extension prompt
  return wallet;
}

/** A read-only contract instance (queries only — no signer needed). */
export function getReadContract(): Contract {
  return new Contract(CONTRACT_ADDRESS, ABI, provider);
}

/** A writable contract instance bound to a connected wallet (for invokes). */
export function getWriteContract(wallet: BrowserWallet): Contract {
  return new Contract(CONTRACT_ADDRESS, ABI, wallet);
}
