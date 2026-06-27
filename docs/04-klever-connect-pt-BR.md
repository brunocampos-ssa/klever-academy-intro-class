# 04 — Klever Connect

[English](./04-klever-connect.md)

Como a sua aplicação conversa com a Klever Blockchain.

---

## O que é o Klever Connect?

O **Klever Connect** (`@klever/connect`) é o SDK oficial em TypeScript/JavaScript
para construir na Klever. Ele cuida do que todo dApp precisa:

- **Provider** — ler a rede, enviar transações (`KleverProvider`).
- **Carteiras** — `BrowserWallet` (extensão) e `NodeWallet` (servidor/scripts).
- **Transações** — montar, assinar, transmitir (`TransactionBuilder`, `Transaction`).
- **Contratos** — uma classe `Contract` no estilo ethers.js, guiada pela sua ABI.

Instale:

```bash
npm install @klever/connect
# ou importe só os subpacotes que você precisa:
npm install @klever/connect-provider @klever/connect-wallet @klever/connect-contracts
```

---

## Os objetos principais

```txt
KleverProvider ──▶ lê a rede (consultas, saldos, broadcasting)
      │
      ├── BrowserWallet ──▶ assina via a Klever Web Extension (dApps)
      └── NodeWallet    ──▶ assina com uma chave privada (backend / scripts)

Contract(endereco, abi, signerOuProvider)
      ├── só provider ──▶ leituras gratuitas (call)
      └── carteira (signer) ──▶ escritas (invoke)
```

> Regra prática: **provider para leituras, carteira para escritas.**

---

## Uso em backend / scripts (NodeWallet)

Usado em `scripts/interact.ts`. A chave vem de uma variável de ambiente — nunca
fica fixa no código.

```ts
import { KleverProvider } from "@klever/connect-provider";
import { NodeWallet } from "@klever/connect-wallet";
import { Contract } from "@klever/connect-contracts";

const provider = new KleverProvider({ network: "testnet" });
const wallet = new NodeWallet(provider, process.env.PRIVATE_KEY!);
await wallet.connect();

const contract = new Contract(CONTRACT_ADDRESS, ABI, wallet);
await contract.invoke("issueCertificate", student, "Course", "ipfs://cid");
```

> ⚠️ O `NodeWallet` é só para servidores e scripts. Nunca leve uma chave privada
> para o navegador. No navegador, use o `BrowserWallet`.

---

## Uso no frontend (BrowserWallet)

Usado em `app/web`. A extensão guarda a chave; o seu código só enxerga o endereço
e pede para a extensão assinar.

```ts
import { KleverProvider } from "@klever/connect-provider";
import { BrowserWallet } from "@klever/connect-wallet";

const provider = new KleverProvider({ network: "testnet" });
const wallet = new BrowserWallet(provider);
await wallet.connect();           // abre o pop-up da extensão
console.log("Conectado:", wallet.address);
```

Tudo isso fica centralizado em [`app/web/src/klever.ts`](../app/web/src/klever.ts).

---

## Fluxo de conexão da carteira

```txt
Usuário clica em "Conectar"
     │
     ▼
BrowserWallet.connect()  ──▶ pop-up da extensão ──▶ usuário aprova
     │
     ▼
wallet.address disponível  ──▶ monta um Contract de escrita (endereco, abi, wallet)
```

---

## Fluxo de uma transação (uma escrita)

```txt
contract.invoke("issueCertificate", ...args)
     │  monta a transação a partir da ABI
     ▼
a carteira assina  (pop-up da extensão, ou NodeWallet com a chave)
     │
     ▼
o provider transmite  ──▶ nó ──▶ incluída em um bloco
     │
     ▼
resultado (hash da tx); leia de volta com uma view (isValid / getCertificate)
```

Para leituras, pule a assinatura por completo: `contract.call("isValid", id)`.

---

## Onde configurar

| Lugar | O quê |
| --- | --- |
| `app/web/src/klever.ts` | rede, endereço do contrato, ABI (frontend) |
| `.env` | `PRIVATE_KEY`, `CONTRACT_ADDRESS`, `NETWORK` (scripts) |

---

Próximo: [`05-ai-assisted-development-pt-BR.md`](05-ai-assisted-development-pt-BR.md)
