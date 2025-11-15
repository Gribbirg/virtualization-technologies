#!/bin/bash

set -e

DEPLOYMENT_NAME="gribkov-ikbo-16-22"
IMAGE_NAME="gribkov-ikbo-16-22-obraz"

echo "=== Kubernetes Deployment Test Script ==="
echo "Student: Gribkov A.S., IKBO-16-22"
echo ""

echo "Step 1: Checking if Minikube is running..."
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start
else
    echo "Minikube is already running"
fi
echo ""

echo "Step 2: Configuring Docker to use Minikube's Docker daemon..."
eval $(minikube docker-env)
echo ""

echo "Step 3: Building Docker image..."
docker build -t $IMAGE_NAME .
echo ""

echo "Step 4: Verifying Docker image..."
docker images | grep $IMAGE_NAME
echo ""

echo "Step 5: Applying Kubernetes deployment..."
kubectl apply -f deployment.yaml
echo ""

echo "Step 6: Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/$DEPLOYMENT_NAME
echo ""

echo "Step 7: Getting deployment information..."
kubectl get deployments
echo ""

echo "Step 8: Getting pod information..."
kubectl get pods
echo ""

echo "Step 9: Getting cluster events..."
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 10
echo ""

echo "Step 10: Viewing kubectl configuration..."
kubectl config view
echo ""

echo "Step 11: Exposing service..."
if kubectl get service $DEPLOYMENT_NAME &> /dev/null; then
    echo "Service already exists"
else
    kubectl expose deployment $DEPLOYMENT_NAME --type=NodePort --port=8080
fi
echo ""

echo "Step 12: Getting service information..."
kubectl get services
echo ""

echo "Step 13: Getting service information..."
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get service $DEPLOYMENT_NAME -o jsonpath='{.spec.ports[0].nodePort}')
echo "Minikube IP: $MINIKUBE_IP"
echo "NodePort: $NODE_PORT"
echo "Service URL: http://${MINIKUBE_IP}:${NODE_PORT}"
echo ""

echo "Step 14: Setting up port forwarding..."
kubectl port-forward service/$DEPLOYMENT_NAME 8080:8080 &
PORT_FORWARD_PID=$!
sleep 3
echo "Port forward PID: $PORT_FORWARD_PID"
echo ""

echo "Step 15: Testing the service via port-forward..."
RESPONSE=$(curl -s http://localhost:8080)
echo "Response: $RESPONSE"
echo ""

if [ "$RESPONSE" == "Hello World!" ]; then
    echo "✓ Test PASSED: Service is working correctly!"
else
    echo "✗ Test FAILED: Expected 'Hello World!' but got '$RESPONSE'"
    kill $PORT_FORWARD_PID 2>/dev/null
    exit 1
fi
echo ""

echo "Step 16: Stopping port-forward..."
kill $PORT_FORWARD_PID 2>/dev/null
echo "Port-forward stopped"
echo ""

echo "Step 17: Checking addons..."
minikube addons list
echo ""

echo "=== All tests completed successfully! ==="
echo ""

echo "Optional: To view the Kubernetes Dashboard, run:"
echo "  minikube dashboard"
echo ""

echo "Cleanup commands (run manually if needed):"
echo "  kubectl delete service $DEPLOYMENT_NAME"
echo "  kubectl delete deployment $DEPLOYMENT_NAME"
echo "  minikube stop"
