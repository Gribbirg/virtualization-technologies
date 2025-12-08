@echo off
setlocal enabledelayedexpansion

set NAMESPACE=task-management
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..\..

echo ==========================================
echo   Task Management System Deployment
echo   Practical Work 8
echo ==========================================
echo.

echo [INFO] Step 1/10: Checking prerequisites...
where docker >nul 2>&1 || (echo [ERROR] docker is not installed. Please install it first. && exit /b 1)
where kubectl >nul 2>&1 || (echo [ERROR] kubectl is not installed. Please install it first. && exit /b 1)
where helm >nul 2>&1 || (echo [ERROR] helm is not installed. Please install it first. && exit /b 1)
where minikube >nul 2>&1 || (echo [ERROR] minikube is not installed. Please install it first. && exit /b 1)
echo [SUCCESS] All required tools are installed

echo [INFO] Step 2/10: Checking Docker daemon...
docker ps >nul 2>&1 || (echo [ERROR] Docker is not running. Please start Docker manually. && exit /b 1)
echo [SUCCESS] Docker daemon is running

echo [INFO] Step 3/10: Setting up Minikube cluster...
for /f "tokens=*" %%a in ('minikube status --format^={{.Host}} 2^>nul') do set MINIKUBE_STATUS=%%a
if not "%MINIKUBE_STATUS%"=="Running" (
    echo [INFO] Cleaning up old Minikube cluster...
    minikube delete 2>nul

    echo [INFO] Starting fresh Minikube cluster...
    minikube start --driver=docker --cpus=6 --memory=10240 --disk-size=30g --kubernetes-version=v1.28.0

    echo [INFO] Enabling Minikube addons...
    minikube addons enable metrics-server

    echo [INFO] Waiting for Minikube to be ready...
    timeout /t 10 /nobreak >nul
) else (
    echo [INFO] Minikube is already running
    kubectl cluster-info >nul 2>&1 || (
        echo [WARNING] Minikube running but kubectl cannot connect. Restarting...
        minikube delete 2>nul
        minikube start --driver=docker --cpus=6 --memory=10240 --disk-size=30g --kubernetes-version=v1.28.0
        minikube addons enable metrics-server
        timeout /t 10 /nobreak >nul
    )
)
echo [SUCCESS] Minikube is ready

echo [INFO] Step 4/10: Creating namespace...
kubectl create namespace %NAMESPACE% 2>nul || echo [WARNING] Namespace already exists
kubectl config set-context --current --namespace=%NAMESPACE%
echo [SUCCESS] Namespace '%NAMESPACE%' is ready

echo [INFO] Step 4.5/10: Adding Helm repositories...
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>nul
helm repo add grafana https://grafana.github.io/helm-charts 2>nul
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts 2>nul
helm repo update
echo [SUCCESS] Helm repositories are ready

echo [INFO] Step 5/10: Installing infrastructure with Helm...
echo.
echo [INFO]   - Installing PostgreSQL instances (3x)...

helm upgrade --install auth-postgres oci://registry-1.docker.io/bitnamicharts/postgresql --namespace %NAMESPACE% --set auth.username=auth_user --set auth.password=auth_password --set auth.database=auth_db --set primary.persistence.size=1Gi --set primary.resources.requests.cpu=100m --set primary.resources.requests.memory=256Mi --set primary.resources.limits.cpu=300m --set primary.resources.limits.memory=512Mi --wait --timeout=3m

helm upgrade --install task-postgres oci://registry-1.docker.io/bitnamicharts/postgresql --namespace %NAMESPACE% --set auth.username=task_user --set auth.password=task_password --set auth.database=task_db --set primary.persistence.size=1Gi --set primary.resources.requests.cpu=100m --set primary.resources.requests.memory=256Mi --set primary.resources.limits.cpu=300m --set primary.resources.limits.memory=512Mi --wait --timeout=3m

helm upgrade --install notification-postgres oci://registry-1.docker.io/bitnamicharts/postgresql --namespace %NAMESPACE% --set auth.username=notification_user --set auth.password=notification_password --set auth.database=notification_db --set primary.persistence.size=1Gi --set primary.resources.requests.cpu=100m --set primary.resources.requests.memory=256Mi --set primary.resources.limits.cpu=300m --set primary.resources.limits.memory=512Mi --wait --timeout=3m

echo [SUCCESS] PostgreSQL instances installed

echo [INFO]   - Installing Redis...
helm upgrade --install redis oci://registry-1.docker.io/bitnamicharts/redis --namespace %NAMESPACE% --set auth.password=redis_password --set master.persistence.enabled=false --set master.resources.requests.cpu=100m --set master.resources.requests.memory=128Mi --set master.resources.limits.cpu=200m --set master.resources.limits.memory=256Mi --set replica.replicaCount=0 --wait --timeout=3m

echo [SUCCESS] Redis installed

echo [INFO]   - Installing Kafka...
kubectl apply -f %PROJECT_DIR%\infrastructure\kafka\kafka-deployment.yaml
kubectl wait --for=condition=ready pod -l app=kafka -n %NAMESPACE% --timeout=5m 2>nul || echo [WARNING] Kafka is still starting
echo [SUCCESS] Kafka installed

