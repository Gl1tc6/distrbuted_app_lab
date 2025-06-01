FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run lint
RUN npm audit --production

FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nodeuser -G nodejs
WORKDIR /app
COPY --from=builder --chown=nodeuser:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=nodeuser:nodejs /app/src /app/src
COPY --from=builder --chown=nodeuser:nodejs /app/package.json /app/

ENV NODE_ENV=production
USER nodeuser
EXPOSE 3000
CMD ["node", "--no-deprecation", "--no-warnings", "src/index.js"]