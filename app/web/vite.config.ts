// Vite config for the React + TypeScript frontend.
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // Allow importing the contract ABI JSON from outside app/web (see klever.ts).
  // `fs.allow` lets Vite read the repo root during dev.
  server: {
    fs: {
      allow: [".."],
    },
  },
});
