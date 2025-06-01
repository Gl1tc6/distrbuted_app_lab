.PHONY: setup build deploy upgrade rollback clean test security-scan

# Setup development environment
setup:
	./scripts/setup.sh

# Build all Docker images
build:
	eval $(minikube docker-env) && \
	docker build -t frontend:v1 ./frontend && \
	docker build -t backend:v1 ./backend && \
	docker build -t auth-service:v1 ./auth-service

# Build v2 images for upgrade testing
build-v2:
	eval $(minikube docker-env) && \
	docker build -t frontend:v2 ./frontend && \
	docker build -t backend:v2 ./backend && \
	docker build -t auth-service:v2 ./auth-service

# Deploy application
deploy:
	kubectl apply -f security/rbac/
	kubectl apply -k k8s/overlays/dev
	kubectl apply -f k8s/security/

# Run security scans
security-scan:
	cd security/scan && ./trivy-scan.sh
	cd security/scan && ./kubesec-scan.sh

# Upgrade to v2
upgrade:
	./scripts/upgrade.sh all v2

# Rollback to previous version
rollback:
	./scripts/rollback.sh all "Testing rollback functionality"

# Blue-green deployment switch
blue-green-switch:
	./scripts/blue-green-switch.sh green frontend

# Health check
health-check:
	./scripts/health-check.sh

# Clean up resources
clean:
	kubectl delete -k k8s/overlays/dev --ignore-not-found=true
	kubectl delete -f k8s/security/ --ignore-not-found=true
	kubectl delete -f security/rbac/ --ignore-not-found=true

# Run tests
test:
	cd frontend && npm test
	cd backend && npm test

# Complete test scenario
test-upgrade-scenario:
	make build
	make deploy
	make health-check
	make security-scan
	make build-v2
	make upgrade
	make health-check
	make rollback
	make health-check