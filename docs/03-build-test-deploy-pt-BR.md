# 03 — Build, Testes e Deploy

[English](./03-build-test-deploy.md)

Como levar o contrato do código-fonte até um endereço ativo na Klever.

> Ajuste a rede, a carteira e o caminho do contrato conforme o seu ambiente.

---

## Build

```bash
./scripts/build.sh
```

Por baixo dos panos, isso roda o comando de build **correto** da Klever:

```bash
~/klever-sdk/ksc all build
```

A saída vai para `contracts/certificate-registry/output/`:

- `certificate-registry.wasm` — o bytecode publicável
- `certificate-registry.abi.json` — a ABI (usada pelo frontend/scripts)

> ❌ Não use `sc-meta all build`, `cargo build` nem `mxpy` — esses pertencem a
> outros ecossistemas. A Klever faz o build com o `ksc`.

### Requisitos do build e a nota sobre o link do wasm

Duas coisas que o build precisa, e uma arestinha que vale conhecer:

1. **O `ksc` descobre o contrato por um marcador `klever.json`** na pasta do
   contrato (`contracts/certificate-registry/klever.json`). Sem ele, o `ksc all
   build` imprime *"Found 0 contract crates"* e não faz nada silenciosamente — é
   o marcador que torna a pasta um contrato compilável.
2. **Um target wasm do Rust precisa estar instalado** — configurado uma vez no
   [`01-setup-pt-BR.md`](01-setup-pt-BR.md) (seção 3, "Adicione o target de build
   WebAssembly").
3. **No Rust 1.82+**, o próprio link do wasm pelo `ksc` pode falhar com
   `undefined symbol: mBufferNew` (o Rust parou de importar automaticamente
   símbolos wasm indefinidos, e o `ksc` instalado não passa `--import-undefined`).
   O `build.sh` **detecta isso e refaz o link automaticamente** da crate `wasm/`
   gerada com a flag correta — guardada em
   `contracts/certificate-registry/.cargo/config.toml` — então você ainda obtém
   um `output/certificate-registry.wasm` publicável. A correção limpa de longo
   prazo é atualizar o Klever SDK em https://install.klever.org quando uma versão
   tratar isso nativamente.

> O `build.sh` nunca reporta sucesso falso: se nenhum `.wasm` for produzido (nem
> pela alternativa), ele termina com erro em vez de imprimir "Build complete".

---

## Testes

```bash
./scripts/test.sh      # roda cargo test
```

Os testes rodam em uma **blockchain simulada** (`klever-sc-scenario`) — sem rede,
sem taxas e **sem etapa de build**. O harness de testes registra o objeto do
contrato Rust e o executa em processo, então você *não* precisa rodar o
`./scripts/build.sh` antes. Os testes incluídos cobrem deploy, emissão e controle
de acesso. Adicione mais à medida que você estender o contrato (veja o doc de
desafios).

### O proxy tipado (e como regenerá-lo)

Os testes chamam o contrato por meio de um **proxy tipado** —
`src/certificate_registry_proxy.rs`, exposto como o módulo
`certificate_registry_proxy`. Ele é gerado a partir da ABI do contrato e oferece
métodos com tipos seguros, como `.issue_certificate(...)` e `.is_valid(id)`, em
vez de chamadas "soltas" baseadas em strings. Ele está versionado no repositório,
então o `cargo test` funciona de imediato.

**Se você mudar a interface pública do contrato** (adicionar/renomear um endpoint,
mudar o tipo de um argumento), o proxy fica desatualizado e os testes param de
compilar. Regenere-o:

```bash
# A partir da meta crate do contrato:
cd contracts/certificate-registry/meta
cargo run -- proxy                 # escreve em ../output/proxy.rs
cp ../output/proxy.rs ../src/certificate_registry_proxy.rs   # atualiza a cópia versionada
```

> Um proxy desatualizado aparece como "cannot find method ..." ou um erro de tipo
> nos testes logo após você editar os endpoints — esse é o sinal para regenerá-lo.
> A mesma ABI também alimenta o frontend, então rode o build
> (`./scripts/build.sh`) para atualizar a `abi/` quando mudar a interface.

---

## Deploy

1. Garanta que sua carteira de testnet tem KLV (veja o passo do faucet em
   `docs/01-setup-pt-BR.md`).
2. Configure o `.env` (copie de `.env.example`) com `KEY_FILE`, `KLEVER_NODE`.
3. Faça o deploy:

```bash
./scripts/deploy.sh
```

Por baixo dos panos:

```bash
# Ajuste a rede, o KEY_FILE e os caminhos conforme o seu ambiente.
KLEVER_NODE=https://node.testnet.klever.org \
  ~/klever-sdk/koperator \
  --key-file="$KEY_FILE" \
  sc create \
  --wasm="contracts/certificate-registry/output/certificate-registry.wasm" \
  --upgradeable --readable --payable \
  --await --sign --result-only
```

O JSON de resultado inclui o novo **endereço do contrato** (`klv1...`). Copie-o.

---

## Depois do deploy: conecte tudo

Coloque o endereço em todos os lugares onde as ferramentas esperam por ele:

```bash
# .env (para os scripts)
CONTRACT_ADDRESS=klv1seu_endereco_do_contrato...
```

```ts
// app/web/src/klever.ts (para o frontend)
export const CONTRACT_ADDRESS = "klv1seu_endereco_do_contrato...";
```

---

## Verifique o deploy

Um contrato recém-publicado está **vazio**, então consultar antes de emitir não
retorna nada útil. Faça o ciclo completo: **emita um certificado e depois leia de
volta.**

Primeiro, diga aos scripts com qual contrato falar — defina `CONTRACT_ADDRESS` no
`.env` (recomendado) ou passe inline em cada comando:

```bash
# .env  (carregado automaticamente pelos scripts)
CONTRACT_ADDRESS=klv1seu_endereco_do_contrato...
```

**1) Emita um certificado** — uma escrita, então precisa da carteira emissora.
Quem fez o deploy é o emissor (veja o `init`), então use o mesmo `KEY_FILE` do
deploy:

