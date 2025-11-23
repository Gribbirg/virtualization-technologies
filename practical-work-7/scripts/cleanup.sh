#!/bin/bash

NAMESPACE="gribkov-as-ikbo-16-22"

echo "========================================="
echo "Cleaning up resources"
echo "========================================="
echo ""

echo "Deleting all pods in namespace $NAMESPACE..."
kubectl delete pods --all -n $NAMESPACE --ignore-not-found=true
echo ""

echo "Deleting namespace $NAMESPACE..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true
echo ""

echo "========================================="
echo "Cleanup completed!"
echo "========================================="
