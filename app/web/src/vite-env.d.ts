/// <reference types="vite/client" />

// Type the custom env vars we read via `import.meta.env`. Vite only exposes
// variables prefixed with `VITE_` to the browser bundle.
interface ImportMetaEnv {
  /** Deployed Certificate Registry address (klv1...). Set in app/web/.env. */
  readonly VITE_CONTRACT_ADDRESS?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
