# Practical Work 8 - Microservices Task Management System

## Overview

Complete microservices-based Task Management System deployed on Kubernetes (Minikube) with comprehensive monitoring, logging, and tracing infrastructure.

## System Architecture

### Business Services (Spring Boot + Kotlin)
1. **Auth Service** (Port 8081)
   - User registration and authentication
   - JWT token management with Redis
   - Token validation endpoint

2. **Task Service** (Port 8082)
   - CRUD operations for tasks
   - Task filtering and pagination
   - Task statistics

3. **Notification Service** (Port 8083)
   - Consumes Kafka events
   - Stores notifications
   - Notification management API

### Infrastructure Services

#### Databases (PostgreSQL 15)
- **auth-postgres** - Auth Service database
- **task-postgres** - Task Service database
- **notification-postgres** - Notification Service database
- Pattern: 1 database per service
- Persistent volumes for data persistence

#### Message Broker
- **Apache Kafka** (KRaft mode)
  - Topics: `auth-events`, `task-events`
  - Event-driven communication between services

#### Cache & Session Storage
- **Redis 7**
  - JWT token storage
  - 24-hour TTL for tokens

#### API Gateway
- **KrakenD**
  - Single entry point for all services
  - Request routing
  - JWT validation
  - Rate limiting

#### Logging Stack
- **Graylog 5.2**
  - Centralized log aggregation
  - GELF UDP input (port 12201)
  - Logs: HTTP method, URL, IP address
- **MongoDB 6.0** - Graylog metadata
- **Elasticsearch 7.17** - Log storage

#### Monitoring Stack
- **Prometheus**
  - Metrics collection from services and databases
  - Service discovery via Kubernetes
- **Grafana**
  - Metrics visualization
  - Pre-configured dashboards
  - Login: admin/admin

#### Tracing
- **Jaeger**
  - Distributed tracing
  - Request flow visualization
  - Performance analysis

## Project Structure

```
practical-work-8/
├── auth-service/
│   ├── src/                    # Kotlin source code
│   ├── helm/                   # Helm chart
│   ├── docs/
│   │   └── PROMPT.md          # Implementation guide
│   ├── build.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── task-service/
│   ├── src/                    # Kotlin source code
│   ├── helm/                   # Helm chart
│   ├── docs/
│   │   └── PROMPT.md          # Implementation guide
│   ├── build.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── notification-service/
│   ├── src/                    # Kotlin source code
│   ├── helm/                   # Helm chart
│   ├── docs/
│   │   └── PROMPT.md          # Implementation guide
│   ├── build.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── infrastructure/
│   ├── helm/
│   │   ├── postgresql/         # 3 PostgreSQL instances
│   │   ├── redis/
│   │   ├── kafka/
│   │   ├── krakend/
│   │   ├── graylog/
│   │   ├── prometheus/
│   │   ├── grafana/
│   │   └── jaeger/
│   ├── krakend/
│   │   └── krakend.json       # API Gateway configuration
│   ├── scripts/
│   │   ├── setup-minikube.sh
│   │   ├── install-all.sh
│   │   ├── uninstall-all.sh
│   │   ├── port-forward-all.sh
│   │   └── test-infrastructure.sh
│   ├── docs/
│   │   ├── PROMPT.md          # Infrastructure setup guide
│   │   └── ARCHITECTURE.md
│   └── README.md
│
├── scripts/
│   ├── build-all.sh           # Build all services
│   ├── deploy-all.sh          # Deploy everything to Minikube
│   ├── test-system.sh         # End-to-end testing
│   └── cleanup-all.sh         # Remove everything
│
├── docs/
│   ├── API.md                 # API documentation
│   ├── DEPLOYMENT.md          # Deployment guide
│   └── TESTING.md             # Testing guide
│
├── report/
│   └── ПВКСП_Отчет8_ГрибковАС_ИКБО-16-22.md
│
└── README.md                  # This file
```

## Technology Stack

### Application Layer
- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2+
- **Build Tool**: Gradle (Kotlin DSL)
- **API Documentation**: OpenAPI/Swagger

### Infrastructure Layer
- **Container Orchestration**: Kubernetes (Minikube)
- **Package Manager**: Helm 3
- **API Gateway**: KrakenD 2.5+
- **Message Broker**: Apache Kafka 3.6+ (KRaft)
- **Cache**: Redis 7
- **Database**: PostgreSQL 15

