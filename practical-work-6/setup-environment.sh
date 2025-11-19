#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

info_msg() {
    echo -e "${YELLOW}→ $1${NC}"
}

echo "==========================================="
echo "Kubernetes Environment Setup"
echo "Practical Work 6"
echo "Author: Gribkov A.S. IKBO-16-22"
echo "==========================================="
echo ""

info_msg "This script will setup Colima and Minikube for Kubernetes development"
echo ""

info_msg "Step 1: Checking if Colima is installed..."
if ! command -v colima &> /dev/null; then
    error_exit "Colima is not installed. Install with: brew install colima"
fi
success_msg "Colima is installed"

info_msg "Step 2: Checking if Minikube is installed..."
if ! command -v minikube &> /dev/null; then
    error_exit "Minikube is not installed. Install with: brew install minikube"
fi
success_msg "Minikube is installed"

info_msg "Step 3: Stopping existing Minikube cluster if running..."
if minikube status &> /dev/null; then
    minikube delete
    success_msg "Existing Minikube cluster deleted"
else
    info_msg "No existing Minikube cluster found"
fi

info_msg "Step 4: Restarting Colima..."
if colima status &> /dev/null; then
    info_msg "Stopping Colima..."
    colima stop || true
fi

info_msg "Deleting existing Colima VM..."
colima delete -f || true

info_msg "Starting Colima with proper configuration..."
colima start --cpu 2 --memory 4 --disk 20
success_msg "Colima started successfully"

sleep 5

info_msg "Step 5: Starting Minikube..."
minikube start --driver=docker --cpus=2 --memory=2048

success_msg "Minikube started successfully"

info_msg "Step 6: Enabling Ingress addon..."
minikube addons enable ingress
success_msg "Ingress addon enabled"

info_msg "Step 7: Verifying cluster..."
if ! kubectl cluster-info &> /dev/null; then
    error_exit "Cluster is not accessible"
fi
success_msg "Cluster is accessible"

if ! kubectl get nodes &> /dev/null; then
    error_exit "API server is not responding"
fi
success_msg "API server is responding"

echo ""
echo "==========================================="
success_msg "Environment setup completed successfully!"
echo "==========================================="
echo ""
echo "Cluster Information:"
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Minikube IP: $(minikube ip)"
echo ""
echo "Next steps:"
echo "  1. Build images: ./build-images.sh"
echo "  2. Run deployment: ./test.sh"
echo ""
