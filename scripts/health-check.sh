#!/bin/bash

NAMESPACE=${1:-"default"}
TIMEOUT=${2:-30}

echo "Performing comprehensive health check..."

# Check all deployments
echo "Checking deployment status..."
for deployment in $(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    echo "Checking $deployment..."
    
    ready_replicas=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    desired_replicas=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    
    if [ "$ready_replicas" = "$desired_replicas" ]; then
        echo "$deployment: $ready_replicas/$desired_replicas replicas ready"
    else
        echo "$deployment: $ready_replicas/$desired_replicas replicas ready"
    fi
done

# Check services
echo "🌐 Checking service endpoints..."
for service in $(kubectl get services -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    endpoints=$(kubectl get endpoints $service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    if [ $endpoints -gt 0 ]; then
        echo "$service: $endpoints endpoints available"
    else
        echo "$service: No endpoints available"
    fi
done

# Check application health endpoints
echo "🩺 Checking application health endpoints..."

# Get frontend URL
FRONTEND_URL=$(minikube service frontend --url 2>/dev/null || echo "http://localhost:30080")

# Test frontend
if curl -f -s --connect-timeout $TIMEOUT "$FRONTEND_URL" > /dev/null; then
    echo "Frontend health check passed"
else
    echo "Frontend health check failed"
fi

# Test backend (through port-forward)
kubectl port-forward svc/backend 3000:3000 &
PORT_FORWARD_PID=$!
sleep 5

if curl -f -s --connect-timeout $TIMEOUT "http://localhost:3000/health" > /dev/null; then
    echo "Backend health check passed"
else
    echo "Backend health check failed"
fi

kill $PORT_FORWARD_PID 2>/dev/null

# Test auth service
kubectl port-forward svc/auth-service 8080:8080 &
PORT_FORWARD_PID=$!
sleep 5

if curl -f -s --connect-timeout $TIMEOUT "http://localhost:8080/health" > /dev/null; then
    echo "Auth service health check passed"
else
    echo "Auth service health check failed"
fi

kill $PORT_FORWARD_PID 2>/dev/null

echo "Health check completed"