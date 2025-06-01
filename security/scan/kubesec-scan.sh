#!/bin/bash

K8S_MANIFESTS="../k8s/base/*.yaml"
REPORT_DIR="./reports"

mkdir -p $REPORT_DIR

echo "Scanning Kubernetes manifests with Kubesec..."

for manifest in $K8S_MANIFESTS; do
    filename=$(basename "$manifest")
    echo "Scanning $filename..."
    
    kubesec scan "$manifest" > "$REPORT_DIR/kubesec-${filename%.yaml}.json"
    
    # Check score
    score=$(cat "$REPORT_DIR/kubesec-${filename%.yaml}.json" | jq '.[0].score // 0')
    
    if [ "$score" -lt 0 ]; then
        echo "CRITICAL: $filename has negative security score: $score"
        cat "$REPORT_DIR/kubesec-${filename%.yaml}.json" | jq '.[0].advise'
    else
        echo "$filename security score: $score"
    fi
done

echo "Kubesec scanning completed. Reports saved to $REPORT_DIR"