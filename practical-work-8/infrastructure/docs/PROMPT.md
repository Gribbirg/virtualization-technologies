# Infrastructure - Implementation Prompt

## Overview
Set up complete Kubernetes infrastructure for the Task Management System in Minikube. This includes all supporting services: PostgreSQL databases, Redis, Kafka, KrakenD API Gateway, Graylog, Prometheus, Grafana, and Jaeger. **Focus on minimal working configuration - no over-engineering.**

## Technology Stack

### Container Orchestration
- **Platform**: Minikube (Kubernetes 1.28+)
- **Package Manager**: Helm 3
- **Container Runtime**: Docker

### Infrastructure Components

#### 1. PostgreSQL (3 instances)
- **Version**: 15
- **Instances**: 
  - `auth-postgres` - for Auth Service
  - `task-postgres` - for Task Service
  - `notification-postgres` - for Notification Service
- **Pattern**: 1 database per service

#### 2. Redis
- **Version**: 7
- **Purpose**: Token storage for Auth Service
- **Mode**: Single instance (no clustering for simplicity)

#### 3. Apache Kafka
- **Version**: 3.6+
- **Mode**: Single broker with KRaft (no Zookeeper)
- **Topics**: `auth-events`, `task-events`

#### 4. KrakenD API Gateway
- **Version**: 2.5+
- **Purpose**: Single entry point for all services
- **Features**: Routing, rate limiting, JWT validation

#### 5. Graylog Stack
- **Graylog**: 5.2+
- **MongoDB**: 6.0 (for Graylog metadata)
- **Elasticsearch**: 7.17 (for log storage)
- **Input**: GELF UDP on port 12201

#### 6. Prometheus
- **Version**: Latest
- **Purpose**: Metrics collection from all services and databases

#### 7. Grafana
- **Version**: Latest
- **Purpose**: Metrics visualization
- **Datasource**: Prometheus

#### 8. Jaeger
- **Version**: 1.52+
- **Purpose**: Distributed tracing
- **Mode**: All-in-one deployment

## Directory Structure

```
infrastructure/
├── helm/
│   ├── postgresql/
│   │   ├── auth-postgres/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── statefulset.yaml
│   │   │       ├── service.yaml
│   │   │       ├── pvc.yaml
│   │   │       ├── configmap.yaml
│   │   │       └── secret.yaml
│   │   ├── task-postgres/
│   │   │   └── (same structure)
│   │   └── notification-postgres/
│   │       └── (same structure)
│   ├── redis/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       └── secret.yaml
│   ├── kafka/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── statefulset.yaml
│   │       ├── service.yaml
│   │       └── configmap.yaml
│   ├── krakend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       └── ingress.yaml
│   ├── graylog/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── mongodb/
│   │       │   ├── statefulset.yaml
│   │       │   └── service.yaml
│   │       ├── elasticsearch/
│   │       │   ├── statefulset.yaml
│   │       │   └── service.yaml
│   │       └── graylog/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           └── configmap.yaml
│   ├── prometheus/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       └── servicemonitor.yaml
│   ├── grafana/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       └── dashboards/
│   │           └── task-management-dashboard.json
│   └── jaeger/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
├── krakend/
│   └── krakend.json
├── scripts/
│   ├── setup-minikube.sh
│   ├── install-all.sh
│   ├── uninstall-all.sh
│   ├── port-forward-all.sh
│   └── test-infrastructure.sh
├── docs/
│   └── ARCHITECTURE.md
└── README.md
```

## PostgreSQL Configuration

### Common Requirements for All 3 Instances

#### Resource Limits
```yaml
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### Persistent Volume
```yaml
volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 1Gi
```

#### Configuration
- **Max Connections**: 100
- **Shared Buffers**: 128MB
- **Effective Cache Size**: 256MB

#### Monitoring User
Create read-only user for Prometheus:
```sql
CREATE USER monitoring WITH PASSWORD 'monitoring_password';
GRANT CONNECT ON DATABASE auth_db TO monitoring;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO monitoring;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO monitoring;
```

#### Health Probes
```yaml
livenessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - pg_isready -U postgres
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - pg_isready -U postgres
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Instance-Specific Configuration

#### auth-postgres
- **Database**: `auth_db`
- **User**: `auth_user`
- **Port**: 5432
- **Service Name**: `auth-postgres`

#### task-postgres
- **Database**: `task_db`
- **User**: `task_user`
- **Port**: 5432
- **Service Name**: `task-postgres`

