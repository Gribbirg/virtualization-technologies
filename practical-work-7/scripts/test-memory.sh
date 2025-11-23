#!/bin/bash

set -e

NAMESPACE="gribkov-as-ikbo-16-22"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Testing Memory Requests and Limits"
echo "========================================="
echo ""

echo "--- Test 1: Pod with valid memory limits (100Mi request, 200Mi limit, uses 150Mi) ---"
echo ""
echo "Applying memory-request-limit.yaml..."
kubectl apply -f "$PROJECT_DIR/memory-request-limit.yaml"
echo ""

echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod/memory-demo -n $NAMESPACE --timeout=60s || true
sleep 5
echo ""

echo "Pod status:"
kubectl get pod memory-demo -n $NAMESPACE
echo ""

echo "Pod details:"
kubectl get pod memory-demo -n $NAMESPACE -o yaml | grep -A 10 "resources:"
echo ""

echo "Pod metrics:"
kubectl top pod memory-demo -n $NAMESPACE || echo "Metrics not yet available"
echo ""

echo "Deleting pod..."
kubectl delete pod memory-demo -n $NAMESPACE
echo "Waiting for pod deletion..."
kubectl wait --for=delete pod/memory-demo -n $NAMESPACE --timeout=60s
echo ""

echo "--- Test 2: Pod exceeding memory limit (50Mi request, 100Mi limit, tries to use 250Mi) ---"
echo ""
echo "Applying memory-request-limit-2.yaml..."
kubectl apply -f "$PROJECT_DIR/memory-request-limit-2.yaml"
echo ""

echo "Waiting and checking pod status (should be OOMKilled)..."
sleep 10
echo ""

echo "Pod status:"
kubectl get pod memory-demo-2 -n $NAMESPACE
echo ""

echo "Checking if container is being killed repeatedly..."
for i in {1..3}; do
    echo "Check $i:"
    kubectl get pod memory-demo-2 -n $NAMESPACE | grep -E "NAME|memory-demo-2"
    sleep 5
done
echo ""

echo "Pod details (showing OOMKilled reason):"
kubectl get pod memory-demo-2 -n $NAMESPACE -o yaml | grep -A 5 "lastState:" || true
echo ""

echo "Pod events:"
kubectl describe pod memory-demo-2 -n $NAMESPACE | grep -A 20 "Events:"
echo ""

echo "Node events (checking for OOM kills):"
kubectl describe nodes | grep -i "memory" || true
echo ""

echo "Deleting pod..."
kubectl delete pod memory-demo-2 -n $NAMESPACE
echo ""

echo "--- Test 3: Pod requesting more memory than node capacity (1000Gi request) ---"
echo ""
echo "Applying memory-request-limit-3.yaml..."
kubectl apply -f "$PROJECT_DIR/memory-request-limit-3.yaml"
echo ""

echo "Checking pod status (should be Pending)..."
sleep 5
kubectl get pod memory-demo-3 -n $NAMESPACE
echo ""

echo "Pod events (showing insufficient memory):"
kubectl describe pod memory-demo-3 -n $NAMESPACE | grep -A 10 "Events:"
echo ""

echo "Deleting pod..."
kubectl delete pod memory-demo-3 -n $NAMESPACE
echo ""

echo "========================================="
echo "Memory tests completed!"
echo "========================================="