echo [INFO]   - Installing Prometheus...
helm upgrade --install prometheus prometheus-community/prometheus --namespace %NAMESPACE% --set server.persistentVolume.enabled=false --set alertmanager.enabled=false --set prometheus-pushgateway.enabled=false --set server.resources.requests.cpu=100m --set server.resources.requests.memory=256Mi --set server.resources.limits.cpu=300m --set server.resources.limits.memory=512Mi --wait --timeout=3m

echo [SUCCESS] Prometheus installed

echo [INFO]   - Installing Grafana...
helm upgrade --install grafana grafana/grafana --namespace %NAMESPACE% --set adminPassword=admin --set persistence.enabled=false --set resources.requests.cpu=50m --set resources.requests.memory=128Mi --set resources.limits.cpu=200m --set resources.limits.memory=256Mi --set datasources."datasources\.yaml".apiVersion=1 --set datasources."datasources\.yaml".datasources[0].name=Prometheus --set datasources."datasources\.yaml".datasources[0].type=prometheus --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server:80 --set datasources."datasources\.yaml".datasources[0].isDefault=true --wait --timeout=3m

echo [SUCCESS] Grafana installed

echo [INFO]   - Installing Jaeger...
helm upgrade --install jaeger jaegertracing/jaeger --namespace %NAMESPACE% --set provisionDataStore.cassandra=false --set allInOne.enabled=true --set storage.type=memory --set allInOne.resources.requests.cpu=50m --set allInOne.resources.requests.memory=128Mi --set allInOne.resources.limits.cpu=200m --set allInOne.resources.limits.memory=256Mi --wait --timeout=3m

echo [SUCCESS] Jaeger installed

echo [INFO]   - Installing MongoDB for Graylog...
helm upgrade --install mongodb oci://registry-1.docker.io/bitnamicharts/mongodb --namespace %NAMESPACE% --set auth.rootPassword=graylog_password --set persistence.size=1Gi --set resources.requests.cpu=200m --set resources.requests.memory=512Mi --set resources.limits.cpu=500m --set resources.limits.memory=1Gi --set livenessProbe.initialDelaySeconds=60 --set livenessProbe.timeoutSeconds=30 --set readinessProbe.initialDelaySeconds=60 --set readinessProbe.timeoutSeconds=30 --wait --timeout=5m

echo [SUCCESS] MongoDB installed

echo [INFO]   - Installing OpenSearch for Graylog...
kubectl apply -f "%PROJECT_DIR%\infrastructure\opensearch\deployment.yaml"
kubectl wait --for=condition=ready pod -l app=opensearch -n %NAMESPACE% --timeout=5m 2>nul || echo [WARNING] OpenSearch is still starting

echo [SUCCESS] OpenSearch installed

echo [INFO]   - Installing Graylog...
kubectl apply -f "%PROJECT_DIR%\infrastructure\graylog\deployment.yaml"
echo [INFO]     Waiting for Graylog (this may take a few minutes)...
kubectl wait --for=condition=ready pod -l app=graylog -n %NAMESPACE% --timeout=10m 2>nul || echo [WARNING] Graylog is still starting

echo [SUCCESS] Graylog installed

echo [INFO]   - Installing KrakenD API Gateway...
kubectl create configmap krakend-config --from-file=krakend.json="%PROJECT_DIR%\infrastructure\krakend\krakend.json" --namespace=%NAMESPACE% --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "%PROJECT_DIR%\infrastructure\krakend\deployment.yaml"

echo [SUCCESS] KrakenD installed

echo [SUCCESS] All infrastructure components installed

echo [INFO] Step 6/10: Building Docker images for microservices...

cd /d "%PROJECT_DIR%\auth-service"
echo [INFO]   - Building auth-service...
docker build -t auth-service:latest .
minikube image load auth-service:latest

cd /d "%PROJECT_DIR%\task-service"
echo [INFO]   - Building task-service...
docker build -t task-service:latest .
minikube image load task-service:latest

cd /d "%PROJECT_DIR%\notification-service"
echo [INFO]   - Building notification-service...
docker build -t notification-service:latest .
minikube image load notification-service:latest

cd /d "%PROJECT_DIR%\web-client"
echo [INFO]   - Building web-client...
docker build -t web-client:latest .
minikube image load web-client:latest

cd /d "%PROJECT_DIR%"
echo [SUCCESS] All Docker images built and loaded

echo [INFO] Step 7/10: Waiting for infrastructure to be ready...
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n %NAMESPACE% --timeout=300s 2>nul
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n %NAMESPACE% --timeout=300s 2>nul
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n %NAMESPACE% --timeout=300s 2>nul
timeout /t 10 /nobreak >nul
echo [SUCCESS] Infrastructure is ready

echo [INFO] Step 8/10: Deploying microservices...

