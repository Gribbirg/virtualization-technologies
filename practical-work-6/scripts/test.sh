#!/bin/bash

set -e

echo "=================================="
echo "Kubernetes Application Deployment"
echo "Practical Work 6"
echo "Author: Gribkov A.S. IKBO-16-22"
echo "=================================="
echo ""

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

check_prerequisites() {
    info_msg "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        error_exit "kubectl is not installed"
    fi
    success_msg "kubectl is installed"

    if ! kubectl cluster-info &> /dev/null; then
        error_exit "Kubernetes cluster is not accessible. Run: minikube start --driver=docker --cpus=2 --memory=2048"
    fi
    success_msg "Kubernetes cluster is accessible"

    info_msg "Checking if API server is responsive..."
    if ! kubectl get nodes &> /dev/null; then
        error_exit "Kubernetes API server is not responding properly. Try: minikube delete && minikube start --driver=docker --cpus=2 --memory=2048"
    fi
    success_msg "API server is responsive"

    info_msg "Checking Docker images in Minikube..."
    if ! minikube image ls | grep -q "gribkov/static-files:v1"; then
        info_msg "Loading static-files image to Minikube..."
        minikube image load gribkov/static-files:v1 || info_msg "Image not found locally, will pull from registry"
    fi
    if ! minikube image ls | grep -q "gribkov/journal-server:v1"; then
        info_msg "Loading journal-server image to Minikube..."
        minikube image load gribkov/journal-server:v1 || info_msg "Image not found locally, will pull from registry"
    fi
    success_msg "Docker images checked"

    echo ""
}

create_configmaps_and_secrets() {
    info_msg "Creating ConfigMaps and Secrets..."

    if kubectl get configmap frontend-config &> /dev/null; then
        info_msg "ConfigMap 'frontend-config' already exists, skipping..."
    else
        kubectl create configmap frontend-config --from-literal=journalEntries=10
        success_msg "Created ConfigMap 'frontend-config'"
    fi

    if kubectl get secret redis-passwd &> /dev/null; then
        info_msg "Secret 'redis-passwd' already exists, skipping..."
    else
        REDIS_PASSWORD=$(openssl rand -base64 32)
        kubectl create secret generic redis-passwd --from-literal=passwd="${REDIS_PASSWORD}"
        success_msg "Created Secret 'redis-passwd'"
    fi

    if kubectl get configmap redis-config &> /dev/null; then
        info_msg "ConfigMap 'redis-config' already exists, skipping..."
    else
        kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh
        success_msg "Created ConfigMap 'redis-config'"
    fi

    echo ""
}

deploy_redis() {
    info_msg "Deploying Redis StatefulSet..."

    kubectl apply -f app/redis/redis.yml
    kubectl apply -f app/redis/redis-read.yml
    kubectl apply -f app/redis/redis-write.yml

    success_msg "Redis manifests applied"
    echo ""
}

deploy_frontend() {
    info_msg "Deploying Frontend..."

    kubectl apply -f app/frontend/frontend.yaml
    kubectl apply -f app/frontend/traffic-service.yml

    success_msg "Frontend manifests applied"
    echo ""
}

deploy_fileserver() {
    info_msg "Deploying FileServer..."

    kubectl apply -f app/fileserver/fileserver.yml
    kubectl apply -f app/fileserver/fileserver-service.yml

    success_msg "FileServer manifests applied"
    echo ""
}

deploy_ingress() {
    info_msg "Deploying Ingress..."

    if kubectl get ingressclass nginx &> /dev/null || kubectl get ingressclass public &> /dev/null; then
        success_msg "Ingress controller is available"
    else
        info_msg "Ingress controller not found. For Minikube, run: minikube addons enable ingress"
    fi

    kubectl apply -f app/frontend/ingress.yaml
    success_msg "Ingress manifest applied"
    echo ""
}

wait_for_deployments() {
    info_msg "Waiting for deployments to be ready..."

    info_msg "Waiting for Redis StatefulSet (this may take a while)..."
    kubectl wait --for=condition=ready pod -l app=redis --timeout=300s || info_msg "Redis pods may still be starting..."

    info_msg "Waiting for Frontend Deployment..."
    kubectl wait --for=condition=available deployment/frontend --timeout=180s
    success_msg "Frontend is ready"

    info_msg "Waiting for FileServer Deployment..."
    kubectl wait --for=condition=available deployment/fileserver --timeout=180s
    success_msg "FileServer is ready"

    echo ""
}

display_status() {
    info_msg "Deployment Status:"
    echo ""

    echo "=== Pods ==="
    kubectl get pods
    echo ""

    echo "=== Services ==="
    kubectl get services
    echo ""

    echo "=== StatefulSets ==="
    kubectl get statefulsets
    echo ""

    echo "=== PersistentVolumeClaims ==="
    kubectl get pvc
    echo ""

    echo "=== Ingress ==="
    kubectl get ingress
    echo ""
}

check_redis_replication() {
    info_msg "Checking Redis replication status..."

    REDIS_PASSWORD=$(kubectl get secret redis-passwd -o jsonpath='{.data.passwd}' | base64 -d)

    if kubectl get pod redis-0 &> /dev/null; then
        echo "Redis-0 (Master) Info:"
        kubectl exec redis-0 -- redis-cli -a "${REDIS_PASSWORD}" INFO replication 2>/dev/null | grep -E "role|connected_slaves" || true
        success_msg "Redis replication check completed"
    else
        info_msg "Redis pods not ready yet"
    fi

    echo ""
}

get_access_urls() {
    info_msg "Access URLs:"
    echo ""

    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        echo "Minikube detected"
        MINIKUBE_IP=$(minikube ip)
        echo "Access the application at: http://${MINIKUBE_IP}"
        echo "  - Static files: http://${MINIKUBE_IP}/"
        echo "  - API: http://${MINIKUBE_IP}/api"
        echo ""
        echo "To open in browser: minikube service frontend"
    else
        INGRESS_IP=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
        INGRESS_HOST=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

        if [ "$INGRESS_IP" != "pending" ] && [ -n "$INGRESS_IP" ]; then
            echo "Access the application at: http://${INGRESS_IP}"
            echo "  - Static files: http://${INGRESS_IP}/"
            echo "  - API: http://${INGRESS_IP}/api"
        elif [ -n "$INGRESS_HOST" ]; then
            echo "Access the application at: http://${INGRESS_HOST}"
            echo "  - Static files: http://${INGRESS_HOST}/"
            echo "  - API: http://${INGRESS_HOST}/api"
        else
            echo "Ingress IP not yet assigned. Run 'kubectl get ingress' to check status."
            echo ""
            echo "Use port-forward for testing:"
            echo "  kubectl port-forward svc/frontend 8080:8080"
            echo "  Then access: http://localhost:8080/api"
        fi
    fi

    echo ""
}

main() {
    check_prerequisites
    create_configmaps_and_secrets
    deploy_redis
    deploy_frontend
    deploy_fileserver
    deploy_ingress
    wait_for_deployments
    display_status
    check_redis_replication
    get_access_urls

    success_msg "Deployment completed successfully!"
    echo ""
    echo "To monitor the application:"
    echo "  kubectl get pods -w"
    echo ""
    echo "To view logs:"
    echo "  kubectl logs -f deployment/frontend"
    echo "  kubectl logs -f deployment/fileserver"
    echo "  kubectl logs -f redis-0"
    echo ""
    echo "To cleanup:"
    echo "  ./cleanup.sh"
    echo ""
}

main "$@"
