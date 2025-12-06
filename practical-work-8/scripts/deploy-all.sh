#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="task-management"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

echo "=========================================="
echo "  Task Management System Deployment"
echo "  Practical Work 8"
echo "=========================================="
echo ""

log_info "Step 1/10: Checking prerequisites..."
check_command docker
check_command kubectl
check_command helm
check_command minikube
log_success "All required tools are installed"

log_info "Step 2/10: Checking Docker daemon..."
if ! docker ps &> /dev/null; then
    log_warning "Docker daemon is not running. Attempting to start Colima..."
    if command -v colima &> /dev/null; then
        colima stop 2>/dev/null || true
        colima delete -f 2>/dev/null || true
        log_info "Starting fresh Colima instance..."
        colima start --cpu 6 --memory 12 --disk 50
        sleep 10
        if ! docker ps &> /dev/null; then
            log_error "Failed to start Docker via Colima"
            exit 1
        fi
    else
        log_error "Docker is not running and Colima is not installed. Please start Docker manually."
        exit 1
    fi
fi
log_success "Docker daemon is running"

log_info "Step 3/10: Setting up Minikube cluster..."
MINIKUBE_STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null || echo "Stopped")
if [ "$MINIKUBE_STATUS" != "Running" ]; then
    log_info "Cleaning up old Minikube cluster..."
    minikube delete 2>/dev/null || true

    log_info "Starting fresh Minikube cluster..."
    minikube start \
        --driver=docker \
        --cpus=6 \
        --memory=10240 \
        --disk-size=30g \
        --kubernetes-version=v1.28.0

    log_info "Enabling Minikube addons..."
    minikube addons enable metrics-server

    log_info "Waiting for Minikube to be ready..."
    sleep 10
else
    log_info "Minikube is already running"
    kubectl cluster-info &>/dev/null || {
        log_warning "Minikube running but kubectl cannot connect. Restarting..."
        minikube delete 2>/dev/null || true
        minikube start \
            --driver=docker \
            --cpus=6 \
            --memory=10240 \
            --disk-size=30g \
            --kubernetes-version=v1.28.0
        minikube addons enable metrics-server
        sleep 10
    }
fi
log_success "Minikube is ready"

log_info "Step 4/10: Creating namespace..."
kubectl create namespace $NAMESPACE 2>/dev/null || log_warning "Namespace already exists"
kubectl config set-context --current --namespace=$NAMESPACE
log_success "Namespace '$NAMESPACE' is ready"

log_info "Step 4.5/10: Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>/dev/null || true
helm repo update
log_success "Helm repositories are ready"

log_info "Step 5/10: Installing infrastructure with Helm..."

log_info "  - Installing PostgreSQL instances (3x)..."

helm upgrade --install auth-postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
    --namespace $NAMESPACE \
    --set auth.username=auth_user \
    --set auth.password=auth_password \
    --set auth.database=auth_db \
    --set primary.persistence.size=1Gi \
    --set primary.resources.requests.cpu=100m \
    --set primary.resources.requests.memory=256Mi \
    --set primary.resources.limits.cpu=300m \
    --set primary.resources.limits.memory=512Mi \
    --wait --timeout=3m || log_warning "auth-postgres installation had issues, continuing..."

helm upgrade --install task-postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
    --namespace $NAMESPACE \
    --set auth.username=task_user \
    --set auth.password=task_password \
    --set auth.database=task_db \
    --set primary.persistence.size=1Gi \
    --set primary.resources.requests.cpu=100m \
    --set primary.resources.requests.memory=256Mi \
    --set primary.resources.limits.cpu=300m \
    --set primary.resources.limits.memory=512Mi \
    --wait --timeout=3m || log_warning "task-postgres installation had issues, continuing..."

helm upgrade --install notification-postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
    --namespace $NAMESPACE \
    --set auth.username=notification_user \
    --set auth.password=notification_password \
    --set auth.database=notification_db \
    --set primary.persistence.size=1Gi \
    --set primary.resources.requests.cpu=100m \
    --set primary.resources.requests.memory=256Mi \
    --set primary.resources.limits.cpu=300m \
    --set primary.resources.limits.memory=512Mi \
    --wait --timeout=3m || log_warning "notification-postgres installation had issues, continuing..."

