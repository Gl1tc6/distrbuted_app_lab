#!/bin/bash

IMAGES=("frontend:v1" "backend:v1" "auth-service:v1")
REPORT_DIR="./reports"

mkdir -p $REPORT_DIR

echo "Starting security scan with Trivy..."

for image in "${IMAGES[@]}"; do
    echo "Scanning $image..."
    
    # Scan for vulnerabilities
    trivy image --format json --output "$REPORT_DIR/${image//:/}-vulnerabilities.json" $image
    trivy image --format table --output "$REPORT_DIR/${image//:/}-summary.txt" $image
    
    # Check for HIGH and CRITICAL vulnerabilities
    high_critical=$(trivy image --format json $image | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")] | length')
    
    if [ "$high_critical" -gt 0 ]; then
        echo "CRITICAL: $image has $high_critical HIGH/CRITICAL vulnerabilities!"
        echo "Scan failed for $image" >> "$REPORT_DIR/scan-failures.log"
    else
        echo "$image passed security scan"
    fi
done

echo "Security scan completed. Reports saved to $REPORT_DIR"