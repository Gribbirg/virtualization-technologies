#!/bin/bash

NAMESPACE="task-management"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "=========================================="
echo "  Cleanup Task Management System"
echo "=========================================="
echo ""

log_info "Uninstalling microservices..."
helm uninstall auth-service -n $NAMESPACE 2>/dev/null || true
helm uninstall task-service -n $NAMESPACE 2>/dev/null || true
helm uninstall notification-service -n $NAMESPACE 2>/dev/null || true
log_success "Microservices uninstalled"

log_info "Uninstalling infrastructure..."
helm uninstall auth-postgres -n $NAMESPACE 2>/dev/null || true
helm uninstall task-postgres -n $NAMESPACE 2>/dev/null || true
helm uninstall notification-postgres -n $NAMESPACE 2>/dev/null || true
helm uninstall redis -n $NAMESPACE 2>/dev/null || true
helm uninstall kafka -n $NAMESPACE 2>/dev/null || true
helm uninstall prometheus -n $NAMESPACE 2>/dev/null || true
helm uninstall grafana -n $NAMESPACE 2>/dev/null || true
helm uninstall jaeger -n $NAMESPACE 2>/dev/null || true
log_success "Infrastructure uninstalled"

log_info "Deleting PVCs..."
kubectl delete pvc --all -n $NAMESPACE 2>/dev/null || true
log_success "PVCs deleted"

log_info "Deleting namespace..."
kubectl delete namespace $NAMESPACE 2>/dev/null || true
log_success "Namespace deleted"

echo ""
read -p "Do you want to delete Minikube cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Deleting Minikube cluster..."
    minikube delete
    log_success "Minikube cluster deleted"
fi

echo ""
log_success "Cleanup complete!"


