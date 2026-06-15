# Strat Analytics — Operação multi-cliente (Camada 2)

Como a Strat organiza domínios, produtos e clientes dentro do Strat Analytics,
usando os recursos **nativos** do umami (Websites + Teams) — sem fork de código.

> Tudo aqui é configuração/operação. O fork (white-label) é só a casca; a operação
> roda nos recursos nativos. Automação de onboarding em `strat/scripts/`.

---

## Conceitos nativos

- **Website** = 1 domínio rastreado (ex.: `pluginhub.com.br`, `stratacademy.ai`). Tem
  um `websiteId` (usado no script de tracking) e, opcionalmente, um `shareId` (relatório público).
- **Team** = grupo que compartilha websites. Serve pra isolar clientes/produtos e dar
  acesso (login) a quem é do cliente, sem ver os demais.
- **Share URL** = `/.../share/<shareId>` — relatório público, sem login. Entregável pro cliente.

---

## Modelo de organização Strat

```
Strat Analytics
├── Team "Strat — Interno"        → domínios próprios (strat.tec.br, academy, hub...)
├── Team "Cliente: PluginHub"     → pluginhub.com.br (+ subdomínios/produtos do cliente)
├── Team "Cliente: <Fulano>"      → domínios do cliente
└── ...
```

**Regras de nomenclatura:**
- Team de cliente: `Cliente: <Nome>` · Team interno: `Strat — <Área>`.
- Website `name`: `<Cliente/Produto> — <ambiente>` (ex.: `PluginHub — prod`). `domain`: o host puro.
- `shareId`: slug curto e estável por website (ex.: `pluginhub`) → vira a URL pública.

## Modelos de acesso do cliente (escolher por cliente)

1. **Só relatório (sem login)** — gera `shareId` e manda a URL pública. Mais simples; padrão p/ maioria.
2. **Self-service (com login)** — cria Team do cliente, convida o e-mail dele (vê só o que é dele).
   Use quando o cliente quer entrar e explorar sozinho.

Staff Strat: usuário admin participa de todos os Teams (ou é dono). Cliente: só no Team dele.

---

## Onboarding de um novo domínio

Automatizado em `strat/scripts/onboard-website.mjs` (cria o Website via API e devolve o snippet).
Ver `strat/scripts/README.md`. Fluxo manual equivalente:

1. (se cliente novo c/ login) criar Team `Cliente: <Nome>`.
2. criar Website (`name`, `domain`, `teamId?`, `shareId?`).
3. instalar o snippet no site do cliente:
   ```html
   <script defer src="https://ferramentas-umami.hupeii.easypanel.host/script.js"
           data-website-id="<WEBSITE_ID>"></script>
   ```
4. (opcional) entregar a URL pública: `https://ferramentas-umami.hupeii.easypanel.host/share/<shareId>`.

---

## Domínio do painel

Hoje: `ferramentas-umami.hupeii.easypanel.host`. Recomendado migrar p/ domínio próprio
(ex.: `analytics.strat.tec.br`) — ajusta-se em Easypanel (add domain) + `script.js` passa a
servir nesse host. Snippets usam o host do painel; definir o domínio final ANTES de distribuir snippets.
