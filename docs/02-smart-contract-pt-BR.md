# 02 — O Smart Contract

[English](./02-smart-contract.md)

Uma explicação amigável para iniciantes do contrato Registro de Certificados
(`contracts/certificate-registry/src/lib.rs`).

---

## Propósito

Guardar certificados acadêmicos **on-chain** para que qualquer pessoa possa
verificá-los sem confiar em um servidor central. Um **emissor** (por exemplo, a
Klever Academy) cria certificados para os alunos; **qualquer pessoa** pode lê-los
e validá-los.

---

## Anotações: as macros que definem o comportamento

No `klever-sc`, você não chama uma função especial para "registrar um endpoint".
Você **anota** um método, e as macros do framework o transformam no tipo certo de
membro do contrato. Esses atributos são o "dicionário" de todo o contrato — cada
exemplo abaixo foi tirado diretamente do `src/lib.rs`.

| Anotação | Categoria | O que marca | Neste contrato |
| --- | --- | --- | --- |
| `#[klever_sc::contract]` | Contrato | a trait cujo conteúdo vira o contrato publicado | `trait CertificateRegistry` |
| `#[init]` | Ciclo de vida | o construtor — roda **uma vez** no deploy | `init()` |
| `#[upgrade]` | Ciclo de vida | roda no upgrade do contrato (mantém o estado) | `upgrade()` |
| `#[endpoint(name)]` | **Escrita** | função pública que altera estado (uma transação assinada) | `issueCertificate`, `revokeCertificate`, `setIssuer` |
| `#[view(name)]` | **Leitura** | consulta pública somente leitura (gratuita, sem carteira) | `getCertificate`, `isValid`, `getTotalCertificates`, `getIssuer` |
| `#[storage_mapper("key")]` | **Storage** | um acessor de estado persistente guardado sob `"key"` | `issuer`, `lastId`, `certificates` |
| `#[only_owner]` | Controle de acesso | restringe a chamada ao owner/quem fez o deploy | `setIssuer` |
| `#[event("name")]` | Eventos | um log estruturado on-chain | `certificateIssued`, `certificateRevoked` |
| `#[indexed]` | Eventos | marca um parâmetro do evento como **tópico pesquisável** | `id`, `student` nos eventos |
| `#[type_abi]` + `#[derive(...)]` | Tipos | tornam uma struct própria armazenável + visível na ABI (veja *Codificação e ABI* abaixo) | a struct `Certificate` |
| *(sem anotação)* | Auxiliar privado | um método comum da trait — interno, **não** entra na ABI | `require_caller_is_issuer`, `get_certificate_or_panic` |

**Modelo mental de web:** `#[endpoint]` ≈ um `POST` (altera estado, custa taxa),
`#[view]` ≈ um `GET` (leitura gratuita), `#[storage_mapper]` ≈ uma tabela de banco
que vive on-chain.

> Repare nos **dois nomes**: `#[endpoint(issueCertificate)]` fica escrito acima da
> função Rust `fn issue_certificate(...)`. O argumento da anotação
> (`issueCertificate`, em camelCase) é o **nome público na ABI** que os scripts e o
> frontend chamam; a função Rust mantém o snake_case idiomático. O mesmo vale para
> `#[view(name)]`, `#[storage_mapper("key")]` e `#[event("name")]`.

> Foco iniciante: endpoint é escrita, view é leitura — esse é o mapa inteiro.
> Foco intermediário: a `"key"` de um `storage_mapper` é a chave literal de storage on-chain; o tipo de retorno (`SingleValueMapper`, `MapMapper`) define o formato dos dados.
> Foco avançado: métodos sem anotação são auxiliares privados, fora da ABI — use-os para concentrar a lógica de controle de acesso em um só lugar.

---

## Modelo de dados

Cada certificado é uma struct:

```rust
struct Certificate {
    id: u64,                      // ID sequencial atribuído pelo contrato
    student: ManagedAddress,      // de quem é o certificado
    course: ManagedBuffer,        // nome do curso / da turma
    metadata_uri: ManagedBuffer,  // hash ou URI para os detalhes off-chain
    issued_at: u64,               // timestamp do bloco
    revoked: bool,                // flag de revogação
}
```

---

## Codificação e ABI (os atributos acima da struct)

No `src/lib.rs`, a struct é precedida por dois atributos:

```rust
#[type_abi]
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, Clone, PartialEq, Debug)]
pub struct Certificate<M: ManagedTypeApi> { /* ... */ }
```

Uma blockchain só guarda **bytes**. Por isso a struct precisa de código gerado
automaticamente para se transformar em bytes (e voltar), além de uma descrição
para que ferramentas off-chain a entendam. É exatamente isso que essas duas
linhas oferecem — você escreve uma linha, o compilador escreve todo o trabalho
repetitivo.

**`#[type_abi]`** exporta o *formato* da struct (nomes dos campos + tipos) para a
**ABI** do contrato (o JSON em `abi/`). Graças a ele, o Klever Connect e os
scripts sabem que um `Certificate` tem um `id: u64`, um endereço `student` e
assim por diante, e conseguem decodificar automaticamente o que o contrato
retorna.

