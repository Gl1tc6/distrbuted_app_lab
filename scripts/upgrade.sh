#!/bin/bash

set -e

COMPONENT=${1:-"all"}
NEW_VERSION=${2:-"v2"}
NAMESPACE=${3:-"default"}

echo "Starting upgrade process for $COMPONENT to $NEW_VERSION..."

# Function to wait for rollout completion
wait_for_rollout() {
    local deployment=$1
    echo "Waiting for $deployment rollout to complete..."
    kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=300s
}

# Function to perform security checks
security_check() {
    local image=$1
    echo "Running security checks for $image..."
    
    # Trivy scan
    if ! trivy image --exit-code 1 --severity HIGH,CRITICAL $image; then
        echo "Security scan failed for $image"
        return 1
    fi
    
    # Cosign verification
    if ! cosign verify --key cosign.pub $image; then
        echo "Signature verification failed for $image"
        return 1
    fi
    
    echo "Security checks passed for $image"
    return 0
}

# Upgrade specific component
upgrade_component() {
    local comp=$1
    local version=$2
    
    echo "Upgrading $comp to $version..."
    
    # Security check before upgrade
    if ! security_check "$comp:$version"; then
        echo "Upgrade blocked due to security issues"
        exit 1
    fi
    
    # Update image
    kubectl set image deployment/$comp $comp=$comp:$version -n $NAMESPACE
    
    # Wait for rollout
    wait_for_rollout $comp
    
    # Health check
    sleep 10
    if kubectl get deployment/$comp -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' | grep -q "$(kubectl get deployment/$comp -n $NAMESPACE -o jsonpath='{.spec.replicas}')"; then
        echo "$comp upgrade completed successfully"
    else
        echo "$comp upgrade failed - initiating rollback"
        kubectl rollout undo deployment/$comp -n $NAMESPACE
        exit 1
    fi
}

# Main upgrade logic
if [ "$COMPONENT" = "all" ]; then
    upgrade_component "backend" $NEW_VERSION
    upgrade_component "auth-service" $NEW_VERSION
    upgrade_component "frontend" $NEW_VERSION
else
    upgrade_component $COMPONENT $NEW_VERSION
fi

echo "🎉 Upgrade process completed successfully!"