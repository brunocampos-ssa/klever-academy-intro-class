# 06 — Desafios da Aula

[English](./06-class-challenges.md)

Exercícios práticos, agrupados por nível. Escolha a trilha que combina com você —
ou faça as três. Cada desafio indica *o que mudar* e *onde*.

> Use o `ai.klever.org` para planejar e revisar suas mudanças (veja o `docs/05`),
> mas sempre rode o `./scripts/test.sh` e o `./scripts/build.sh` para verificar.

---

## 🟢 Iniciante

Objetivo: ficar à vontade rodando o projeto e fazendo edições seguras.

1. **Conectar uma carteira**
   - Rode `cd app/web && npm install && npm run dev`.
   - Conecte a Klever Web Extension e confirme que o seu endereço aparece.

2. **Mudar os rótulos do app**
   - No `app/web/src/App.tsx` e nos componentes, mude os títulos/rótulos (por
     exemplo, traduza-os, ou renomeie "Verify" para "Verificar certificado").
   - Veja a página recarregar sozinha (hot-reload).

3. **Consultar um certificado existente**
   - Faça o deploy do contrato (ou use um fornecido pelo instrutor).
   - Defina `CONTRACT_ADDRESS` em `app/web/src/klever.ts`.
   - Use o painel "Verify Certificate" para consultar o ID `1`.

✅ Sucesso: você conectou uma carteira e leu o status de um certificado.

---

## 🟡 Intermediário

Objetivo: modificar o contrato e os scripts com confiança.

1. **Adicionar expiração ao certificado**
   - Adicione um campo `expires_at: u64` à struct `Certificate` no `lib.rs`.
   - Aceite um argumento `validity_seconds` no `issueCertificate` e calcule
     `expires_at = issued_at + validity_seconds`.
   - Atualize o `isValid` para também retornar `false` quando
     `get_block_timestamp() > expires_at`.
   - Atualize a ABI (o `ksc all build` a regenera) e a exibição no frontend.

2. **Adicionar uma validação melhor**
   - Rejeite `metadata_uri` vazio.
   - Rejeite emitir para o endereço zero/vazio.
   - Adicione uma mensagem `require!` clara para cada caso.

3. **Melhorar o tratamento de estado no frontend**
   - No `CertificateViewer.tsx`, diferencie "não encontrado" de "revogado" e de
     "expirado" com mensagens diferentes.
   - Desabilite o botão de emitir enquanto uma transação está pendente (já está
     parcialmente feito — deixe a UX mais clara, adicione um toast de sucesso).

✅ Sucesso: os testes continuam passando e as novas regras aparecem na UI.

---

## 🔴 Avançado

Objetivo: melhorar arquitetura, segurança, testes e integrações.

1. **Adicionar papéis de emissor (múltiplos emissores)**
   - Troque o `issuer` único por um `SetMapper<ManagedAddress>` (um conjunto de
     emissores autorizados).
   - Adicione `addIssuer` / `removeIssuer` (só para o owner) e atualize a checagem
     de acesso.

2. **Adicionar emissão de certificados em lote**
   - Adicione `issueCertificateBatch` recebendo uma lista de `(aluno, curso, uri)`.
   - Cuidado com o gas: limite o tamanho do lote com um `require!` e documente o
     limite.

3. **Adicionar melhorias de índice/consulta**
   - Mantenha um índice por aluno (`MapMapper<ManagedAddress, ManagedVec<u64>>`)
     para conseguir listar todos os certificados de um aluno.
   - Adicione uma view `getCertificatesByStudent(student)`.

4. **Adicionar testes mais fortes**
   - Cubra o fluxo de revogação, a expiração, as falhas de controle de acesso e os
     limites de lote com testes `klever-sc-scenario`.
   - Adicione um teste negativo de que um não-emissor não consegue adicionar
     emissores.

✅ Sucesso: um contrato mais rico e seguro, com cobertura de testes significativa
e docs/frontend atualizados.

---

## Ideias extras (stretch)

- Emita eventos mais ricos e se inscreva neles no frontend (auto-refresh).
- Adicione um pequeno backend usando `NodeWallet` que emite certificados a partir
  de um servidor.
- Escreva um cenário black-box `.scen.json` para o ciclo de vida completo.