**`#[derive(...)]`** implementa automaticamente um conjunto de capacidades:

| Trait derivada | O que dá à struct | Por que é necessária |
| --- | --- | --- |
| `TopEncode` / `TopDecode` | codifica/decodifica o valor **inteiro** como bytes | como um `Certificate` é guardado e retornado de forma autônoma |
| `NestedEncode` / `NestedDecode` | codifica/decodifica quando o valor está **dentro** de outra coisa (um campo, um item de lista) | o codec escolhe "nested" quando um `Certificate` está embutido em uma estrutura maior |
| `Clone` | fazer uma cópia em memória | para a lógica do contrato duplicar o valor |
| `PartialEq` | comparar dois com `==` | útil na lógica e, principalmente, nos testes |
| `Debug` | imprimir com `{:?}` | saída legível ao testar/depurar |

> Por que dois pares de codificação? Codificar um valor *sozinho* (top-level) é
> diferente de codificá-lo *embutido* em um bloco maior (nested, onde os metadados
> de tamanho importam). Você deriva os dois para o framework sempre escolher o
> correto.

Um modelo mental útil: `#[derive(...)]` é como o `JSON.stringify` / `JSON.parse`
da blockchain, gerado automaticamente — e o `#[type_abi]` é como exportar o tipo
TypeScript para o frontend saber o formato.

> Foco iniciante: "esses atributos deixam a struct ser guardada on-chain e lida pelo nosso app."
> Foco intermediário: repare na divisão top-vs-nested e que a ABI faz a ponte Rust ↔ TypeScript.
> Foco avançado: são derive macros expandidas em tempo de compilação; conheça o formato binário (a codificação nested adiciona metadados de tamanho) ao otimizar o storage.

---

## Storage

O contrato mantém três pedaços de estado persistente:

| Mapper | Tipo | Significado |
| --- | --- | --- |
| `issuer` | `SingleValueMapper<ManagedAddress>` | quem pode emitir/revogar |
| `lastId` | `SingleValueMapper<u64>` | contador autoincremental |
| `certificates` | `MapMapper<u64, Certificate>` | o registro em si |

> Pense no `MapMapper` como uma tabela chave→valor que vive na blockchain.

---

## Endpoints (escritas) e views (leituras)

| Nome | Tipo | Acesso | Propósito |
| --- | --- | --- | --- |
| `init` | construtor | quem faz deploy | roda uma vez; define issuer = quem fez o deploy |
| `issueCertificate` | endpoint | emissor | cria um certificado, retorna o ID |
| `revokeCertificate` | endpoint | emissor | marca `revoked = true` |
| `setIssuer` | endpoint | owner | passa o papel de emissor para outro endereço |
| `getCertificate` | view | qualquer um | lê a struct completa pelo ID |
| `isValid` | view | qualquer um | `true` se existe e não foi revogado |
| `getTotalCertificates` | view | qualquer um | quantos foram emitidos |
| `getIssuer` | view | qualquer um | endereço do emissor atual |

**Endpoints** alteram o estado e exigem uma transação assinada (e taxas).
**Views** são leituras gratuitas — não precisam de carteira.

---

## Eventos

O contrato emite eventos para que apps/indexadores off-chain possam reagir:

```rust
#[event("certificateIssued")]
fn certificate_issued_event(&self, #[indexed] id: u64, #[indexed] student: &ManagedAddress);

#[event("certificateRevoked")]
fn certificate_revoked_event(&self, #[indexed] id: u64);
```

Campos `#[indexed]` viram tópicos pesquisáveis — por exemplo, "me mostre todos os
certificados do aluno X".

---

## Controle de acesso

Duas proteções mantêm tudo seguro:

- `require_caller_is_issuer()` — usada por `issueCertificate` / `revokeCertificate`.
- `#[only_owner]` em `setIssuer` — só quem fez o deploy/o owner pode transferir o papel.

`require!(condição, "mensagem")` aborta a transação inteira com um erro legível se
a condição for falsa. Nada fica gravado pela metade.

---

## Explicação amigável para iniciantes

Leia `src/lib.rs` de cima para baixo. Ele está organizado em seis seções
identificadas:

1. **Inicialização** — `init` / `upgrade`.
2. **Endpoints de escrita** — emitir, revogar, definir emissor.
3. **Views de leitura** — buscar, validar, contar.
4. **Storage** — os mappers acima.
5. **Eventos** — emitido / revogado.
6. **Auxiliares privados** — as checagens de controle de acesso.

Acompanhe o ciclo de vida de um certificado:

```txt
o emissor chama issueCertificate(aluno, curso, uri)
        │
        ▼
exige caller == issuer   ──falha──▶ a transação é revertida
        │ ok
        ▼
id = lastId + 1
grava Certificate{...}
lastId = id
emite certificateIssued(id, aluno)
        │
        ▼
qualquer um chama isValid(id) ──▶ true   (até ser revogado)
```

---

Próximo: [`03-build-test-deploy-pt-BR.md`](03-build-test-deploy-pt-BR.md)
