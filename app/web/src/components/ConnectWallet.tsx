/**
 * ConnectWallet.tsx — Connect/disconnect the Klever Web Extension wallet and
 * display the connected account address.
 *
 * Klever Connect detail: BrowserWallet talks to the browser extension; the
 * private key never enters our app. See klever.ts -> connectWallet().
 */
import { useState } from "react";
import type { BrowserWallet } from "@klever/connect";
import { connectWallet } from "../klever";

type Props = {
  wallet: BrowserWallet | null;
  onChange: (wallet: BrowserWallet | null) => void;
};

export function ConnectWallet({ wallet, onChange }: Props) {
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleConnect() {
    setError(null);
    setBusy(true);
    try {
      const w = await connectWallet();
      onChange(w);
    } catch (e) {
      // Common cause: the Klever Web Extension is not installed/unlocked.
      setError(
        e instanceof Error ? e.message : "Failed to connect wallet",
      );
    } finally {
      setBusy(false);
    }
  }

  function handleDisconnect() {
    wallet?.disconnect?.();
    onChange(null);
  }

  return (
    <section>
      <h2>1. Connect Wallet</h2>
      {wallet ? (
        <div>
          <p>
            ✅ Connected: <code>{wallet.address}</code>
          </p>
          <button onClick={handleDisconnect}>Disconnect</button>
        </div>
      ) : (
        <button onClick={handleConnect} disabled={busy}>
          {busy ? "Connecting..." : "Connect Klever Wallet"}
        </button>
      )}
      {error && <p style={{ color: "crimson" }}>⚠️ {error}</p>}
    </section>
  );
}