echo [INFO]   - Deploying auth-service...
helm upgrade --install auth-service "%PROJECT_DIR%\auth-service\helm\auth-service" --namespace %NAMESPACE% --set image.repository=auth-service --set image.tag=latest --set image.pullPolicy=Never --set env.dbHost=auth-postgres-postgresql --set env.dbPort=5432 --set env.dbName=auth_db --set env.dbUsername=auth_user --set secrets.dbPassword=auth_password --set env.redisHost=redis-master --set env.redisPort=6379 --set secrets.redisPassword=redis_password --set env.kafkaBootstrapServers=kafka:9092 --set env.graylogHost=graylog --set env.graylogPort=12201 --set env.jaegerHost=jaeger-agent --set env.jaegerPort=6831 --wait --timeout=5m

echo [INFO]   - Deploying task-service...
helm upgrade --install task-service "%PROJECT_DIR%\task-service\helm\task-service" --namespace %NAMESPACE% --set image.repository=task-service --set image.tag=latest --set image.pullPolicy=Never --set postgresql.host=task-postgres-postgresql --set postgresql.port=5432 --set postgresql.database=task_db --set postgresql.username=task_user --set postgresql.password=task_password --set kafka.bootstrapServers=kafka:9092 --set authService.url=http://auth-service:8081 --set graylog.host=graylog --set graylog.port=12201 --set jaeger.host=jaeger-agent --set jaeger.port=6831 --set serviceMonitor.enabled=false --wait --timeout=5m

echo [INFO]   - Deploying notification-service...
helm upgrade --install notification-service "%PROJECT_DIR%\notification-service\helm\notification-service" --namespace %NAMESPACE% --set image.repository=notification-service --set image.tag=latest --set image.pullPolicy=Never --set postgresql.host=notification-postgres-postgresql --set postgresql.port=5432 --set postgresql.database=notification_db --set postgresql.username=notification_user --set postgresql.password=notification_password --set kafka.bootstrapServers=kafka:9092 --set authService.url=http://auth-service:8081 --set graylog.host=graylog --set graylog.port=12201 --set jaeger.host=jaeger-agent --set jaeger.port=6831 --set serviceMonitor.enabled=false --wait --timeout=5m

echo [INFO]   - Deploying web-client...
helm upgrade --install web-client "%PROJECT_DIR%\web-client\helm\web-client" --namespace %NAMESPACE% --set image.repository=web-client --set image.tag=latest --set image.pullPolicy=Never --wait --timeout=2m

echo [SUCCESS] All microservices deployed

echo [INFO] Step 9/10: Waiting for all services to be ready...
echo [INFO]   - Waiting for auth-service...
kubectl wait --for=condition=ready pod -l app=auth-service -n %NAMESPACE% --timeout=5m 2>nul || echo [WARNING] auth-service not ready yet
echo [INFO]   - Waiting for task-service...
kubectl wait --for=condition=ready pod -l app=task-service -n %NAMESPACE% --timeout=5m 2>nul || echo [WARNING] task-service not ready yet
echo [INFO]   - Waiting for notification-service...
kubectl wait --for=condition=ready pod -l app=notification-service -n %NAMESPACE% --timeout=5m 2>nul || echo [WARNING] notification-service not ready yet

echo [INFO] Verifying deployment...
kubectl get pods -n %NAMESPACE%
echo.

echo [INFO] Checking service endpoints...
kubectl get svc -n %NAMESPACE%

echo [SUCCESS] Deployment verification complete

echo [INFO] Step 10/10: Port forwarding setup...
echo Port forwarding script is available at: %SCRIPT_DIR%port-forward.bat

echo.
echo ==========================================
echo [SUCCESS] DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo Summary:
echo   - Minikube cluster running
echo   - Infrastructure deployed (PostgreSQL, Redis, Kafka, Prometheus, Grafana, Jaeger)
echo   - Microservices deployed (Auth, Task, Notification)
echo   - Web Client deployed
echo.
echo Next steps:
echo.
echo 1. Start port forwarding:
echo    %SCRIPT_DIR%port-forward.bat
echo.
echo 2. Test the system:
echo    Register a user (through KrakenD):
echo    curl -X POST http://localhost:8080/auth/register ^
echo      -H "Content-Type: application/json" ^
echo      -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"Test123!\"}"
echo.
echo    Login (through KrakenD):
echo    curl -X POST http://localhost:8080/auth/login ^
echo      -H "Content-Type: application/json" ^
echo      -d "{\"username\":\"testuser\",\"password\":\"Test123!\"}"
echo.
echo 3. Access services:
echo    - Web Client: http://localhost:8084 (Test UI)
echo    - KrakenD:    http://localhost:8080 (API Gateway)
echo    - Graylog:    http://localhost:9000 (admin/admin)
echo    - Grafana:    http://localhost:3000 (admin/admin)
echo    - Prometheus: http://localhost:9090
echo    - Jaeger:     http://localhost:16686
echo.
echo 4. View logs:
echo    kubectl logs -n %NAMESPACE% -l app=auth-service --tail=50 -f
echo.
echo 5. Check pod status:
echo    kubectl get pods -n %NAMESPACE%
echo.
echo ==========================================