#### notification-postgres
- **Database**: `notification_db`
- **User**: `notification_user`
- **Port**: 5432
- **Service Name**: `notification-postgres`

## Redis Configuration

### Deployment
```yaml
replicas: 1
image: redis:7-alpine

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### Configuration
- **Max Memory**: 128MB
- **Max Memory Policy**: allkeys-lru
- **Password**: Set via Secret
- **Persistence**: AOF enabled (appendonly yes)

### Health Probes
```yaml
livenessProbe:
  exec:
    command:
      - redis-cli
      - ping
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
      - redis-cli
      - ping
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Kafka Configuration

### StatefulSet (KRaft mode - no Zookeeper)
```yaml
replicas: 1
image: confluentinc/cp-kafka:7.5.0

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Environment Variables
```yaml
env:
  - name: KAFKA_PROCESS_ROLES
    value: "broker,controller"
  - name: KAFKA_NODE_ID
    value: "1"
  - name: KAFKA_CONTROLLER_QUORUM_VOTERS
    value: "1@kafka-0.kafka-headless:9093"
  - name: KAFKA_LISTENERS
    value: "PLAINTEXT://:9092,CONTROLLER://:9093"
  - name: KAFKA_ADVERTISED_LISTENERS
    value: "PLAINTEXT://kafka:9092"
  - name: KAFKA_CONTROLLER_LISTENER_NAMES
    value: "CONTROLLER"
  - name: KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
    value: "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
  - name: KAFKA_AUTO_CREATE_TOPICS_ENABLE
    value: "true"
  - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
    value: "1"
```

### Topics (auto-created)
- `auth-events` - partitions: 3, replication: 1
- `task-events` - partitions: 3, replication: 1

## KrakenD Configuration

### Deployment
```yaml
replicas: 2
image: devopsfaith/krakend:2.5

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### krakend.json Configuration

```json
{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "name": "Task Management API Gateway",
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "output_encoding": "json",
  "extra_config": {
    "telemetry/opencensus": {
      "sample_rate": 100,
      "reporting_period": 0,
      "exporters": {
        "jaeger": {
          "endpoint": "http://jaeger:14268/api/traces",
          "service_name": "krakend"
        }
      }
    },
    "telemetry/metrics": {
      "collection_time": "60s",
      "proxy_disabled": false,
      "router_disabled": false,
      "backend_disabled": false,
      "endpoint_disabled": false,
      "listen_address": ":8090"
    },
    "telemetry/logging": {
      "level": "INFO",
      "prefix": "[KRAKEND]",
      "syslog": false,
      "stdout": true
    }
  },
  "endpoints": [
    {
      "endpoint": "/auth/register",
      "method": "POST",
      "backend": [
        {
          "url_pattern": "/api/auth/register",
          "host": ["http://auth-service:8081"],
          "method": "POST"
        }
      ]
    },
    {
      "endpoint": "/auth/login",
      "method": "POST",
      "backend": [
        {
          "url_pattern": "/api/auth/login",
          "host": ["http://auth-service:8081"],
          "method": "POST"
        }
      ]
    },
    {
      "endpoint": "/auth/validate",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/api/auth/validate",
          "host": ["http://auth-service:8081"],
          "method": "GET"
        }
      ],
      "extra_config": {
        "auth/validator": {
          "alg": "HS256",
          "jwk_url": "http://auth-service:8081/.well-known/jwks.json",
          "disable_jwk_security": true
        }
      }
    },
    {
      "endpoint": "/tasks",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/api/tasks",
          "host": ["http://task-service:8082"],
          "method": "GET"
        }
      ],
      "extra_config": {
        "auth/validator": {
          "alg": "HS256",
          "jwk_url": "http://auth-service:8081/.well-known/jwks.json",
          "disable_jwk_security": true
        }
      }
    },
    {
      "endpoint": "/tasks",
      "method": "POST",
      "backend": [
        {
          "url_pattern": "/api/tasks",
          "host": ["http://task-service:8082"],
          "method": "POST"
        }
      ]
    },
    {
      "endpoint": "/tasks/{id}",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/api/tasks/{id}",
          "host": ["http://task-service:8082"],
          "method": "GET"
        }
      ]
    },
    {
      "endpoint": "/tasks/{id}",
      "method": "PUT",
      "backend": [
        {
          "url_pattern": "/api/tasks/{id}",
          "host": ["http://task-service:8082"],
          "method": "PUT"
        }
      ]
    },
    {
      "endpoint": "/tasks/{id}",
      "method": "DELETE",
      "backend": [
        {
          "url_pattern": "/api/tasks/{id}",
          "host": ["http://task-service:8082"],
          "method": "DELETE"
        }
      ]
    },
    {
      "endpoint": "/notifications",
      "method": "GET",
      "backend": [
        {
          "url_pattern": "/api/notifications",
          "host": ["http://notification-service:8083"],
          "method": "GET"
        }
      ]
    }
  ]
}
```

