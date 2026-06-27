# 05 — Desenvolvimento Assistido por IA

[English](./05-ai-assisted-development.md)

Use o **https://ai.klever.org** e o **Klever MCP** como assistente de
desenvolvimento enquanto você constrói. A IA é ótima para explicar, revisar,
depurar e gerar testes — mas você continua sendo a pessoa que verifica o
resultado.

> Foco iniciante: peça para a IA explicar o código que você não entende.
> Foco intermediário: peça revisões e ideias de testes.
> Foco avançado: integre o Klever MCP ao seu editor e automatize as verificações.

---

## O que é o `ai.klever.org` / Klever MCP?

- **`ai.klever.org`** — um assistente de IA que conhece a Klever: a Klever VM, o
  SDK e as ferramentas. Por isso suas respostas usam os comandos *corretos* da
  Klever (por exemplo, `ksc all build`, `koperator sc create`) em vez dos de
  outras redes.
- **Klever MCP** — um servidor Model Context Protocol que expõe o conhecimento da
  Klever e ferramentas on-chain para clientes de IA (como o Claude ou o seu IDE).
  Ele pode buscar na documentação, gerar a estrutura de projetos e consultar a
  rede por você.

> Por que importa: uma IA genérica costuma alucinar comandos de outras
> blockchains. Um assistente que conhece a Klever fundamenta suas respostas nas
> ferramentas e na documentação reais da Klever.

---

## Para que usar

### 1. Explicar código
Cole o contrato e peça uma explicação em linguagem simples.
→ Veja [`prompts/ai-explain-contract.md`](../prompts/ai-explain-contract.md)

### 2. Revisar contratos
Peça uma revisão focada em controle de acesso, storage e armadilhas da Klever VM.
→ Veja [`prompts/ai-review-contract.md`](../prompts/ai-review-contract.md)

### 3. Depurar erros
Cole o erro exato do `ksc`/`koperator`/`cargo` e peça as causas prováveis.
→ Veja [`prompts/ai-debug-contract.md`](../prompts/ai-debug-contract.md)

### 4. Gerar testes
> "Escreva testes `klever-sc-scenario` para o fluxo de revogação: emitir um
> certificado, revogá-lo e então afirmar que `isValid` retorna false e que
> revogar de novo dá erro."

### 5. Melhorar a documentação
> "Transforme a tabela de endpoints do `docs/02-smart-contract.md` em comentários
> de documentação acima de cada função no `lib.rs`, mantendo o texto conciso."

---

## Exemplos de prompts

**Explicar um único conceito**
> "Neste contrato Klever, o que o `MapMapper<u64, Certificate>` faz, e como ele é
> diferente do `SingleValueMapper`? Responda para quem está começando em Rust."

**Revisar um risco específico**
> "Revise o `issueCertificate` em busca de problemas de controle de acesso e
> overflow na Klever VM. Mostre apenas problemas reais e a linha exata a mudar."

**Depurar um erro de build**
> "O `ksc all build` falha com `<cole o erro>`. Como meu `Cargo.toml` usa o
> klever-sc 0.45, qual a causa e a correção mais prováveis?"

---

## Trabalhando bem com a IA

1. **Dê contexto** — cole o arquivo relevante, o comando exato e o erro exato.
   Perguntas vagas geram respostas vagas.
2. **Peça a menor mudança possível** — "mostre apenas as linhas que eu preciso
   editar."
3. **Sempre verifique** — rode de novo o `./scripts/test.sh` e o
   `./scripts/build.sh`. Trate a saída da IA como um rascunho, não uma garantia.
4. **Confira na documentação** — https://docs.klever.org é a fonte da verdade
   para sintaxe e ferramentas.

---

Próximo: [`06-class-challenges-pt-BR.md`](06-class-challenges-pt-BR.md)
