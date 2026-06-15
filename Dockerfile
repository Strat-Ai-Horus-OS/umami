ARG NODE_IMAGE_VERSION="22-alpine"

# Install dependencies only when needed
FROM node:${NODE_IMAGE_VERSION} AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
# [STRAT patch] copiar pnpm-workspace.yaml: ele carrega onlyBuiltDependencies/
# ignoredBuiltDependencies. Sem esse arquivo, o pnpm >=11 (que o Easypanel
# instala) aborta o install com ERR_PNPM_IGNORED_BUILDS por não saber
# classificar os build scripts (prisma, esbuild, sharp, @swc/core, etc.).
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN npm install -g pnpm@10
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:${NODE_IMAGE_VERSION} AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
COPY docker/proxy.ts ./src

ARG BASE_PATH

ENV BASE_PATH=$BASE_PATH
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_URL="postgresql://user:pass@localhost:5432/dummy"

RUN npm run build-docker

# Production image, copy all the files and run next
FROM node:${NODE_IMAGE_VERSION} AS runner
WORKDIR /app

ARG PRISMA_VERSION="7.3.0"
ARG NODE_OPTIONS

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS=$NODE_OPTIONS

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
RUN set -x \
    && apk add --no-cache curl \
    && npm install -g pnpm@10

# Build artifacts primeiro. O standalone do Next traz seu PRÓPRIO node_modules.
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/generated ./generated

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Script dependencies — instaladas POR ÚLTIMO, sobre o node_modules do standalone.
# [STRAT patch] Ordem invertida vs. upstream: instalar depois do standalone evita
# o conflito do COPY do Docker tentando sobrepor dirs do node_modules do pnpm
# (ex.: "cannot replace directory node_modules/pg with file"). O pnpm escreve o
# estado FINAL do node_modules.
# [STRAT patch] --config.node-linker=hoisted: node_modules real (sem symlink .pnpm),
# senão o semver não resolve no start (ERR_MODULE_NOT_FOUND em check-db.js).
# [STRAT patch] --allow-build repetido por pacote: pnpm >=10 trata build-script
# ignorado como erro fatal e NÃO aceita lista por vírgula.
RUN pnpm --config.node-linker=hoisted --allow-build=@prisma/engines --allow-build=prisma --allow-build=@prisma/client add npm-run-all dotenv chalk semver \
    prisma@${PRISMA_VERSION} \
    @prisma/client@${PRISMA_VERSION} \
    @prisma/adapter-pg@${PRISMA_VERSION}

USER nextjs

EXPOSE 3000

ENV HOSTNAME=0.0.0.0
ENV PORT=3000

CMD ["pnpm", "start-docker"]