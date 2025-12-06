# Task Service - Deployment Guide

## Quick Start

### Local Development

1. **Start PostgreSQL:**
```bash
docker run -d --name task-postgres \
  -e POSTGRES_DB=task_db \
  -e POSTGRES_USER=task_user \
  -e POSTGRES_PASSWORD=task_password \
  -p 5433:5432 \
  postgres:15
```

2. **Start Kafka:**
```bash
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_KRAFT_CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk \
  -e KAFKA_PROCESS_ROLES=broker,controller \
  -e KAFKA_NODE_ID=1 \
  -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  confluentinc/cp-kafka:7.5.0
```

3. **Build and run:**
```bash
./gradlew bootRun
```

4. **Access Swagger UI:**
```
http://localhost:8082/swagger-ui.html
```

## Kubernetes Deployment

### Prerequisites

- Minikube running
- kubectl configured
- Helm 3 installed
- Auth Service deployed
- PostgreSQL deployed (task-postgres)
- Kafka deployed

### Build Docker Image

```bash
# Build image
docker build -t task-service:latest .

# Load into Minikube
minikube image load task-service:latest
```

### Deploy with Helm

```bash
# Install
helm install task-service ./helm/task-service \
  -n task-management \
  --create-namespace

# Check status
kubectl get pods -n task-management -l app=task-service

# View logs
kubectl logs -n task-management -l app=task-service -f

# Port forward
kubectl port-forward -n task-management svc/task-service 8082:8082
```

### Verify Deployment

```bash
# Check health
curl http://localhost:8082/actuator/health

# Check readiness
curl http://localhost:8082/actuator/health/readiness

# Check metrics
curl http://localhost:8082/actuator/prometheus | grep tasks_
```

### Test with Script

```bash
# Make sure Auth Service is running on port 8081
./test-service.sh
```

## Configuration

### Environment Variables

Update `helm/task-service/values.yaml`:

```yaml
env:
  DB_HOST: task-postgres
  DB_PORT: "5432"
  DB_NAME: task_db
  DB_USERNAME: task_user
  DB_PASSWORD: task_password
  KAFKA_BOOTSTRAP_SERVERS: kafka:9092
  AUTH_SERVICE_URL: http://auth-service:8081
  GRAYLOG_HOST: graylog
  GRAYLOG_PORT: "12201"
```

### Resource Limits

Adjust in `values.yaml`:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Autoscaling

Configure HPA:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 60
```

## Monitoring

### Prometheus Metrics

```bash
# View metrics
kubectl port-forward -n task-management svc/task-service 8082:8082
curl http://localhost:8082/actuator/prometheus
```

### Custom Metrics

- `tasks_created_total` - Total tasks created
- `tasks_updated_total` - Total tasks updated
- `tasks_deleted_total` - Total tasks deleted

### Grafana Dashboard

Add Prometheus queries:
```promql
# Task creation rate
rate(tasks_created_total[5m])

# Task operations by type
sum by (operation) (rate(tasks_created_total[5m]))
```

## Troubleshooting

### Pod not starting

```bash
kubectl describe pod -n task-management <pod-name>
kubectl logs -n task-management <pod-name>
```

### Cannot connect to Auth Service

```bash
# Test connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://auth-service:8081/actuator/health
```

### Cannot connect to PostgreSQL

```bash
# Check PostgreSQL is running
kubectl get pods -n task-management -l app=task-postgres

# Test connection
kubectl exec -n task-management task-postgres-0 -- \
  pg_isready -U task_user -d task_db
```

### Kafka events not published

```bash
# Check Kafka logs
kubectl logs -n task-management kafka-0

# List topics
kubectl exec -n task-management kafka-0 -- \
  kafka-topics --bootstrap-server localhost:9092 --list
```

## Upgrade

```bash
# Update image
docker build -t task-service:latest .
minikube image load task-service:latest

# Upgrade Helm release
helm upgrade task-service ./helm/task-service -n task-management

# Watch rollout
kubectl rollout status deployment/task-service -n task-management
```

## Rollback

```bash
# View history
helm history task-service -n task-management

# Rollback to previous version
helm rollback task-service -n task-management

# Rollback to specific revision
helm rollback task-service 1 -n task-management
```

## Uninstall

```bash
# Uninstall Helm release
helm uninstall task-service -n task-management

# Verify removal
kubectl get pods -n task-management -l app=task-service
```

## Performance Tuning

### Database Connection Pool

In `application.yml`:
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10
```

### Cache TTL

```yaml
auth-service:
  validation-cache-ttl: 600  # 10 minutes
```

### JVM Options

In Dockerfile:
```dockerfile
ENTRYPOINT ["java", "-Xmx768m", "-Xms512m", "-jar", "app.jar"]
```

## Security

### Database Credentials

Store in Kubernetes Secret:
```bash
kubectl create secret generic task-postgres-secret \
  -n task-management \
  --from-literal=username=task_user \
  --from-literal=password=secure_password
```

### Network Policies

Restrict access to Task Service:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: task-service-network-policy
spec:
  podSelector:
    matchLabels:
      app: task-service
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: krakend
```

## Backup & Recovery

### Database Backup

```bash
kubectl exec -n task-management task-postgres-0 -- \
  pg_dump -U task_user task_db > backup.sql
```

### Restore

```bash
kubectl exec -i -n task-management task-postgres-0 -- \
  psql -U task_user task_db < backup.sql
```

