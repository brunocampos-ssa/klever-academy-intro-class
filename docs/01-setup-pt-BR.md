# 01 — Configuração do ambiente

[English](./01-setup.md)

Tudo o que você precisa instalar antes da aula. Reserve uns ~15 minutos.

> Foco iniciante: apenas siga os passos na ordem.
> Foco intermediário: confira as versões e entenda o que cada ferramenta faz.
> Foco avançado: automatize isso nos seus dotfiles / em um devcontainer.

---

## 1. Ferramentas necessárias

| Ferramenta | Para quê | Origem |
| --- | --- | --- |
| Klever SDK (`ksc`, `koperator`) | compilar, fazer deploy e chamar contratos | https://install.klever.org |
| Rust + Cargo | o contrato é escrito em Rust | https://rustup.rs |
| **Target wasm** do Rust | compilar o contrato para WebAssembly (a Klever VM é baseada em wasm) | `rustup` |
| Node.js 20.19+ / 22.12+ | rodar o frontend e o `interact.ts` | https://nodejs.org |
| `jq`, `curl` | usados pelos scripts de shell | seu gerenciador de pacotes |
| Klever Web Extension | assinar transações no navegador | loja do Chrome/Brave |

---

## 2. Instale as ferramentas de desenvolvimento Klever

O instalador de uma linha de **https://install.klever.org** configura o Klever
SDK em `~/klever-sdk/` (é onde ficam o `ksc` e o `koperator`).

```bash
# Revise o script antes, se quiser, e então rode o instalador.
# Veja em https://install.klever.org o comando oficial e atualizado.
curl -sSf https://install.klever.org | bash
```

Ao terminar, os binários principais são:

```txt
~/klever-sdk/ksc         # compilador de smart contracts Klever (build, ABI)
~/klever-sdk/koperator   # CLI para deploy e invocação de contratos
```

> Se o instalador colocar o SDK em outro lugar, defina `KLEVER_SDK_PATH` no seu
> `.env` para que os scripts consigam encontrá-lo.

---

## 3. Adicione o target de build WebAssembly

**A Klever VM executa WebAssembly**, então o contrato compila para um `.wasm`.
Você não consegue compilar um smart contract Klever sem um **target wasm** do
Rust instalado.

```bash
# Rust 1.85+ (o que o `ksc` usa por padrão):
rustup target add wasm32v1-none

# Rust mais antigo (< 1.85):
rustup target add wasm32-unknown-unknown
```

> Na dúvida? Instalar **os dois** não faz mal — o `./scripts/build.sh` escolhe o
> que o seu toolchain usa. Se você pular isso, o build falha com
> `error[E0463]: can't find crate for 'core'` (o target wasm está faltando).

---

## 4. Confira seu ambiente

```bash
# Ferramentas Klever
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version

# Rust
rustc --version
cargo --version

# Target wasm do Rust (pelo menos um destes deve aparecer)
rustup target list --installed | grep wasm32

# Node.js (precisa ser 20.19+ ou 22.12+)
node --version
npm --version

# Auxiliares usados pelos scripts
jq --version
curl --version
```

Se algum comando retornar "not found" (ou a linha do target wasm vier vazia),
instale essa ferramenta/target antes de continuar.

---

## 5. Requisito de Node.js para o frontend

O app web usa Vite + React e precisa de **Node.js 20.19+ (ou 22.12+)**.

```bash
cd app/web
npm install
npm run dev   # sobe o servidor de desenvolvimento (tudo bem se o contrato ainda não foi publicado)
```

---

## 6. Preparação da carteira e da rede

Na aula usamos a **testnet** (gratuita, segura, descartável). Há **dois lugares**
que assinam transações, e eles usam credenciais **diferentes**:

| Onde | Assina com | Usado por |
| --- | --- | --- |
| O app web (`app/web`) | a **Klever Web Extension** | o frontend (BrowserWallet) |
| Os scripts de CLI (deploy/emissão) | um **arquivo PEM** (`koperator`) | `./scripts/deploy.sh`, etc. |

### 6.1 Extensão do navegador (para o app web)

1. Instale e desbloqueie a **Klever Web Extension**.
2. Crie uma carteira nova (NÃO reaproveite uma carteira com fundos reais).
3. Troque a rede da extensão para **Testnet**.

### 6.2 Arquivo de chave da CLI (PEM) — para o `koperator`