### Service
```yaml
type: LoadBalancer
ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: metrics
    port: 8090
    targetPort: 8090
```

## Graylog Stack Configuration

### MongoDB
```yaml
replicas: 1
image: mongo:6.0

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

env:
  - name: MONGO_INITDB_ROOT_USERNAME
    value: admin
  - name: MONGO_INITDB_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: graylog-mongodb
        key: password
```

### Elasticsearch
```yaml
replicas: 1
image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi

env:
  - name: discovery.type
    value: single-node
  - name: ES_JAVA_OPTS
    value: "-Xms512m -Xmx512m"
  - name: xpack.security.enabled
    value: "false"
```

### Graylog
```yaml
replicas: 1
image: graylog/graylog:5.2

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi

env:
  - name: GRAYLOG_PASSWORD_SECRET
    value: somepasswordpepper
  - name: GRAYLOG_ROOT_PASSWORD_SHA2
    value: 8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918  # "admin"
  - name: GRAYLOG_HTTP_EXTERNAL_URI
    value: http://graylog:9000/
  - name: GRAYLOG_ELASTICSEARCH_HOSTS
    value: http://elasticsearch:9200
  - name: GRAYLOG_MONGODB_URI
    value: mongodb://admin:password@mongodb:27017/graylog?authSource=admin

ports:
  - name: http
    containerPort: 9000
  - name: gelf-tcp
    containerPort: 12201
  - name: gelf-udp
    containerPort: 12201
    protocol: UDP
```

## Prometheus Configuration

### Deployment
```yaml
replicas: 1
image: prom/prometheus:latest

resources:
  requests:
    cpu: 300m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### prometheus.yml
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'auth-service'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - task-management
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: auth-service
      - source_labels: [__meta_kubernetes_pod_ip]
        action: replace
        target_label: __address__
        replacement: $1:8081
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: instance

  - job_name: 'task-service'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - task-management
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: task-service
      - source_labels: [__meta_kubernetes_pod_ip]
        action: replace
        target_label: __address__
        replacement: $1:8082

  - job_name: 'notification-service'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - task-management
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: notification-service
      - source_labels: [__meta_kubernetes_pod_ip]
        action: replace
        target_label: __address__
        replacement: $1:8083

  - job_name: 'postgres-auth'
    static_configs:
      - targets: ['auth-postgres:5432']
    metrics_path: /metrics

  - job_name: 'postgres-task'
    static_configs:
      - targets: ['task-postgres:5432']

  - job_name: 'postgres-notification'
    static_configs:
      - targets: ['notification-postgres:5432']

  - job_name: 'krakend'
    static_configs:
      - targets: ['krakend:8090']
```

## Grafana Configuration

### Deployment
```yaml
replicas: 1
image: grafana/grafana:latest

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

env:
  - name: GF_SECURITY_ADMIN_USER
    value: admin
  - name: GF_SECURITY_ADMIN_PASSWORD
    value: admin
  - name: GF_INSTALL_PLUGINS
    value: ""
```

### Datasource (provisioned)
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

### Dashboard
Create dashboard with panels:
1. **Service Health** - Up/Down status
2. **HTTP Request Rate** - requests/sec by service
3. **HTTP Request Duration** - p50, p95, p99
4. **JVM Memory Usage** - by service
5. **Database Connections** - active connections by DB
6. **Kafka Consumer Lag** - by topic
7. **Error Rate** - 4xx and 5xx responses
8. **Pod CPU Usage** - by service
9. **Pod Memory Usage** - by service

## Jaeger Configuration

### Deployment (All-in-One)
```yaml
replicas: 1
image: jaegertracing/all-in-one:1.52

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

env:
  - name: COLLECTOR_OTLP_ENABLED
    value: "true"

ports:
  - name: jaeger-ui
    containerPort: 16686
  - name: jaeger-collector
    containerPort: 14268
  - name: jaeger-grpc
    containerPort: 14250
  - name: zipkin
    containerPort: 9411
```

## Scripts