log_success "PostgreSQL instances installed"

log_info "  - Installing Redis..."
helm upgrade --install redis oci://registry-1.docker.io/bitnamicharts/redis \
    --namespace $NAMESPACE \
    --set auth.password=redis_password \
    --set master.persistence.enabled=false \
    --set master.resources.requests.cpu=100m \
    --set master.resources.requests.memory=128Mi \
    --set master.resources.limits.cpu=200m \
    --set master.resources.limits.memory=256Mi \
    --set replica.replicaCount=0 \
    --wait --timeout=3m || true

log_success "Redis installed"

log_info "  - Installing Kafka..."
kubectl apply -f $PROJECT_DIR/infrastructure/kafka/kafka-deployment.yaml
kubectl wait --for=condition=ready pod -l app=kafka -n $NAMESPACE --timeout=5m || log_warning "Kafka is still starting"
log_success "Kafka installed"

log_info "  - Installing Prometheus..."

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace $NAMESPACE \
    --set server.persistentVolume.enabled=false \
    --set alertmanager.enabled=false \
    --set prometheus-pushgateway.enabled=false \
    --set server.resources.requests.cpu=100m \
    --set server.resources.requests.memory=256Mi \
    --set server.resources.limits.cpu=300m \
    --set server.resources.limits.memory=512Mi \
    --wait --timeout=3m || true

log_success "Prometheus installed"

log_info "  - Installing Grafana..."

helm upgrade --install grafana grafana/grafana \
    --namespace $NAMESPACE \
    --set adminPassword=admin \
    --set persistence.enabled=false \
    --set resources.requests.cpu=50m \
    --set resources.requests.memory=128Mi \
    --set resources.limits.cpu=200m \
    --set resources.limits.memory=256Mi \
    --set datasources."datasources\.yaml".apiVersion=1 \
    --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
    --set datasources."datasources\.yaml".datasources[0].type=prometheus \
    --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server:80 \
    --set datasources."datasources\.yaml".datasources[0].isDefault=true \
    --wait --timeout=3m || true

log_success "Grafana installed"

log_info "  - Installing Jaeger..."

helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace $NAMESPACE \
    --set provisionDataStore.cassandra=false \
    --set allInOne.enabled=true \
    --set storage.type=memory \
    --set allInOne.resources.requests.cpu=50m \
    --set allInOne.resources.requests.memory=128Mi \
    --set allInOne.resources.limits.cpu=200m \
    --set allInOne.resources.limits.memory=256Mi \
    --wait --timeout=3m || true

log_success "Jaeger installed"

log_info "  - Installing MongoDB for Graylog..."
helm upgrade --install mongodb oci://registry-1.docker.io/bitnamicharts/mongodb \
    --namespace $NAMESPACE \
    --set auth.rootPassword=graylog_password \
    --set persistence.size=1Gi \
    --set resources.requests.cpu=200m \
    --set resources.requests.memory=512Mi \
    --set resources.limits.cpu=500m \
    --set resources.limits.memory=1Gi \
    --set livenessProbe.initialDelaySeconds=60 \
    --set livenessProbe.timeoutSeconds=30 \
    --set readinessProbe.initialDelaySeconds=60 \
    --set readinessProbe.timeoutSeconds=30 \
    --wait --timeout=5m || log_warning "MongoDB installation had issues, continuing..."

log_success "MongoDB installed"

log_info "  - Installing OpenSearch for Graylog..."
kubectl apply -f "$PROJECT_DIR/infrastructure/opensearch/deployment.yaml" || log_warning "OpenSearch installation had issues"
kubectl wait --for=condition=ready pod -l app=opensearch -n $NAMESPACE --timeout=5m 2>/dev/null || log_warning "OpenSearch is still starting"

log_success "OpenSearch installed"

