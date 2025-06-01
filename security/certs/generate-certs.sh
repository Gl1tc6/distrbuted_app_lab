#!/bin/bash

# Generate TLS certificates for the application
echo "Generating TLS certificates..."

# Create CA private key
openssl genrsa -out ca.key 4096

# Create CA certificate
openssl req -new -x509 -key ca.key -sha256 -subj "/C=HR/ST=Zagreb/L=Zagreb/O=DynamicSoft/CN=DynamicSoft CA" -days 3650 -out ca.crt

# Create server private key
openssl genrsa -out server.key 4096

# Create certificate signing request
openssl req -new -key server.key -out server.csr -config <(
cat <<EOF
[req]
default_bits = 4096
prompt = no
distinguished_name = req_distinguished_name
req_extensions = req_ext

[req_distinguished_name]
C=HR
ST=Zagreb
L=Zagreb
O=DynamicSoft
CN=dynamicsoft.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = dynamicsoft.local
DNS.2 = frontend
DNS.3 = backend
DNS.4 = auth-service
DNS.5 = *.dynamicsoft.local
IP.1 = 127.0.0.1
EOF
)

# Generate server certificate
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extensions req_ext -extfile <(
cat <<EOF
[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = dynamicsoft.local
DNS.2 = frontend
DNS.3 = backend
DNS.4 = auth-service
DNS.5 = *.dynamicsoft.local
IP.1 = 127.0.0.1
EOF
)

# Set appropriate permissions
chmod 600 *.key
chmod 644 *.crt

echo "Certificates generated successfully!"
echo "CA Certificate: ca.crt"
echo "Server Certificate: server.crt"
echo "Server Private Key: server.key"

# Create Kubernetes secret
echo "Creating Kubernetes TLS secret..."
kubectl create secret tls app-tls --cert=server.crt --key=server.key --dry-run=client -o yaml > tls-secret.yaml

echo "TLS secret YAML created: tls-secret.yaml"