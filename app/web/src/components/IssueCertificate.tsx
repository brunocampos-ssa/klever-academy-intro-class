/**
 * IssueCertificate.tsx — Issue a certificate (a state-changing transaction).
 *
 * Only the issuer wallet will succeed on-chain; the contract enforces that.
 * This component just builds the call and lets the extension sign it.
 */
import { useState } from "react";
import type { BrowserWallet } from "@klever/connect";
import { getWriteContract } from "../klever";

type Props = {
  wallet: BrowserWallet | null;
};

export function IssueCertificate({ wallet }: Props) {
  const [student, setStudent] = useState("");
  const [course, setCourse] = useState("Klever Academy Intro Class");
  const [metadataUri, setMetadataUri] = useState("ipfs://replace-with-cid");
  const [status, setStatus] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function handleIssue() {
    if (!wallet) return;
    setStatus(null);
    setBusy(true);
    try {
      const contract = getWriteContract(wallet);
      // `course` and `metadata_uri` are `bytes` in the ABI. The SDK only
      // UTF-8-encodes values for `string` params — for `bytes` it passes the
      // value straight through, so we must hand it real bytes ourselves.
      // (The `student` arg is an `Address`; the SDK decodes klv1... for us.)
      const toBytes = (s: string) => new TextEncoder().encode(s);
      // The extension will pop up to sign this transaction.
      const result = await contract.invoke(
        "issueCertificate",
        student,
        toBytes(course),
        toBytes(metadataUri),
      );
      setStatus(`✅ Submitted: ${JSON.stringify(result)}`);
    } catch (e) {
      setStatus(
        `⚠️ ${e instanceof Error ? e.message : "Failed to issue certificate"}`,
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <section>
      <h2>2. Issue Certificate</h2>
      {!wallet && (
        <p style={{ color: "#999" }}>Connect a wallet first to issue.</p>
      )}

      <label style={{ display: "block", marginBottom: 8 }}>
        Student address (klv1...)
        <input
          style={{ display: "block", width: "100%" }}
          value={student}
          onChange={(e) => setStudent(e.target.value)}
          placeholder="klv1..."
        />
      </label>

      <label style={{ display: "block", marginBottom: 8 }}>
        Course
        <input
          style={{ display: "block", width: "100%" }}
          value={course}
          onChange={(e) => setCourse(e.target.value)}
        />
      </label>

      <label style={{ display: "block", marginBottom: 8 }}>
        Metadata URI / hash
        <input
          style={{ display: "block", width: "100%" }}
          value={metadataUri}
          onChange={(e) => setMetadataUri(e.target.value)}
        />
      </label>

      <button onClick={handleIssue} disabled={!wallet || busy || !student}>
        {busy ? "Issuing..." : "Issue Certificate"}
      </button>

      {status && <p>{status}</p>}
    </section>
  );
}
