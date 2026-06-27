# Aula Introdutória Klever Academy: Crie, Publique e Conecte seu Primeiro Smart Contract

_Aprenda Web3 colocando a mão na massa: crie, teste, publique e conecte um smart contract de verdade na Klever Blockchain._

[English](./README.md)

> Um repositório pronto para sala de aula que leva você do zero a um smart
> contract publicado e conectado na **Klever Blockchain**.
>
> **Este README foi escrito como o slide deck da aula.**
> Apresente de cima para baixo. Cada `---` é uma troca de slide.

```txt
O que você vai fazer hoje:
  build  ─▶  testar  ─▶  deploy   ─▶  conectar       ─▶  verificar
  (Rust)    (cargo)    (koperator)   (Klever Connect)    (on-chain)
```

---

## Boas-vindas

Boas-vindas à **Aula Introdutória da Klever Academy**.

Ao final desta aula você terá:

- Entendido a Klever Blockchain do ponto de vista de quem desenvolve.
- Criado e testado um smart contract de verdade (um **Registro de Certificados**).
- Feito o deploy na testnet da Klever.
- Conectado uma aplicação web a ele com o **Klever Connect**.

> Foco iniciante: siga o fluxo e rode os comandos.
> Foco intermediário: leia a arquitetura e modifique-a.
> Foco avançado: encontre os pontos de extensão e reforce-os.

---

## O que vamos construir

Um **Registro de Certificados**: um registro on-chain onde um emissor (a Klever
Academy) cria certificados verificáveis para os alunos.

```txt
        Emissor (Klever Academy)
                │ issueCertificate(aluno, curso, uri)
                ▼
        ┌───────────────────────────┐
        │   Registro de Certificados │   <- smart contract na Klever VM
        │   id → {aluno, curso,      │
        │         uri, emitido_em,   │
        │         revogado}          │
        └───────────────────────────┘
                ▲                 ▲
   getCertificate(id)        isValid(id)
                │                 │
            App web  ◀── Klever Connect ──▶  Quem quiser verificar
```

---

## Por que Klever Blockchain?

Do ponto de vista de quem desenvolve, a Klever oferece:

- **Klever VM** — executa smart contracts em WebAssembly escritos em Rust.
- **Ferramentas de primeira linha** — `ksc` (build) e `koperator`
  (deploy/invoke), via `install.klever.org`.
- **Klever Connect** — um SDK em TypeScript para conectar aplicações à rede.
- **IA que conhece a Klever** — `ai.klever.org` / Klever MCP, que conhece os
  comandos e a documentação corretos.
- **Documentação clara** — `docs.klever.org` como fonte única da verdade.

---

## Visão geral da aula

| | |
| --- | --- |
| **Formato** | mão na massa, ~60–90 min |
| **Tema** | Registro de Certificados on-chain |
| **Você sai com** | um contrato publicado + um app conectado |
| **Repositório** | `klever-academy-intro-class` |

O ciclo que vamos repetir: **build → testar → deploy → conectar → verificar.**

---

## Público-alvo

Esta aula foi pensada para **todos os níveis**:

- **Iniciantes** — novos em blockchain e/ou Rust. Você segue o fluxo.
- **Intermediários** — confortáveis programando; vão modificar o contrato e os
  scripts.
- **Avançados** — vão identificar os pontos de extensão e melhorar arquitetura,
  segurança e testes.

---

## O que os alunos irão construir

1. Um smart contract em Rust para a Klever VM (`contracts/certificate-registry`).
2. Uma suíte de testes que roda em uma blockchain simulada.
3. Um deploy na testnet da Klever.
4. Um app React + TypeScript (`app/web`) usando o **Klever Connect**.
5. Scripts de linha de comando para build, deploy, emissão e consulta
   (`scripts/`).

---

## Pré-requisitos

- Um computador com terminal (Linux/macOS/WSL).
- **Rust + Cargo**, **Node.js 18+**, `jq`, `curl`.
- O **Klever SDK** via `install.klever.org` (`ksc`, `koperator`).
- A **Klever Web Extension** (navegador) com carteira de testnet + KLV do faucet.

➡️ Passo a passo completo em [`docs/01-setup-pt-BR.md`](docs/01-setup-pt-BR.md).

---

## Visão geral da Klever Blockchain para desenvolvedores

Modelo mental para quem faz aplicações:

```txt
Seu app ──(leituras/consultas)──▶  API do nó Klever ──▶ estado da rede
Seu app ──(escritas/txs)────────▶  assina c/ carteira ──▶ broadcast ──▶ bloco
Smart contract ── vive na ──▶ Klever VM (WASM)
```

