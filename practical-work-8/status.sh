#!/bin/bash

NAMESPACE="task-management"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo "=========================================="
echo "  Task Management System Status"
echo "=========================================="
echo ""

log_info "Minikube Status:"
minikube status
echo ""

log_info "Namespace: $NAMESPACE"
echo ""

log_info "Pods:"
kubectl get pods -n $NAMESPACE -o wide
echo ""

log_info "Services:"
kubectl get svc -n $NAMESPACE
echo ""

log_info "Persistent Volume Claims:"
kubectl get pvc -n $NAMESPACE
echo ""

log_info "Helm Releases:"
helm list -n $NAMESPACE
echo ""

log_info "Resource Usage:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics not available (metrics-server may not be ready)"
echo ""

log_info "Recent Events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
echo ""

echo "=========================================="
echo "To view logs:"
echo "  kubectl logs -n $NAMESPACE <pod-name> -f"
echo ""
echo "To access services:"
echo "  ./port-forward.sh"
echo ""
echo "To test the system:"
echo "  ./test-system.sh"
echo "=========================================="


