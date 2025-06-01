#!/bin/bash

set -e

echo "🚀 Setting up DynamicSoft distributed application..."

# Check prerequisites
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed."; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "❌ minikube is required but not installed."; exit 1; }
command -v trivy >/dev/null 2>&1 || { echo "⚠️ Trivy not found, security scanning will be skipped."; }
command -v cosign >/dev/null 2>&1 || { echo "⚠️ Cosign not found, signature verification will be skipped."; }

echo "Prerequisites check completed"

# Start minikube if not running
echo "Checking minikube status..."
if ! minikube status >/dev/null 2>&1; then
    echo "Starting minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
else
    echo "minikube is already running"
fi

# Enable required addons
echo "Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Generate certificates
echo "Generating TLS certificates..."
cd security/certs
chmod +x generate-certs.sh
./generate-certs.sh
cd ../..

# Build Docker images
echo "Building Docker images..."
eval $(minikube docker-env)

docker build -t frontend:v1 ./frontend
docker build -t backend:v1 ./backend
docker build -t auth-service:v1 ./auth-service

echo "Docker images built successfully"

# Run security scans if available
if command -v trivy >/dev/null 2>&1; then
    echo "Running security scans..."
    cd security/scan
    chmod +x trivy-scan.sh
    ./trivy-scan.sh
    cd ../..
fi

# Generate signing keys if cosign is available
if command -v cosign >/dev/null 2>&1; then
    echo "Generating signing keys..."
    cosign generate-key-pair
    
    echo "Signing images..."
    cosign sign --key cosign.key frontend:v1
    cosign sign --key cosign.key backend:v1
    cosign sign --key cosign.key auth-service:v1
fi

# Apply RBAC
echo "Applying RBAC configurations..."
kubectl apply -f security/rbac/

# Deploy application
echo "Deploying application..."
kubectl apply -k k8s/overlays/dev

# Apply security policies
echo "Applying security policies..."
kubectl apply -f k8s/security/

# Wait for deployments
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all

# Run health check
echo "Running health check..."
chmod +x scripts/health-check.sh
./scripts/health-check.sh

echo "   Setup completed successfully!"
echo "   Access the application:"
echo "   Frontend: $(minikube service frontend --url)"
echo "   Use 'kubectl get pods' to check pod status"
echo "   Use 'kubectl logs <pod-name>' to view logs"