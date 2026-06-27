# Registro de Certificados — Smart Contract

[English](./README.md)

Um smart contract Klever VM mínimo e amigável para sala de aula que guarda
certificados acadêmicos on-chain. Faz parte do repositório
**`klever-academy-intro-class`**.

## O que ele faz

| Ação | Quem | Endpoint |
| --- | --- | --- |
| Emitir um certificado | Só o emissor | `issueCertificate(student, course, metadata_uri)` |
| Revogar um certificado | Só o emissor | `revokeCertificate(id)` |
| Trocar o emissor | Só o owner | `setIssuer(new_issuer)` |
| Ler um certificado | Qualquer um | `getCertificate(id)` (view) |
| Validar um certificado | Qualquer um | `isValid(id)` (view) |
| Contar certificados | Qualquer um | `getTotalCertificates()` (view) |
| Ler o emissor | Qualquer um | `getIssuer()` (view) |

## Modelo de dados

Cada certificado é uma struct `Certificate`:

```rust
struct Certificate {
    id: u64,                 // sequencial, atribuído pelo contrato
    student: ManagedAddress, // de quem é o certificado
    course: ManagedBuffer,   // nome do curso / da turma
    metadata_uri: ManagedBuffer, // hash ou URI para os detalhes off-chain
    issued_at: u64,          // timestamp do bloco
    revoked: bool,           // flag de revogação (o histórico é preservado)
}
```

Storage:

- `issuer` → `SingleValueMapper<ManagedAddress>`
- `lastId` → `SingleValueMapper<u64>` (contador autoincremental)
- `certificates` → `MapMapper<u64, Certificate>`

## Arquivos

```txt
certificate-registry/
├── Cargo.toml          # manifesto da crate do contrato
├── src/lib.rs          # o contrato (leia este primeiro, de cima para baixo)
├── tests/              # testes cargo usando klever-sc-scenario
├── meta/               # ferramenta de build/ABI (raramente editada)
├── abi/                # ABI de referência usada pelo frontend + scripts
└── README.md           # este arquivo
```

## Build e testes

A partir da raiz do repositório:

```bash
./scripts/build.sh   # ~/klever-sdk/ksc all build  -> output/*.wasm + ABI
./scripts/test.sh    # cargo test
```

> Ajuste a versão do `klever-sc` no `Cargo.toml` para casar com o seu toolchain
> instalado (`~/klever-sdk/ksc --version`). Veja `docs/03-build-test-deploy-pt-BR.md`.

Para a explicação completa, veja [`docs/02-smart-contract-pt-BR.md`](../../docs/02-smart-contract-pt-BR.md).
