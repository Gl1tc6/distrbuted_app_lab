#!/bin/bash

set -e

TARGET=${1:-"green"}
COMPONENT=${2:-"frontend"}

if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
    echo "Usage: $0 <blue|green> [component]"
    exit 1
fi

echo "Switching $COMPONENT traffic to $TARGET environment..."

# Scale up target deployment
echo "Scaling up $COMPONENT-$TARGET..."
kubectl scale deployment $COMPONENT-$TARGET --replicas=2

# Wait for target to be ready
echo "Waiting for $TARGET environment to be ready..."
kubectl rollout status deployment/$COMPONENT-$TARGET --timeout=300s

# Update service selector
echo "Switching traffic to $TARGET..."
kubectl patch service $COMPONENT -p "{\"spec\":{\"selector\":{\"version\":\"$TARGET\"}}}"

# Scale down other environment
OTHER="blue"
if [ "$TARGET" == "blue" ]; then
    OTHER="green"
fi

echo "Scaling down $COMPONENT-$OTHER..."
kubectl scale deployment $COMPONENT-$OTHER --replicas=0

echo "Traffic successfully switched to $TARGET environment"
echo "Current service status:"
kubectl get service $COMPONENT -o wide