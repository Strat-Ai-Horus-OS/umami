# Strat Analytics — Fork operacional do Umami

Fork white-label do [umami](https://github.com/umami-software/umami) para a operação Strat
(multi-domínio, multi-cliente, multi-produto), mantido **sincronizável com o upstream oficial**.

> Base do fork: **umami v3.1.0** (Next 16 · React 19 · Prisma 7 · Postgres/ClickHouse).
> Org: `Strat-Ai-Horus-OS/umami` · Deploy: Easypanel (projeto `ferramentas`, build via GitHub).

---

## 🔱 Regra de ouro: white-label por camadas

Quanto mais a gente mexe no core do umami, mais dolorido fica puxar a próxima versão oficial.
Por isso **toda customização fica concentrada em pontos de baixo conflito de merge**:

| Camada | Onde mexer | Conflito no update |
|---|---|---|
| Config | `.env`, variáveis (`UMAMI_APP_NAME`, etc.) | **Zero** |
| Assets | `public/` (logo, favicon, manifest, OG) | **Zero** |
| Tema | CSS variables / tokens de cor | Mínimo |
| Features novas | **arquivos novos** (não editar core) | Mínimo |
| Core | componentes/rotas existentes do umami | **Alto — evitar** |

**Nunca** edite um arquivo do core se der pra resolver por ENV, asset, ou arquivo novo.

---

## 🌿 Modelo de branches

```
origin   = github.com/Strat-Ai-Horus-OS/umami   (nosso fork)
upstream = github.com/umami-software/umami        (oficial)

master  → espelho do upstream. NÃO commitar aqui. Só serve pra sincronizar.
strat   → nossa branch de produção. Todo código Strat vive aqui.
          Deploy do Easypanel aponta pra ESTA branch.
```

---

## 🔄 Atualizar a partir do umami oficial

```bash
# 1. Atualiza o espelho
git checkout master
git fetch upstream
git merge --ff-only upstream/master        # master nunca diverge → ff sempre passa
git push origin master

# 2. Traz as novidades pra nossa branch
git checkout strat
git rebase master                          # reaplica nossos commits por cima do upstream
#   (resolva conflitos — devem ser raros se seguirmos as camadas)
git push --force-with-lease origin strat   # dispara o auto-deploy no Easypanel
```

Para fixar numa release estável em vez do topo do master, use a tag:
`git rebase v3.1.0` (troque pela tag desejada — `git tag --sort=-creatordate | head`).

---

## 🚀 Deploy (Easypanel · projeto `ferramentas`)

- Serviço `umami` → trocar source de `image` para **GitHub** → `Strat-Ai-Horus-OS/umami`, branch `strat`, auto-deploy ON.
- Banco `umami-db` (Postgres 17) permanece o mesmo. **Backup antes do primeiro deploy do fork.**
- ENV atual preservada: `DATABASE_TYPE=postgresql`, `DATABASE_URL=...@ferramentas_umami-db:5432/ferramentas`.

---

## 🧩 O que é nativo (NÃO forkar)

- **Vários domínios** → recurso "Websites". Cada domínio = 1 Website.
- **Clientes / produtos** → recurso "Teams". 1 Team por cliente/produto, com isolamento de acesso.
- **Relatórios pro cliente** → URL de share pública por Website.

O fork existe para **marca, design e features novas** — não para multi-domínio/multi-cliente.

---

## 🩹 Patches de core conhecidos (manter no rebase)

Mudanças mínimas no core que precisamos preservar ao sincronizar com o upstream:

- **`Dockerfile` (linha ~45)** — `--allow-build` inclui `@prisma/client,prisma` além de
  `@prisma/engines`. Sem isso, o pnpm ≥10 falha o build com `ERR_PNPM_IGNORED_BUILDS`
  (a fase `runner` roda sem o `pnpm-workspace.yaml`). Procure por `[STRAT patch]` no arquivo.
  Quando o upstream corrigir isso, é só aceitar a versão deles.

## 🗺️ Roadmap de camadas

- **C1 — White-label:** logo Strat, paleta (alinhar `Horus-OS/docs/DESIGN-SYSTEM.md`), nome, login, favicon, e-mails.
- **C2 — Operação multi-cliente:** convenção de Teams/Websites, onboarding de domínio semi-automático, carteira de clientes.
- **C3 — Integrações Strat:** webhooks → n8n (alertas), export → Supabase/Horus, relatório semanal via WhatsApp (ZAP Gateway), conector ClickUp.
- **C4 — Features de produto (avaliar):** funil/eventos custom, score de leads, comparativo entre clientes, resumo por IA.
