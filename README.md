# Distributed App Upgrade Lab

Laboratorijska vježba za sigurnu nadogradnju raspodijeljene aplikacije korištenjem Docker i Kubernetes tehnologija.

## Preduvjeti

- Docker Engine 20.10+
- minikube 1.25+
- kubectl
- Git
- Trivy, Cosign, Kubesec

## Pokretanje

1. Klonirajte repozitorij:
```bash
git clone https://github.com/Gl1tc6/distributed_app_lab.git
cd distributed_app_lab
```

2. Pokrenite minikube:

```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

3. Generirajte certifikate:

```bash
cd security/certs
./generate-certs.sh
kubectl create secret tls app-tls --cert=server.crt --key=server.key
```

4. Izgradite i skenirajte Docker slike:

```bash
docker build -t frontend:v1 ./frontend
docker build -t backend:v1 ./backend
docker build -t auth-service:v1 ./auth-service
trivy image frontend:v1
trivy image backend:v1
trivy image auth-service:v1
```
5. Primjenite RBAC i pokrenite aplikaciju:

```bash
kubectl apply -f security/rbac/
kubectl apply -k k8s/overlays/dev
kubectl apply -f k8s/security/
```
## Testiranje nadogradnje
Pogledajte datoteke u /scripts direktoriju za automatske skripte za testiranje.


## Troubleshooting
```bash
# Česti problemi:
# Ako minikube ne radi:
minikube delete && minikube start

# Ako nema resursa:
kubectl get events --sort-by=.metadata.creationTimestamp

# Provjera logova:
kubectl logs -l app=backend
```

## Struktura projekta
```
distributed-app-upgrade-lab/
├── README.md
├── Makefile
├── .gitignore
│
├── frontend/
│   ├── package.json
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── public/
│   │   └── index.html
│   └── src/
│       ├── App.js
│       └── index.js
│
├── backend/
│   ├── package.json
│   ├── Dockerfile
│   └── src/
│       ├── index.js
│       └── migrate.js
│
├── auth-service/
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile
│
├── db/
│   ├── init.sql
│   └── docker-compose.yml
│
├── k8s/
│   ├── base/
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── auth-service-deployment.yaml
│   │   ├── database-statefulset.yaml
│   │   └── services.yaml
│   │
│   ├── overlays/
│   │   └── dev/
│   │       ├── kustomization.yaml
│   │       ├── secrets.yaml
│   │       ├── configmaps.yaml
│   │       └── backend-dev-patch.yaml
│   │
│   └── security/
│       ├── network-policies.yaml
│       └── pod-security-policy.yaml
│
├── security/
│   ├── rbac/
│   │   ├── service-accounts.yaml
│   │   └── rbac.yaml
│   │
│   ├── certs/
│   │   ├── generate-certs.sh
│   │   └── tls-config.yaml
│   │
│   └── scan/
│       ├── trivy-scan.sh
│       ├── cosign-verify.sh
│       ├── kubesec-scan.sh
│       └── run-zap-scan.sh
│
└── scripts/
    ├── setup.sh
    ├── upgrade.sh
    ├── rollback.sh
    ├── blue-green-switch.sh
    └── health-check.sh
```