- **Leituras** (views) são gratuitas e não precisam de carteira.
- **Escritas** (endpoints) exigem transação assinada e uma pequena taxa.
- **Redes**: mainnet (real), testnet (prática gratuita), local (sua máquina).

---

## Klever VM e smart contracts

- Contratos são em **Rust**, compilados para **WebAssembly** para a **Klever VM**.
- O framework `klever-sc` oferece anotações:
  - `#[init]` — construtor, roda uma vez no deploy.
  - `#[endpoint]` — função que altera estado (uma escrita).
  - `#[view]` — função somente leitura (uma consulta gratuita).
  - `#[storage_mapper(...)]` — estado persistente.
  - `#[event(...)]` — logs estruturados.

```rust
#[endpoint(issueCertificate)]
fn issue_certificate(&self, student: ManagedAddress, course: ManagedBuffer, metadata_uri: ManagedBuffer) -> u64 {
    self.require_caller_is_issuer();
    // ... grava o certificado, incrementa o contador, emite um evento
}
```

➡️ Explicação completa em [`docs/02-smart-contract-pt-BR.md`](docs/02-smart-contract-pt-BR.md).

---

## Visão geral das ferramentas

| Ferramenta | Papel | Origem |
| --- | --- | --- |
| `ksc` | compila o contrato → wasm + ABI | `install.klever.org` |
| `koperator` | deploy + invoke de contratos | `install.klever.org` |
| `@klever/connect` | conecta apps à rede | npm |
| `ai.klever.org` / Klever MCP | assistente de IA | `ai.klever.org` |
| `docs.klever.org` | a referência | web |

> Importante: a Klever usa `ksc all build` e `koperator sc create/invoke` —
> **não** `sc-meta`, `mxpy`, `hardhat` ou `foundry`. Uma IA que conhece a Klever
> evita que você copie comandos da rede errada.

---

## Instalação das ferramentas de desenvolvimento Klever

```bash
# Instale o Klever SDK (revise o script em install.klever.org antes).
curl -sSf https://install.klever.org | bash

# Verifique
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version
```

Isso instala `ksc` e `koperator` em `~/klever-sdk/`.

➡️ Detalhes + solução de problemas em [`docs/01-setup-pt-BR.md`](docs/01-setup-pt-BR.md).

---

## Usando IA com `ai.klever.org`

Use um assistente que **conhece a Klever** para avançar mais rápido:

- **Explicar** o contrato → [`prompts/ai-explain-contract.md`](prompts/ai-explain-contract.md)
- **Revisar** o contrato → [`prompts/ai-review-contract.md`](prompts/ai-review-contract.md)
- **Depurar** um erro → [`prompts/ai-debug-contract.md`](prompts/ai-debug-contract.md)
- **Gerar testes** e **melhorar a documentação**.

➡️ Como fazer em [`docs/05-ai-assisted-development-pt-BR.md`](docs/05-ai-assisted-development-pt-BR.md).

---

## Arquitetura do projeto

```txt
klever-academy-intro-class/
├── contracts/certificate-registry/   # smart contract em Rust (Klever VM)
│   ├── src/lib.rs                     #   o contrato
│   ├── tests/                         #   testes cargo (rede simulada)
│   ├── abi/                           #   ABI de referência (front/scripts usam)
│   └── meta/                          #   ferramenta de build
├── app/web/                          # frontend React + TS (Klever Connect)
│   └── src/klever.ts                  #   ← toda a config de rede fica aqui
├── scripts/                          # build / deploy / issue / query / interact
├── docs/                             # docs passo a passo da aula
└── prompts/                          # prompts de IA prontos para uso
```

> Foco iniciante: você mexe principalmente em `app/web` e roda `scripts/`.
> Foco intermediário: você edita `contracts/.../lib.rs` e `scripts/`.
> Foco avançado: você remodela o storage, adiciona papéis e amplia `tests/`.

---

## Explicação do smart contract

O contrato tem seis seções identificadas em `src/lib.rs`:

1. **Init** — quem faz o deploy vira o emissor.
2. **Endpoints de escrita** — `issueCertificate`, `revokeCertificate`, `setIssuer`.
3. **Views** — `getCertificate`, `isValid`, `getTotalCertificates`, `getIssuer`.
4. **Storage** — `issuer`, `lastId`, `certificates`.
5. **Eventos** — `certificateIssued`, `certificateRevoked`.
6. **Auxiliares** — checagem de emissor, buscar-ou-falhar.