Os scripts de CLI fazem deploy e invoke via `koperator`, que assina com um
**arquivo PEM**. A configuração `KEY_FILE` no `.env` aponta para ele. Você tem
duas opções:

**Opção A — gerar uma carteira de CLI nova (mais simples, recomendado na aula):**

```bash
# Cria uma carteira nova e grava o PEM (com permissões 0600).
# Imprime o novo endereço klv1...
~/klever-sdk/koperator account create --key-file=./walletKey.pem
```

**Opção B — reaproveitar a conta da extensão (importar a chave privada):**

Use isto se quiser que a CLI assine como a **mesma conta** da sua extensão do
navegador. Na Klever Web Extension, revele/exporte a **chave privada em hex**
daquela conta (configurações da conta → exportar chave privada), e então:

```bash
# <CHAVE_PRIVADA_HEX> é a chave secreta de 64 caracteres hex exportada da extensão.
~/klever-sdk/koperator account import-sk <CHAVE_PRIVADA_HEX> --path ./walletKey.pem
```

> Se a extensão só te der uma **mnemônica/seed phrase** (e não uma chave hex),
> use a Opção A — na aula você não precisa que a CLI compartilhe a conta da
> extensão.

Aponte os scripts para o PEM no `.env` (veja `.env.example`):

```bash
KEY_FILE=./walletKey.pem        # ou um caminho absoluto como $HOME/klever-sdk/walletKey.pem
```

Confira o endereço de um PEM a qualquer momento:

```bash
~/klever-sdk/koperator account address --key-file=./walletKey.pem
```

### 6.3 Coloque saldo na carteira da CLI pelo faucet da testnet

Deploys custam uma pequena taxa, então o endereço da **carteira do PEM** precisa
de KLV de teste:

```bash
# Pegue o endereço do seu PEM e peça ao faucet para abastecê-lo.
ADDR=$(~/klever-sdk/koperator account address --key-file=./walletKey.pem | grep -oE 'klv1[0-9a-z]+' | tail -1)
curl -X POST \
  "https://api.testnet.klever.org/v1.0/transaction/send-user-funds/$ADDR" \
  -H "Content-Type: application/json"
```

> ⚠️ **Segurança.** O `import-sk` recebe a chave como argumento de linha de
> comando, então ela fica no histórico do shell e na lista de processos. Use uma
> **carteira de testnet dedicada**, nunca uma com fundos reais, e limpe essa
> linha do histórico depois (ex.: `history -d <n>`).
>
> ⚠️ Nunca faça commit de um arquivo de chave ou de uma seed phrase. O
> `.gitignore` já exclui `*.pem`, mas mantenha o cuidado.

---

## 7. Configuração do editor (VS Code + rust-analyzer)

O contrato é em Rust, mas você abre este repositório pela **raiz** — e a raiz não
tem um `Cargo.toml` (ela guarda o contrato, o app web, os scripts e os docs). Por
causa disso, **o rust-analyzer pode não detectar o contrato automaticamente** e
agir como se não houvesse projeto Rust algum.

Este repositório já traz a solução em `.vscode/settings.json`: ela aponta o
rust-analyzer para as crates do contrato de forma explícita, via
`rust-analyzer.linkedProjects`:

```jsonc
{
  "rust-analyzer.linkedProjects": [
    "./contracts/certificate-registry/Cargo.toml",
    "./contracts/certificate-registry/meta/Cargo.toml"
  ]
}
```

Para fazer funcionar:

1. Instale a extensão **rust-analyzer** (o VS Code vai recomendá-la — veja o
   `.vscode/extensions.json`).
2. Abra a pasta **raiz do repositório** no VS Code (não uma subpasta).
3. Rode **Command Palette → "rust-analyzer: Restart Server"** (ou recarregue a
   janela). O primeiro carregamento roda `cargo metadata` e indexa a crate —
   dê um minuto a ele.

> Se ainda assim não aparecer nada, abra **Output → rust-analyzer** e leia o log.
> A causa mais comum é uma versão do `klever-sc` que não casa com o seu
> toolchain — alinhe o `contracts/certificate-registry/Cargo.toml` com o
> `~/klever-sdk/ksc --version` (veja [`03-build-test-deploy-pt-BR.md`](03-build-test-deploy-pt-BR.md)).

---

Próximo: [`02-smart-contract-pt-BR.md`](02-smart-contract-pt-BR.md)
