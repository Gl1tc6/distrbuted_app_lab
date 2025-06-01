FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-service .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
WORKDIR /root/
COPY --from=builder --chown=appuser:appuser /app/auth-service .
USER appuser
EXPOSE 8080
CMD ["./auth-service"]