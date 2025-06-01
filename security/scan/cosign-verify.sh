#!/bin/bash

IMAGES=("frontend:v1" "backend:v1" "auth-service:v1")
PUBLIC_KEY="cosign.pub"

echo "Verifying image signatures with Cosign..."

for image in "${IMAGES[@]}"; do
    echo "Verifying signature for $image..."
    
    if cosign verify --key $PUBLIC_KEY $image; then
        echo "Signature verified for $image"
    else
        echo "CRITICAL: Signature verification failed for $image!"
        exit 1
    fi
done

echo "All image signatures verified successfully!"