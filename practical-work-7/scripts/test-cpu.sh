#!/bin/bash

set -e

NAMESPACE="gribkov-as-ikbo-16-22"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Testing CPU Requests and Limits"
echo "========================================="
echo ""

echo "--- Test 1: Pod with valid CPU limits (0.5 request, 1 limit, tries to use 2) ---"
echo ""
echo "Applying cpu-request-limit.yaml..."
kubectl apply -f "$PROJECT_DIR/cpu-request-limit.yaml"
echo ""

echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod/cpu-demo -n $NAMESPACE --timeout=60s
sleep 10
echo ""

echo "Pod status:"
kubectl get pod cpu-demo -n $NAMESPACE
echo ""

echo "Pod details:"
kubectl get pod cpu-demo -n $NAMESPACE -o yaml | grep -A 10 "resources:"
echo ""

echo "Pod metrics (CPU should be limited to ~1 CPU):"
kubectl top pod cpu-demo -n $NAMESPACE || echo "Metrics not yet available"
sleep 5
kubectl top pod cpu-demo -n $NAMESPACE || echo "Metrics not yet available"
echo ""

echo "Deleting pod..."
kubectl delete pod cpu-demo -n $NAMESPACE
echo "Waiting for pod deletion..."
kubectl wait --for=delete pod/cpu-demo -n $NAMESPACE --timeout=60s
echo ""

echo "--- Test 2: Pod requesting more CPU than node capacity (100 CPU request) ---"
echo ""
echo "Applying cpu-request-limit-2.yaml..."
kubectl apply -f "$PROJECT_DIR/cpu-request-limit-2.yaml"
echo ""

echo "Checking pod status (should be Pending)..."
sleep 5
kubectl get pod cpu-demo-2 -n $NAMESPACE
echo ""

echo "Pod events (showing insufficient CPU):"
kubectl describe pod cpu-demo-2 -n $NAMESPACE | grep -A 10 "Events:"
echo ""

echo "Deleting pod..."
kubectl delete pod cpu-demo-2 -n $NAMESPACE
echo ""

echo "========================================="
echo "CPU tests completed!"
echo "========================================="
