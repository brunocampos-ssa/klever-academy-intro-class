/**
 * App.tsx — Top-level UI for the Certificate Registry demo.
 *
 * Layout (teaching flow, top to bottom):
 *   1. ConnectWallet      — connect the Klever Web Extension, show the account.
 *   2. IssueCertificate   — issuer creates a certificate (a write transaction).
 *   3. CertificateViewer  — anyone queries a certificate by ID (a read).
 *
 * The wallet lives in App state so children can share the same connection.
 */
import { useState } from "react";
import type { BrowserWallet } from "@klever/connect-wallet";
import { ConnectWallet } from "./components/ConnectWallet";
import { IssueCertificate } from "./components/IssueCertificate";
import { CertificateViewer } from "./components/CertificateViewer";
import { CONTRACT_ADDRESS, NETWORK } from "./klever";

export default function App() {
  // The connected wallet (or null when disconnected). Shared with children.
  const [wallet, setWallet] = useState<BrowserWallet | null>(null);

  return (
    <main
      style={{
        maxWidth: 720,
        margin: "0 auto",
        padding: "2rem 1rem",
        fontFamily: "system-ui, sans-serif",
        lineHeight: 1.5,
      }}
    >
      <header>
        <h1>Klever Academy — Certificate Registry</h1>
        <p style={{ color: "#666" }}>
          Connect your wallet, issue a certificate, and verify it on-chain.
        </p>
        <p style={{ fontSize: 12, color: "#999" }}>
          Network: <code>{NETWORK}</code> · Contract:{" "}
          <code>{CONTRACT_ADDRESS}</code>
        </p>
      </header>

      <hr />

      {/* 1. Wallet connection */}
      <ConnectWallet wallet={wallet} onChange={setWallet} />

      <hr />

      {/* 2. Issue (write) — requires a connected wallet */}
      <IssueCertificate wallet={wallet} />

      <hr />

      {/* 3. Query (read) — works without a wallet */}
      <CertificateViewer />
    </main>
  );
}
