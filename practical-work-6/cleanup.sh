#!/bin/bash

echo "=================================="
echo "Kubernetes Cleanup Script"
echo "Practical Work 6"
echo "Author: Gribkov A.S. IKBO-16-22"
echo "=================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info_msg() {
    echo -e "${YELLOW}→ $1${NC}"
}

success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

info_msg "Deleting Ingress..."
kubectl delete -f app/frontend/ingress.yaml --ignore-not-found=true
success_msg "Ingress deleted"

info_msg "Deleting Frontend resources..."
kubectl delete -f app/frontend/frontend.yaml --ignore-not-found=true
kubectl delete -f app/frontend/traffic-service.yml --ignore-not-found=true
success_msg "Frontend deleted"

info_msg "Deleting FileServer resources..."
kubectl delete -f app/fileserver/fileserver.yml --ignore-not-found=true
kubectl delete -f app/fileserver/fileserver-service.yml --ignore-not-found=true
success_msg "FileServer deleted"

info_msg "Deleting Redis resources..."
kubectl delete -f app/redis/redis.yml --ignore-not-found=true
kubectl delete -f app/redis/redis-read.yml --ignore-not-found=true
kubectl delete -f app/redis/redis-write.yml --ignore-not-found=true
success_msg "Redis deleted"

info_msg "Deleting ConfigMaps..."
kubectl delete configmap frontend-config --ignore-not-found=true
kubectl delete configmap redis-config --ignore-not-found=true
success_msg "ConfigMaps deleted"

info_msg "Deleting Secrets..."
kubectl delete secret redis-passwd --ignore-not-found=true
success_msg "Secrets deleted"

info_msg "Deleting PersistentVolumeClaims..."
kubectl delete pvc -l app=redis --ignore-not-found=true
success_msg "PVCs deleted"

echo ""
info_msg "Waiting for resources to be fully deleted..."
sleep 5

echo ""
echo "Remaining resources:"
kubectl get pods,svc,ingress,configmap,secret,pvc 2>/dev/null | grep -E "frontend|fileserver|redis" || echo "All resources cleaned up!"

echo ""
success_msg "Cleanup completed!"
