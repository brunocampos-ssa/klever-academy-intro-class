/**
 * CertificateViewer.tsx — Query a certificate by ID and show its status.
 *
 * Reads are free and need no wallet — we use a read-only Contract instance
 * (provider only). We call `isValid` and `getCertificate`.
 */
import { useState } from "react";
import { getReadContract } from "../klever";

export function CertificateViewer() {
  const [id, setId] = useState("1");
  const [valid, setValid] = useState<boolean | null>(null);
  const [details, setDetails] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleQuery() {
    setError(null);
    setValid(null);
    setDetails(null);
    setBusy(true);
    try {
      const contract = getReadContract();
      const numericId = Number(id);

      // isValid -> boolean (true only if it exists and is not revoked)
      const isValid = await contract.call<boolean>("isValid", numericId);
      setValid(isValid);

      // getCertificate -> the full struct (or empty if it doesn't exist)
      const cert = await contract.call("getCertificate", numericId);
      setDetails(JSON.stringify(cert, null, 2));
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "Failed to query certificate",
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <section>
      <h2>3. Verify Certificate</h2>
      <label style={{ display: "block", marginBottom: 8 }}>
        Certificate ID
        <input
          style={{ display: "block", width: 120 }}
          value={id}
          onChange={(e) => setId(e.target.value)}
          type="number"
          min={1}
        />
      </label>

      <button onClick={handleQuery} disabled={busy}>
        {busy ? "Querying..." : "Query"}
      </button>

      {valid !== null && (
        <p>
          Status:{" "}
          {valid ? (
            <strong style={{ color: "green" }}>VALID ✅</strong>
          ) : (
            <strong style={{ color: "crimson" }}>
              INVALID / REVOKED / NOT FOUND ❌
            </strong>
          )}
        </p>
      )}

      {details && (
        <pre
          style={{
            background: "#f5f5f5",
            padding: "0.75rem",
            overflowX: "auto",
          }}
        >
          {details}
        </pre>
      )}

      {error && <p style={{ color: "crimson" }}>⚠️ {error}</p>}
    </section>
  );
}
