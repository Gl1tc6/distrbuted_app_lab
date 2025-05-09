FROM node:16-alpine AS builder

WORKDIR /app

# Kopiranje package.json i instalacija ovisnosti
COPY package*.json ./
RUN npm ci

# Kopiranje izvornog koda
COPY . .

# Sigurnosna provjera
RUN npm audit --production

# Build aplikacije
RUN npm run build

# Multi-stage build za produkcijsku sliku
FROM nginx:1.21-alpine

# Kopiranje build-a iz prethodne faze
COPY --from=builder /app/build /usr/share/nginx/html

# Kopiranje NGINX konfiguracije
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Izlaganje porta 80
EXPOSE 80

# Zdravstvena provjera
HEALTHCHECK --interval=30s --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Pokretanje NGINX servera
CMD ["nginx", "-g", "daemon off;"]
