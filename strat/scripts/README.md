# strat/scripts — ferramentas operacionais

Scripts que NÃO fazem parte do umami nem do build (excluídos via `.dockerignore`).
Rodam contra a API do Strat Analytics em produção.

## onboard-website.mjs

Cria um Website (e opcionalmente um Team e/ou relatório público) e imprime o snippet de tracking.

```bash
UMAMI_URL=https://ferramentas-umami.hupeii.easypanel.host \
UMAMI_USER=<admin> UMAMI_PASS=<senha> \
node strat/scripts/onboard-website.mjs \
  --name "PluginHub — prod" \
  --domain pluginhub.com.br \
  --share pluginhub \          # opcional: gera relatório público /share/pluginhub
  --new-team "Cliente: PluginHub"   # opcional: cria Team e vincula o website
  # ou --team-id <uuid> para vincular a um Team existente
```

Requer Node 18+ (usa `fetch` nativo). Saída: id do website + `<script>` pronto pra colar
e, se houver `--share`, a URL pública do relatório.

Ver `strat/OPERACAO.md` para o modelo de organização (Teams/Websites/acesso).