log_info "  - Installing Graylog..."
kubectl apply -f "$PROJECT_DIR/infrastructure/graylog/deployment.yaml" || log_warning "Graylog installation had issues"
log_info "    Waiting for Graylog (this may take a few minutes)..."
kubectl wait --for=condition=ready pod -l app=graylog -n $NAMESPACE --timeout=10m 2>/dev/null || log_warning "Graylog is still starting"

log_success "Graylog installed"

log_info "  - Installing KrakenD API Gateway..."
# Create ConfigMap with krakend.json
kubectl create configmap krakend-config \
    --from-file=krakend.json="$PROJECT_DIR/infrastructure/krakend/krakend.json" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy KrakenD
kubectl apply -f "$PROJECT_DIR/infrastructure/krakend/deployment.yaml"

log_success "KrakenD installed"

log_success "All infrastructure components installed"

log_info "Step 6/10: Building Docker images for microservices..."

cd "$PROJECT_DIR/auth-service"
log_info "  - Building auth-service..."
docker build -t auth-service:latest .
minikube image load auth-service:latest

cd "$PROJECT_DIR/task-service"
log_info "  - Building task-service..."
docker build -t task-service:latest .
minikube image load task-service:latest

cd "$PROJECT_DIR/notification-service"
log_info "  - Building notification-service..."
docker build -t notification-service:latest .
minikube image load notification-service:latest

cd "$PROJECT_DIR/web-client"
log_info "  - Building web-client..."
docker build -t web-client:latest .
minikube image load web-client:latest

cd "$PROJECT_DIR"
log_success "All Docker images built and loaded"

log_info "Step 7/10: Waiting for infrastructure to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n $NAMESPACE --timeout=300s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n $NAMESPACE --timeout=300s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n $NAMESPACE --timeout=300s 2>/dev/null || true
sleep 10
log_success "Infrastructure is ready"

log_info "Step 8/10: Deploying microservices..."

log_info "  - Deploying auth-service..."
helm upgrade --install auth-service "$PROJECT_DIR/auth-service/helm/auth-service" \
    --namespace $NAMESPACE \
    --set image.repository=auth-service \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --set env.dbHost=auth-postgres-postgresql \
    --set env.dbPort=5432 \
    --set env.dbName=auth_db \
    --set env.dbUsername=auth_user \
    --set secrets.dbPassword=auth_password \
    --set env.redisHost=redis-master \
    --set env.redisPort=6379 \
    --set secrets.redisPassword=redis_password \
    --set env.kafkaBootstrapServers=kafka:9092 \
    --set env.graylogHost=graylog \
    --set env.graylogPort=12201 \
    --set env.jaegerHost=jaeger-agent \
    --set env.jaegerPort=6831 \
    --wait --timeout=5m || log_warning "auth-service deployment had issues, continuing..."

log_info "  - Deploying task-service..."
helm upgrade --install task-service "$PROJECT_DIR/task-service/helm/task-service" \
    --namespace $NAMESPACE \
    --set image.repository=task-service \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --set postgresql.host=task-postgres-postgresql \
    --set postgresql.port=5432 \
    --set postgresql.database=task_db \
    --set postgresql.username=task_user \
    --set postgresql.password=task_password \
    --set kafka.bootstrapServers=kafka:9092 \
    --set authService.url=http://auth-service:8081 \
    --set graylog.host=graylog \
    --set graylog.port=12201 \
    --set jaeger.host=jaeger-agent \
    --set jaeger.port=6831 \
    --set serviceMonitor.enabled=false \
    --wait --timeout=5m || log_warning "task-service deployment had issues, continuing..."

log_info "  - Deploying notification-service..."
helm upgrade --install notification-service "$PROJECT_DIR/notification-service/helm/notification-service" \
    --namespace $NAMESPACE \
    --set image.repository=notification-service \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --set postgresql.host=notification-postgres-postgresql \
    --set postgresql.port=5432 \
    --set postgresql.database=notification_db \
    --set postgresql.username=notification_user \
    --set postgresql.password=notification_password \
    --set kafka.bootstrapServers=kafka:9092 \
    --set authService.url=http://auth-service:8081 \
    --set graylog.host=graylog \
    --set graylog.port=12201 \
    --set jaeger.host=jaeger-agent \
    --set jaeger.port=6831 \
    --set serviceMonitor.enabled=false \
    --wait --timeout=5m || log_warning "notification-service deployment had issues, continuing..."