### Observability Stack
- **Logging**: Graylog 5.2 + MongoDB 6.0 + Elasticsearch 7.17
- **Metrics**: Prometheus + Grafana
- **Tracing**: Jaeger 1.52+

## Prerequisites

### Required Software
- Docker Desktop or Colima
- Minikube
- kubectl
- Helm 3
- Java 21 (for local development)
- Gradle 8.5+ (or use wrapper)

### System Requirements
- **CPU**: 4 cores minimum
- **RAM**: 8GB minimum
- **Disk**: 20GB free space

## Quick Start

### 1. Setup Minikube

```bash
cd infrastructure
./scripts/setup-minikube.sh
```

This will:
- Delete existing Minikube cluster
- Start new cluster with 4 CPUs and 8GB RAM
- Enable Ingress and Metrics Server addons

### 2. Install Infrastructure

```bash
cd infrastructure
./scripts/install-all.sh
```

This installs:
- 3 PostgreSQL instances with persistent volumes
- Redis
- Kafka
- Graylog stack (Graylog + MongoDB + Elasticsearch)
- Prometheus
- Grafana
- Jaeger
- KrakenD API Gateway

Wait for all pods to be ready (~5 minutes).

### 3. Build and Deploy Services

```bash
cd ..
./scripts/build-all.sh
./scripts/deploy-all.sh
```

This will:
- Build Docker images for all 3 services
- Load images into Minikube
- Deploy services using Helm charts
- Configure HPA (Horizontal Pod Autoscaler)

### 4. Setup Port Forwarding

```bash
./scripts/port-forward-all.sh
```

Access services at:
- **KrakenD API Gateway**: http://localhost:8080
- **Graylog**: http://localhost:9000 (admin/admin)
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

### 5. Test System

```bash
./scripts/test-system.sh
```

This runs end-to-end tests:
- User registration
- User login
- Task creation
- Task updates
- Notification verification
- Kafka event verification
- Graylog log verification
- Prometheus metrics verification
- Jaeger trace verification

## API Usage Examples

### 1. Register User

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "SecurePass123!"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john_doe",
  "expiresIn": 86400
}
```

### 3. Create Task

```bash
TOKEN="your-jwt-token"

curl -X POST http://localhost:8080/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement authentication",
    "description": "Add JWT-based auth",
    "status": "PENDING"
  }'
```

### 4. Get Tasks

```bash
curl -X GET http://localhost:8080/tasks \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Get Notifications

```bash
curl -X GET http://localhost:8080/notifications \
  -H "Authorization: Bearer $TOKEN"
```

## Monitoring & Observability

### Grafana Dashboards

Access Grafana at http://localhost:3000 (admin/admin)

Pre-configured dashboard includes:
- Service health status
- HTTP request rate by service
- Request duration (p50, p95, p99)
- JVM memory usage
- Database connection pools
- Kafka consumer lag
- Error rates (4xx, 5xx)
- Pod CPU and memory usage

### Graylog Logs

Access Graylog at http://localhost:9000 (admin/admin)

Search queries:
- All logs: `*`
- Auth service: `application:auth-service`
- Task operations: `message:*task*`
- Errors: `level:ERROR`
- User actions: `user_id:1`

### Jaeger Traces

Access Jaeger at http://localhost:16686

View traces for:
- Complete request flow through API Gateway
- Service-to-service communication
- Database queries
- Kafka message publishing

### Prometheus Metrics

Access Prometheus at http://localhost:9090

Example queries:
- Request rate: `rate(http_server_requests_seconds_count[5m])`
- Memory usage: `jvm_memory_used_bytes`
- DB connections: `hikaricp_connections_active`
- Kafka lag: `kafka_consumer_lag`

## Kubernetes Features

### Persistent Volumes

All PostgreSQL instances use PersistentVolumeClaims:

```bash
kubectl get pvc -n task-management
```

Test persistence:
```bash
# Delete a pod
kubectl delete pod auth-postgres-0 -n task-management

# Pod recreates, data persists
kubectl exec -n task-management auth-postgres-0 -- psql -U auth_user -d auth_db -c "SELECT COUNT(*) FROM users;"
```

### Horizontal Pod Autoscaling

All services configured with HPA (60% CPU/Memory target):

```bash
kubectl get hpa -n task-management
```

Test autoscaling:
```bash
# Generate load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://task-service:8082/api/tasks; done"

# Watch scaling
kubectl get hpa -n task-management --watch
```

### Health Probes