### setup-minikube.sh
```bash
#!/bin/bash
set -e

echo "Setting up Minikube..."

# Delete existing cluster
minikube delete || true

# Start Minikube with sufficient resources
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --kubernetes-version=v1.28.0

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

echo "Minikube setup complete!"
kubectl cluster-info
```

### install-all.sh
```bash
#!/bin/bash
set -e

NAMESPACE="task-management"

echo "Creating namespace..."
kubectl create namespace $NAMESPACE || true

echo "Installing PostgreSQL instances..."
helm install auth-postgres ./helm/postgresql/auth-postgres -n $NAMESPACE
helm install task-postgres ./helm/postgresql/task-postgres -n $NAMESPACE
helm install notification-postgres ./helm/postgresql/notification-postgres -n $NAMESPACE

echo "Installing Redis..."
helm install redis ./helm/redis -n $NAMESPACE

echo "Installing Kafka..."
helm install kafka ./helm/kafka -n $NAMESPACE

echo "Installing Graylog stack..."
helm install graylog ./helm/graylog -n $NAMESPACE

echo "Installing Prometheus..."
helm install prometheus ./helm/prometheus -n $NAMESPACE

echo "Installing Grafana..."
helm install grafana ./helm/grafana -n $NAMESPACE

echo "Installing Jaeger..."
helm install jaeger ./helm/jaeger -n $NAMESPACE

echo "Installing KrakenD..."
helm install krakend ./helm/krakend -n $NAMESPACE

echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s

echo "Infrastructure installation complete!"
```

### port-forward-all.sh
```bash
#!/bin/bash

NAMESPACE="task-management"

echo "Setting up port forwarding..."

kubectl port-forward -n $NAMESPACE svc/krakend 8080:8080 &
kubectl port-forward -n $NAMESPACE svc/graylog 9000:9000 &
kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000 &
kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &
kubectl port-forward -n $NAMESPACE svc/jaeger 16686:16686 &

echo "Port forwarding active:"
echo "  KrakenD:    http://localhost:8080"
echo "  Graylog:    http://localhost:9000 (admin/admin)"
echo "  Grafana:    http://localhost:3000 (admin/admin)"
echo "  Prometheus: http://localhost:9090"
echo "  Jaeger:     http://localhost:16686"
echo ""
echo "Press Ctrl+C to stop port forwarding"

wait
```

### test-infrastructure.sh
```bash
#!/bin/bash
set -e

NAMESPACE="task-management"

echo "Testing infrastructure..."

# Check all pods are running
echo "Checking pod status..."
kubectl get pods -n $NAMESPACE

# Test PostgreSQL connections
echo "Testing PostgreSQL connections..."
kubectl exec -n $NAMESPACE auth-postgres-0 -- pg_isready -U auth_user
kubectl exec -n $NAMESPACE task-postgres-0 -- pg_isready -U task_user
kubectl exec -n $NAMESPACE notification-postgres-0 -- pg_isready -U notification_user

# Test Redis
echo "Testing Redis..."
kubectl exec -n $NAMESPACE $(kubectl get pod -n $NAMESPACE -l app=redis -o jsonpath='{.items[0].metadata.name}') -- redis-cli ping

# Test Kafka
echo "Testing Kafka..."
kubectl exec -n $NAMESPACE kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list

echo "All infrastructure tests passed!"
```

## Deliverables

1. **Helm Charts**: Complete charts for all infrastructure components
2. **KrakenD Configuration**: krakend.json with all routes
3. **Scripts**: Setup, installation, and testing scripts
4. **README.md**: Comprehensive setup and usage guide
5. **ARCHITECTURE.md**: System architecture documentation

## Success Criteria

- ✅ Minikube cluster starts successfully
- ✅ All 3 PostgreSQL instances running with persistent volumes
- ✅ Redis running and accessible
- ✅ Kafka running with topics auto-created
- ✅ KrakenD routing requests correctly
- ✅ Graylog receiving logs via GELF
- ✅ Prometheus scraping metrics from all services
- ✅ Grafana displaying dashboards
- ✅ Jaeger collecting traces
- ✅ All health probes passing
- ✅ All services can communicate

## Notes

- **Keep it simple**: Use single replicas for stateful services (except PostgreSQL)
- **Resource limits**: Set appropriate limits to fit in Minikube
- **Persistent volumes**: Use standard storage class
- **Secrets**: Use Kubernetes Secrets for sensitive data
- **Monitoring**: Ensure all services expose metrics
- **Logging**: Configure GELF appender in all services

