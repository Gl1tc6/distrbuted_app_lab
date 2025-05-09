FROM node:16-alpine AS builder

WORKDIR /app

# Kopiranje package.json i instalacija ovisnosti
COPY package*.json ./
COPY .npmrc ./
RUN npm ci --only=production

# Kopiranje izvornog koda
COPY . .

# Statička analiza koda i sigurnosno testiranje
RUN npm run lint
RUN npm audit --production

# Multi-stage build za minimiziranje površine napada
FROM node:16-alpine

# Korištenje neprivilegirane korisničke uloge
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nodeuser -G nodejs

WORKDIR /app

# Kopiranje samo potrebnih datoteka iz prethodne faze
COPY --from=builder --chown=nodeuser:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=nodeuser:nodejs /app/src /app/src
COPY --from=builder --chown=nodeuser:nodejs /app/package*.json /app/

# Konfiguracija sigurnosti
ENV NODE_ENV=production

# Kreiranje direktorija za privremene datoteke i logove
RUN mkdir -p /app/logs /app/tmp