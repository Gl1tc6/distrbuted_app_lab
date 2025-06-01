FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM nginx:alpine
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nodeuser -G nodejs
COPY --from=builder --chown=nodeuser:nodejs /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
USER nodeuser
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]