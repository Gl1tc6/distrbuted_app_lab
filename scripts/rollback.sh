#!/bin/bash

set -e

COMPONENT=${1:-"all"}
REASON=${2:-"Manual rollback"}
NOTIFICATION_EMAIL=${3:-"admin@dynamicsoft.hr"}

echo "Starting rollback process for $COMPONENT..."
echo "Reason: $REASON"

# Function to rollback component
rollback_component() {
    local comp=$1
    
    echo "Checking rollout history for $comp..."
    kubectl rollout history deployment/$comp
    
    echo "Rolling back $comp to previous version..."
    kubectl rollout undo deployment/$comp
    
    echo "Waiting for rollback to complete..."
    kubectl rollout status deployment/$comp --timeout=300s
    
    # Verify rollback
    sleep 10
    if kubectl get deployment/$comp -o jsonpath='{.status.readyReplicas}' | grep -q "$(kubectl get deployment/$comp -o jsonpath='{.spec.replicas}')"; then
        echo "$comp rollback completed successfully"
    else
        echo "$comp rollback failed!"
        exit 1
    fi
}

# Audit logging
echo "$(date): Rollback initiated by $(whoami) for $COMPONENT. Reason: $REASON" >> /var/log/upgrade-audit.log

# Main rollback logic
if [ "$COMPONENT" = "all" ]; then
    rollback_component "frontend"
    rollback_component "auth-service" 
    rollback_component "backend"
else
    rollback_component $COMPONENT
fi

# Send notification
echo "Rollback completed for $COMPONENT at $(date). Reason: $REASON" | mail -s "DynamicSoft Rollback Notification" $NOTIFICATION_EMAIL

echo "Rollback process completed successfully!"