All services have:
- **Liveness Probe**: Restarts pod if unhealthy
- **Readiness Probe**: Removes from service if not ready
- **Startup Probe**: Allows slow startup

View probe status:
```bash
kubectl describe pod <pod-name> -n task-management
```

### Resource Limits

All pods have CPU and memory limits:

```bash
kubectl top pods -n task-management
```

## Development Guide

### Local Development

Each service can run locally:

```bash
# Auth Service
cd auth-service
./gradlew bootRun

# Task Service
cd task-service
./gradlew bootRun

# Notification Service
cd notification-service
./gradlew bootRun
```

### Running Tests

```bash
# Unit tests
./gradlew test

# Integration tests
./gradlew integrationTest

# Test coverage report
./gradlew jacocoTestReport
```

### Building Docker Images

```bash
# Single service
cd auth-service
docker build -t auth-service:latest .

# All services
./scripts/build-all.sh
```

## Troubleshooting

### Pods Not Starting

```bash
kubectl get pods -n task-management
kubectl describe pod <pod-name> -n task-management
kubectl logs <pod-name> -n task-management
```

### Database Connection Issues

```bash
# Test PostgreSQL
kubectl exec -n task-management auth-postgres-0 -- pg_isready -U auth_user

# Check credentials
kubectl get secret auth-postgres-secret -n task-management -o yaml
```

### Kafka Issues

```bash
# Check Kafka logs
kubectl logs kafka-0 -n task-management

# List topics
kubectl exec -n task-management kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list

# Check consumer groups
kubectl exec -n task-management kafka-0 -- kafka-consumer-groups --bootstrap-server localhost:9092 --list
```

### Service Communication

```bash
# Test service-to-service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://auth-service:8081/actuator/health
```

## Cleanup

### Remove Everything

```bash
./scripts/cleanup-all.sh
```

Or manually:

```bash
# Delete services
helm uninstall auth-service task-service notification-service -n task-management

# Delete infrastructure
cd infrastructure
./scripts/uninstall-all.sh

# Delete namespace
kubectl delete namespace task-management

# Delete Minikube cluster
minikube delete
```

## Implementation Order

Follow this order for implementation:

1. **Infrastructure** (Week 1)
   - Setup Minikube
   - Deploy PostgreSQL instances
   - Deploy Redis, Kafka
   - Deploy monitoring stack

2. **Auth Service** (Week 1-2)
   - Implement user registration/login
   - JWT token management
   - Redis integration
   - Kafka event publishing

3. **Task Service** (Week 2)
   - Implement CRUD operations
   - Auth service integration
   - Kafka event publishing

4. **Notification Service** (Week 2)
   - Kafka consumer
   - Notification storage
   - API endpoints

5. **KrakenD Gateway** (Week 3)
   - Configure routes
   - JWT validation
   - Integration testing

6. **Monitoring & Logging** (Week 3)
   - Graylog configuration
   - Grafana dashboards
   - Jaeger tracing

7. **Testing & Documentation** (Week 3-4)
   - End-to-end tests
   - Report preparation
   - Screenshots

## Report Requirements

Document in report:
1. ✅ System architecture diagram
2. ✅ Helm charts for all services
3. ✅ KrakenD configuration
4. ✅ Working system with authentication
5. ✅ Persistent volume demonstration (delete pod, data persists)
6. ✅ Kafka message flow
7. ✅ Jaeger traces
8. ✅ Prometheus metrics
9. ✅ Grafana dashboards
10. ✅ Graylog logs with HTTP method, URL, IP

## Questions for Defense

1. **Helm advantages/disadvantages, alternatives?**
   - Advantages: templating, versioning, rollbacks
   - Disadvantages: complexity, learning curve
   - Alternatives: Kustomize, raw YAML

2. **Why message bus for microservices?**
   - Asynchronous communication
   - Loose coupling
   - Alternatives: REST, gRPC, GraphQL

3. **Persistent volumes in databases?**
   - Data persistence across pod restarts
   - "1 DB per service" pros: isolation, independence
   - "1 DB per service" cons: complexity, transactions

4. **Separate monitoring user in DB?**
   - Principle of least privilege
   - Security: limits damage from compromised credentials

5. **KrakenD functionality and alternatives?**
   - API Gateway: routing, auth, rate limiting
   - Alternatives: Kong, Traefik, NGINX, AWS API Gateway

## Author

Gribkov A.S., IKBO-16-22

## License

Educational project for MIREA

