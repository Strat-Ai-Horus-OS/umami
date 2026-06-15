#!/usr/bin/env node
// [STRAT] Onboarding de um novo domínio no Strat Analytics (umami).
// Cria o Website via API (opcionalmente um Team e/ou share público) e imprime o
// snippet de tracking. NÃO faz parte do build do umami — ferramenta operacional.
//
// Uso:
//   UMAMI_URL=https://ferramentas-umami.hupeii.easypanel.host \
//   UMAMI_USER=admin UMAMI_PASS=*** \
//   node strat/scripts/onboard-website.mjs --name "PluginHub — prod" --domain pluginhub.com.br [--share pluginhub] [--new-team "Cliente: PluginHub"] [--team-id <uuid>]

const args = parseArgs(process.argv.slice(2));
const URL_BASE = (process.env.UMAMI_URL || '').replace(/\/$/, '');
const USER = process.env.UMAMI_USER;
const PASS = process.env.UMAMI_PASS;

if (!URL_BASE || !USER || !PASS) {
  fail('Defina UMAMI_URL, UMAMI_USER e UMAMI_PASS no ambiente.');
}
if (!args.name || !args.domain) {
  fail('Argumentos obrigatórios: --name "<nome>" --domain <host>');
}

const token = await login();
let teamId = args['team-id'] || null;

if (args['new-team']) {
  const team = await api('POST', '/api/teams', { name: args['new-team'] }, token);
  teamId = team.id;
  console.log(`✓ Team criado: "${team.name}" (${team.id}) · accessCode: ${team.accessCode}`);
}

const website = await api(
  'POST',
  '/api/websites',
  {
    name: args.name,
    domain: args.domain,
    ...(args.share ? { shareId: args.share } : {}),
    ...(teamId ? { teamId } : {}),
  },
  token,
);

console.log(`\n✓ Website criado: "${website.name}" (${website.id})`);
console.log('\n--- snippet de tracking (cole no <head> do site) ---');
console.log(
  `<script defer src="${URL_BASE}/script.js" data-website-id="${website.id}"></script>`,
);
if (website.shareId) {
  console.log(`\n--- relatório público ---\n${URL_BASE}/share/${website.shareId}`);
}

// ---------- helpers ----------
async function login() {
  const res = await fetch(`${URL_BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: USER, password: PASS }),
  });
  if (!res.ok) fail(`Login falhou (${res.status}): ${await res.text()}`);
  const { token } = await res.json();
  if (!token) fail('Login não retornou token.');
  return token;
}

async function api(method, path, body, token) {
  const res = await fetch(`${URL_BASE}${path}`, {
    method,
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) fail(`${method} ${path} falhou (${res.status}): ${await res.text()}`);
  return res.json();
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      const key = argv[i].slice(2);
      const val = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : true;
      out[key] = val;
    }
  }
  return out;
}

function fail(msg) {
  console.error(`✗ ${msg}`);
  process.exit(1);
}
