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
| Node.js 18+ | rodar o frontend e o `interact.ts` | https://nodejs.org |
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

## 3. Confira seu ambiente

```bash
# Ferramentas Klever
~/klever-sdk/ksc --version
~/klever-sdk/koperator --version

# Rust
rustc --version
cargo --version

# Node.js (precisa ser 18+)
node --version
npm --version

# Auxiliares usados pelos scripts
jq --version
curl --version
```

Se algum comando retornar "not found", instale essa ferramenta antes de
continuar.

---

## 4. Requisito de Node.js para o frontend

O app web usa Vite + React e precisa de **Node.js 18 ou mais recente**.

```bash
cd app/web
npm install
npm run dev   # sobe o servidor de desenvolvimento (tudo bem se o contrato ainda não foi publicado)
```

---

## 5. Preparação da carteira e da rede

Na aula usamos a **testnet** (gratuita, segura, descartável).

1. Instale e desbloqueie a **Klever Web Extension**.
2. Crie uma carteira nova (NÃO reaproveite uma carteira com fundos reais).
3. Troque a rede da extensão para **Testnet**.
4. Pegue KLV de teste no faucet da testnet para pagar as taxas de deploy:

```bash
# Troque <seu_endereco> pelo seu endereço klv1...
curl -X POST \
  "https://api.testnet.klever.org/v1.0/transaction/send-user-funds/<seu_endereco>" \
  -H "Content-Type: application/json"
```

5. Para os scripts de CLI, exporte a chave da carteira como um arquivo PEM e
   aponte os scripts para ele via `KEY_FILE` no `.env` (veja `.env.example`).

> ⚠️ Nunca faça commit de um arquivo de chave ou de uma seed phrase. O
> `.gitignore` já exclui `*.pem`, mas mantenha o cuidado.

---

## 6. Configuração do editor (VS Code + rust-analyzer)

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
