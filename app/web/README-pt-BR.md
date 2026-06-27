# Registro de Certificados — App Web

[English](./README.md)

Um pequeno frontend em React + TypeScript que se conecta à Klever Blockchain com
o **Klever Connect** e conversa com o contrato Registro de Certificados.

Faz parte do repositório **`klever-academy-intro-class`**.

## O que ele demonstra

1. **Conectar uma carteira** com a Klever Web Extension (`BrowserWallet`).
2. **Mostrar a conta conectada** (o endereço).
3. **Emitir um certificado** (uma transação assinada).
4. **Consultar um certificado** por ID (uma leitura gratuita).
5. **Mostrar o status do certificado** (válido / revogado / não encontrado).

## Onde a configuração acontece

➡️ **Tudo o que você precisa conectar fica em [`src/klever.ts`](src/klever.ts):**

| Configuração | O que mudar |
| --- | --- |
| `NETWORK` | `mainnet` / `testnet` / `devnet` (use `testnet` na aula) |
| `CONTRACT_ADDRESS` | o endereço `klv1...` do `./scripts/deploy.sh` |
| `ABI` | importada de `contracts/certificate-registry/abi/...` |

## Rodar localmente

```bash
cd app/web
npm install
npm run dev
```

Depois abra a URL que aparecer e confirme que a **Klever Web Extension** está
instalada e desbloqueada.

> Foco iniciante: mude rótulos e teste o botão de conectar.
> Foco intermediário: melhore o tratamento de estados de carregamento/erro.
> Foco avançado: inscreva-se nos eventos do contrato e atualize o viewer
> automaticamente.

## Observações

- Este app é intencionalmente mínimo e **não está pronto para produção** — sem
  framework de estilo, sem roteador, sem suíte de testes. Ele foi feito para
  clareza didática.
- A chave privada nunca entra neste app: a assinatura acontece dentro da extensão.
- Veja [`docs/04-klever-connect-pt-BR.md`](../../docs/04-klever-connect-pt-BR.md)
  para a explicação completa do Klever Connect.