```bash
./scripts/issue-certificate.sh klv1endereco_do_aluno... "Klever Academy Intro Class" "ipfs://cid"
```

O `returnData` do resultado é o **id** do novo certificado (o primeiro é `1`).

**2) Consulte de volta** — uma leitura gratuita, sem carteira:

```bash
./scripts/query-certificate.sh 1
```

O `isValid` deve retornar `true` e o `getCertificate` deve retornar os campos
guardados. Se os dois responderem, seu contrato está no ar e funcionando.

> Os scripts leem `CONTRACT_ADDRESS` (e `KEY_FILE`, `KLEVER_NODE`) do `.env`.
> Uma variável de ambiente inline (ex.: `CONTRACT_ADDRESS=klv1... ./scripts/...`)
> tem precedência sobre o `.env` naquela execução.

Você também pode ver no explorer:

- Testnet: `https://testnet.kleverscan.org/smart-contract/<endereco_do_contrato>`

---

## Problemas comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| `ksc: not found` | SDK não instalado / caminho errado | rode o instalador de novo; defina `KLEVER_SDK_PATH` |
| Build falha na versão do `klever-sc` | versões incompatíveis | alinhe as versões no `Cargo.toml` com `ksc --version` |
| Deploy: "insufficient balance" | sem KLV de testnet | use o faucet (docs/01) |
| Deploy: erro de "signature/key" | `KEY_FILE` errado | aponte o `KEY_FILE` para o seu PEM |
| Consulta retorna vazio | ID ou endereço do contrato errado | confirme o `CONTRACT_ADDRESS` e se o certificado existe |
| Frontend não lê a ABI | caminho mudou | verifique o import da ABI no `klever.ts` |

---

Próximo: [`04-klever-connect-pt-BR.md`](04-klever-connect-pt-BR.md)
