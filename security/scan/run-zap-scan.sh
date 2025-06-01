#!/bin/bash

TARGET_URL=${1:-"http://localhost:30080"}
REPORT_DIR="./reports"

mkdir -p $REPORT_DIR

echo "Starting OWASP ZAP security scan against $TARGET_URL..."

# Run ZAP baseline scan
docker run -v $(pwd)/$REPORT_DIR:/zap/wrk/:rw \
    -t owasp/zap2docker-stable zap-baseline.py \
    -t $TARGET_URL \
    -g gen.conf \
    -J zap-report.json \
    -r zap-report.html

echo "ZAP scan completed. Reports saved to $REPORT_DIR"