Ciclo de vida de um certificado:

```txt
issueCertificate ─▶ exige emissor ─▶ grava + lastId++ ─▶ emite evento
                                                           │
qualquer um ─▶ isValid(id) ─▶ true (até ser revogado) ◀────┘
```

➡️ Leia linha a linha em [`docs/02-smart-contract-pt-BR.md`](docs/02-smart-contract-pt-BR.md).

---

## Processo de build

```bash
./scripts/build.sh        # roda: ~/klever-sdk/ksc all build
```

Gera `contracts/certificate-registry/output/`:
- `certificate-registry.wasm` (publicável)
- `certificate-registry.abi.json` (para o front/scripts)

---

## Processo de testes

```bash
./scripts/test.sh         # roda: cargo test
```

Os testes rodam em uma **blockchain simulada** — sem rede, sem taxas. Cobrem
deploy, emissão e controle de acesso. Amplie-os nos desafios.

> Foco iniciante: apenas rode e leia a saída verde.
> Foco avançado: adicione testes de revogação/expiração/papéis.

---

## Processo de deploy

```bash
# 1) Coloque saldo na carteira de testnet (faucet) — veja docs/01
# 2) Configure o .env (KEY_FILE, KLEVER_NODE)
./scripts/deploy.sh       # roda: koperator sc create ... --await --sign
```

Copie o endereço `klv1...` impresso para:
- `.env` → `CONTRACT_ADDRESS`
- `app/web/src/klever.ts` → `CONTRACT_ADDRESS`

➡️ Detalhes em [`docs/03-build-test-deploy-pt-BR.md`](docs/03-build-test-deploy-pt-BR.md).

---

## Interagindo com o contrato

**Pela linha de comando:**

```bash
# Emitir (escrita) — só a carteira emissora tem sucesso
./scripts/issue-certificate.sh klv1aluno... "Klever Academy Intro Class" "ipfs://cid"

# Consultar (leitura) — gratuito, sem carteira
./scripts/query-certificate.sh 1
```

**Pelo Node.js (Klever Connect):**

```bash
PRIVATE_KEY=... CONTRACT_ADDRESS=klv1... npx tsx scripts/interact.ts
```

---

## Conectando com Klever Connect

O app web conecta tudo por um único arquivo: `app/web/src/klever.ts`.

```ts
const provider = new KleverProvider({ network: "testnet" });
const wallet   = new BrowserWallet(provider);   // Klever Web Extension
await wallet.connect();

const contract = new Contract(CONTRACT_ADDRESS, ABI, wallet);
await contract.invoke("issueCertificate", student, course, uri); // escrita
const valid = await contract.call("isValid", id);                // leitura
```

Rode:

```bash
cd app/web && npm install && npm run dev
```

➡️ Guia completo em [`docs/04-klever-connect-pt-BR.md`](docs/04-klever-connect-pt-BR.md).

---

## Fluxo sugerido para demonstração ao vivo

1. `./scripts/build.sh` — mostre o wasm aparecer.
2. `./scripts/test.sh` — mostre os testes verdes.
3. `./scripts/deploy.sh` — copie o endereço do contrato.
4. Cole o endereço em `app/web/src/klever.ts`.
5. `cd app/web && npm run dev` — conecte a carteira.
6. Emita um certificado na interface; assine na extensão.
7. Consulte o ID; mostre **VÁLIDO ✅**.
8. (Opcional) `revokeCertificate`, consulte de novo, mostre **INVÁLIDO ❌**.

---

## Desafios para desenvolvedores iniciantes, intermediários e avançados

- 🟢 **Iniciante** — conectar carteira, mudar rótulos do app, consultar um
  certificado.
- 🟡 **Intermediário** — adicionar expiração, validação mais forte, melhor
  estado de UI.
- 🔴 **Avançado** — papéis de emissor, emissão em lote, índice por aluno, mais
  testes.

➡️ Descrições completas em [`docs/06-class-challenges-pt-BR.md`](docs/06-class-challenges-pt-BR.md).

---

## Referências e próximos passos

- **Documentação:** https://docs.klever.org
- **Instalar ferramentas:** https://install.klever.org
- **Assistente de IA:** https://ai.klever.org
- Este repositório: `docs/`, `prompts/`, `scripts/`, `contracts/`, `app/web/`.

Próximos passos:
1. Conclua um desafio do `docs/06`.
2. Faça o deploy da sua própria variação na testnet.
3. Compartilhe o que você construiu com a comunidade Klever Academy.

---

## Licença

MIT — veja [`LICENSE`](LICENSE).