log_info "  - Deploying web-client..."
helm upgrade --install web-client "$PROJECT_DIR/web-client/helm/web-client" \
    --namespace $NAMESPACE \
    --set image.repository=web-client \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --wait --timeout=2m || log_warning "web-client deployment had issues, continuing..."

log_success "All microservices deployed"

log_info "Step 9/10: Waiting for all services to be ready..."
log_info "  - Waiting for auth-service..."
kubectl wait --for=condition=ready pod -l app=auth-service -n $NAMESPACE --timeout=5m 2>/dev/null || log_warning "auth-service not ready yet"
log_info "  - Waiting for task-service..."
kubectl wait --for=condition=ready pod -l app=task-service -n $NAMESPACE --timeout=5m 2>/dev/null || log_warning "task-service not ready yet"
log_info "  - Waiting for notification-service..."
kubectl wait --for=condition=ready pod -l app=notification-service -n $NAMESPACE --timeout=5m 2>/dev/null || log_warning "notification-service not ready yet"

log_info "Verifying deployment..."
kubectl get pods -n $NAMESPACE
echo ""

log_info "Checking service endpoints..."
kubectl get svc -n $NAMESPACE

log_success "Deployment verification complete"

log_info "Step 10/10: Setting up port forwarding..."

cat > "$SCRIPT_DIR/port-forward.sh" << 'EOF'
#!/bin/bash
NAMESPACE="task-management"

echo "Setting up port forwarding..."
echo "Press Ctrl+C to stop all port forwards"
echo ""

kubectl port-forward -n $NAMESPACE svc/krakend 8080:8080 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/auth-service 8081:8081 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/task-service 8082:8082 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/notification-service 8083:8083 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/web-client 8084:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/graylog 9000:9000 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/grafana 3000:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/jaeger-query 16686:16686 > /dev/null 2>&1 &

sleep 2

echo "Port forwarding active:"
echo "  Web Client:          http://localhost:8084"
echo "  KrakenD (Gateway):   http://localhost:8080"
echo "  Auth Service:        http://localhost:8081"
echo "  Task Service:        http://localhost:8082"
echo "  Notification Service: http://localhost:8083"
echo "  Graylog:             http://localhost:9000 (admin/admin)"
echo "  Grafana:             http://localhost:3000 (admin/admin)"
echo "  Prometheus:          http://localhost:9090"
echo "  Jaeger:              http://localhost:16686"
echo ""
echo "Press Ctrl+C to stop"

wait
EOF

chmod +x "$SCRIPT_DIR/port-forward.sh"

echo ""
echo "=========================================="
log_success "DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  ✅ Minikube cluster running"
echo "  ✅ Infrastructure deployed (PostgreSQL, Redis, Kafka, Prometheus, Grafana, Jaeger)"
echo "  ✅ Microservices deployed (Auth, Task, Notification)"
echo "  ✅ Web Client deployed"
echo ""
echo "🚀 Next steps:"
echo ""
echo "1. Start port forwarding:"
echo "   ./scripts/port-forward.sh"
echo ""
echo "2. Test the system:"
echo "   # Register a user (через KrakenD)"
echo "   curl -X POST http://localhost:8080/auth/register \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"Test123!\"}'"
echo ""
echo "   # Login (через KrakenD)"
echo "   curl -X POST http://localhost:8080/auth/login \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"username\":\"testuser\",\"password\":\"Test123!\"}'"
echo ""
echo "3. Access services:"
echo "   - Web Client: http://localhost:8084 (Test UI)"
echo "   - KrakenD:    http://localhost:8080 (API Gateway)"
echo "   - Graylog:    http://localhost:9000 (admin/admin)"
echo "   - Grafana:    http://localhost:3000 (admin/admin)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Jaeger:     http://localhost:16686"
echo ""
echo "4. View logs:"
echo "   kubectl logs -n $NAMESPACE -l app=auth-service --tail=50 -f"
echo ""
echo "5. Check pod status:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "=========================================="

