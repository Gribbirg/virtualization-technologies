#!/bin/bash

set -e

NAMESPACE="gribkov-as-ikbo-16-22"

echo "========================================="
echo "Setup environment for Practical Work 7"
echo "========================================="
echo ""

echo "Checking minikube status..."
if ! minikube status &> /dev/null; then
    echo "ERROR: minikube is not running. Please start it with 'minikube start'"
    exit 1
fi
echo "✓ minikube is running"
echo ""

echo "Enabling metrics-server addon..."
minikube addons enable metrics-server
echo "✓ metrics-server enabled"
echo ""

echo "Waiting for metrics-server to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
sleep 10
echo ""

echo "Checking API services..."
kubectl get apiservices | grep metrics
echo ""

echo "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✓ namespace created/verified"
echo ""

echo "========================================="
echo "Setup completed successfully!"
echo "========================================="
