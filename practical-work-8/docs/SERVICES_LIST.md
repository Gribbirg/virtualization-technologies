# Complete Services List

## Summary

**Total Services to Deploy**: 15-16 pods/services

### Business Services: 3
- Auth Service
- Task Service  
- Notification Service

### Infrastructure Services: 12-13
- PostgreSQL (3 instances)
- Redis
- Kafka
- KrakenD
- Graylog
- MongoDB (for Graylog)
- Elasticsearch (for Graylog)
- Prometheus
- Grafana
- Jaeger

---

## Detailed Service List

### 1. Auth Service ⭐ (Business Logic)

**Type**: Spring Boot Application (Kotlin)  
**Port**: 8081  
**Replicas**: 2-5 (HPA)  
**Purpose**: User authentication and authorization

**Dependencies:**
- auth-postgres (database)
- redis (token storage)
- kafka (event publishing)

**Endpoints:**
- POST `/api/auth/register` - User registration
- POST `/api/auth/login` - User login (returns JWT)
- GET `/api/auth/validate` - Token validation
- POST `/api/auth/logout` - User logout
- GET `/api/auth/me` - Get current user info

**Resources:**
- CPU: 500m request, 1000m limit
- Memory: 512Mi request, 1Gi limit

**Health Probes:**
- Liveness: `/actuator/health/liveness`
- Readiness: `/actuator/health/readiness`
- Startup: `/actuator/health/startup`

**Observability:**
- Logs: GELF to Graylog (port 12201)
- Metrics: Prometheus (port 8081/actuator/prometheus)
- Traces: Jaeger integration

---

### 2. Task Service ⭐ (Business Logic)

**Type**: Spring Boot Application (Kotlin)  
**Port**: 8082  
**Replicas**: 2-5 (HPA)  
**Purpose**: Task management (CRUD operations)

**Dependencies:**
- task-postgres (database)
- kafka (event publishing)
- auth-service (token validation)

**Endpoints:**
- POST `/api/tasks` - Create task
- GET `/api/tasks` - List tasks (with filters)
- GET `/api/tasks/{id}` - Get task by ID
- PUT `/api/tasks/{id}` - Update task
- DELETE `/api/tasks/{id}` - Delete task
- GET `/api/tasks/stats` - Task statistics

**Resources:**
- CPU: 500m request, 1000m limit
- Memory: 512Mi request, 1Gi limit

**Health Probes:**
- Liveness: `/actuator/health/liveness`
- Readiness: `/actuator/health/readiness`
- Startup: `/actuator/health/startup`

**Observability:**
- Logs: GELF to Graylog
- Metrics: Prometheus
- Traces: Jaeger integration

---

### 3. Notification Service ⭐ (Business Logic)

**Type**: Spring Boot Application (Kotlin)  
**Port**: 8083  
**Replicas**: 2-4 (HPA)  
**Purpose**: Notification management and Kafka event consumption

**Dependencies:**
- notification-postgres (database)
- kafka (event consumption)
- auth-service (token validation)

**Endpoints:**
- GET `/api/notifications` - List notifications
- GET `/api/notifications/{id}` - Get notification by ID
- POST `/api/notifications/{id}/read` - Mark as read
- POST `/api/notifications/read-all` - Mark all as read
- GET `/api/notifications/unread-count` - Get unread count
- DELETE `/api/notifications/{id}` - Delete notification

**Resources:**
- CPU: 300m request, 500m limit
- Memory: 256Mi request, 512Mi limit

**Health Probes:**
- Liveness: `/actuator/health/liveness`
- Readiness: `/actuator/health/readiness`
- Startup: `/actuator/health/startup`

**Observability:**
- Logs: GELF to Graylog
- Metrics: Prometheus
- Traces: Jaeger integration

---

### 4. auth-postgres 💾 (Database)

**Type**: PostgreSQL 15 StatefulSet  
**Port**: 5432  
**Replicas**: 1  
**Purpose**: Database for Auth Service

**Database**: `auth_db`  
**User**: `auth_user`  
**Tables**: `users`

**Storage:**
- PersistentVolume: 1Gi
- StorageClass: standard
- Access Mode: ReadWriteOnce

**Configuration:**
- Max connections: 100
- Shared buffers: 128MB
- Monitoring user: `monitoring` (read-only)

**Resources:**
- CPU: 250m request, 500m limit
- Memory: 256Mi request, 512Mi limit

**Health Probes:**
- Liveness: `pg_isready -U auth_user`
- Readiness: `pg_isready -U auth_user`

---

### 5. task-postgres 💾 (Database)

**Type**: PostgreSQL 15 StatefulSet  
**Port**: 5432  
**Replicas**: 1  
**Purpose**: Database for Task Service

**Database**: `task_db`  
**User**: `task_user`  
**Tables**: `tasks`

**Storage:**
- PersistentVolume: 1Gi
- StorageClass: standard
- Access Mode: ReadWriteOnce

**Configuration:**
- Max connections: 100
- Shared buffers: 128MB
- Monitoring user: `monitoring` (read-only)

**Resources:**
- CPU: 250m request, 500m limit
- Memory: 256Mi request, 512Mi limit

---

### 6. notification-postgres 💾 (Database)

**Type**: PostgreSQL 15 StatefulSet  
**Port**: 5432  
**Replicas**: 1  
**Purpose**: Database for Notification Service

**Database**: `notification_db`  
**User**: `notification_user`  
**Tables**: `notifications`

**Storage:**
- PersistentVolume: 1Gi
- StorageClass: standard
- Access Mode: ReadWriteOnce

**Configuration:**
- Max connections: 100
- Shared buffers: 128MB
- Monitoring user: `monitoring` (read-only)

**Resources:**
- CPU: 250m request, 500m limit
- Memory: 256Mi request, 512Mi limit

---

### 7. Redis 🔴 (Cache)

**Type**: Redis 7 Deployment  
**Port**: 6379  
**Replicas**: 1  
**Purpose**: JWT token storage for Auth Service

**Configuration:**
- Max memory: 128MB
- Eviction policy: allkeys-lru
- Persistence: AOF enabled
- Password protected

**Storage:**
- Ephemeral (tokens expire in 24h)

**Resources:**
- CPU: 100m request, 200m limit
- Memory: 128Mi request, 256Mi limit

**Health Probes:**
- Liveness: `redis-cli ping`
- Readiness: `redis-cli ping`

---

### 8. Kafka 📨 (Message Broker)

**Type**: Kafka 3.6+ StatefulSet (KRaft mode)  
**Port**: 9092  
**Replicas**: 1  
**Purpose**: Event streaming between services

**Topics:**
- `auth-events` (3 partitions)
- `task-events` (3 partitions)

**Configuration:**
- Mode: KRaft (no Zookeeper needed)
- Auto-create topics: enabled
- Replication factor: 1

**Storage:**
- PersistentVolume: 2Gi

**Resources:**
- CPU: 500m request, 1000m limit
- Memory: 512Mi request, 1Gi limit

---

### 9. KrakenD 🚪 (API Gateway)

**Type**: KrakenD 2.5+ Deployment  
**Ports**: 8080 (API), 8090 (metrics)  
**Replicas**: 2  
**Purpose**: Single entry point, routing, JWT validation

**Routes:**
- `/auth/*` → Auth Service (8081)
- `/tasks/*` → Task Service (8082)
- `/notifications/*` → Notification Service (8083)

**Features:**
- JWT validation
- Request routing
- Rate limiting
- Metrics export
- Jaeger tracing

**Resources:**
- CPU: 200m request, 500m limit
- Memory: 256Mi request, 512Mi limit

**Configuration:**
- Config file: `krakend.json`
- Mounted via ConfigMap

---

### 10. Graylog 📋 (Log Aggregation)

**Type**: Graylog 5.2 Deployment  
**Ports**: 9000 (UI), 12201 (GELF UDP)  
**Replicas**: 1  
**Purpose**: Centralized logging

**Dependencies:**
- mongodb (metadata storage)
- elasticsearch (log storage)

**Configuration:**
- Admin user: admin
- Admin password: admin
- Input: GELF UDP (port 12201)

**Resources:**
- CPU: 500m request, 1000m limit
- Memory: 1Gi request, 2Gi limit

**Access:**
- Web UI: http://localhost:9000
- Credentials: admin/admin

---

### 11. MongoDB 🍃 (Graylog Metadata)

**Type**: MongoDB 6.0 StatefulSet  
**Port**: 27017  
**Replicas**: 1  
**Purpose**: Graylog metadata storage

**Configuration:**
- Root user: admin
- Authentication enabled

**Storage:**
- PersistentVolume: 1Gi

**Resources:**
- CPU: 250m request, 500m limit
- Memory: 256Mi request, 512Mi limit

---

### 12. Elasticsearch 🔍 (Log Storage)

**Type**: Elasticsearch 7.17 StatefulSet  
**Port**: 9200  
**Replicas**: 1  
**Purpose**: Graylog log storage backend

**Configuration:**
- Single-node mode
- Security disabled (for simplicity)
- JVM heap: 512MB

**Storage:**
- PersistentVolume: 2Gi

**Resources:**
- CPU: 500m request, 1000m limit
- Memory: 1Gi request, 2Gi limit

---

### 13. Prometheus 📊 (Metrics Collection)

**Type**: Prometheus Latest Deployment  
**Port**: 9090  
**Replicas**: 1  
**Purpose**: Metrics collection from all services

**Scrape Targets:**
- auth-service:8081/actuator/prometheus
- task-service:8082/actuator/prometheus
- notification-service:8083/actuator/prometheus
- auth-postgres:5432 (via postgres_exporter)
- task-postgres:5432 (via postgres_exporter)
- notification-postgres:5432 (via postgres_exporter)
- krakend:8090/metrics

**Configuration:**
- Scrape interval: 15s
- Retention: 15 days

**Resources:**
- CPU: 300m request, 500m limit
- Memory: 512Mi request, 1Gi limit

**Access:**
- Web UI: http://localhost:9090

---

### 14. Grafana 📈 (Metrics Visualization)

**Type**: Grafana Latest Deployment  
**Port**: 3000  
**Replicas**: 1  
**Purpose**: Metrics visualization and dashboards

**Datasource:**
- Prometheus (auto-configured)

**Dashboards:**
- Task Management System Overview
- Service Health
- JVM Metrics
- Database Metrics
- HTTP Request Metrics

**Resources:**
- CPU: 200m request, 500m limit
- Memory: 256Mi request, 512Mi limit

**Access:**
- Web UI: http://localhost:3000
- Credentials: admin/admin

---

### 15. Jaeger 🔎 (Distributed Tracing)

**Type**: Jaeger 1.52+ All-in-One Deployment  
**Ports**: 16686 (UI), 14268 (collector), 14250 (gRPC)  
**Replicas**: 1  
**Purpose**: Distributed tracing across services

**Configuration:**
- All-in-one mode (collector + query + UI)
- In-memory storage (for simplicity)
- OTLP enabled

**Resources:**
- CPU: 200m request, 500m limit
- Memory: 256Mi request, 512Mi limit

**Access:**
- Web UI: http://localhost:16686

---

## Service Communication Matrix

| From | To | Protocol | Purpose |
|------|-----|----------|---------|
| User | KrakenD | HTTP | API requests |
| KrakenD | Auth Service | HTTP | Authentication |
| KrakenD | Task Service | HTTP | Task operations |
| KrakenD | Notification Service | HTTP | Notifications |
| Auth Service | auth-postgres | PostgreSQL | User data |
| Auth Service | Redis | Redis Protocol | Token storage |
| Auth Service | Kafka | Kafka Protocol | Publish events |
| Task Service | task-postgres | PostgreSQL | Task data |
| Task Service | Kafka | Kafka Protocol | Publish events |
| Task Service | Auth Service | HTTP | Token validation |
| Notification Service | notification-postgres | PostgreSQL | Notification data |
| Notification Service | Kafka | Kafka Protocol | Consume events |
| Notification Service | Auth Service | HTTP | Token validation |
| All Services | Graylog | GELF UDP | Log shipping |
| Prometheus | All Services | HTTP | Metrics scraping |
| Prometheus | PostgreSQL | HTTP | DB metrics |
| Grafana | Prometheus | HTTP | Query metrics |
| KrakenD | Jaeger | HTTP | Send traces |
| All Services | Jaeger | HTTP | Send traces |

---

## Resource Summary

### Total Resource Requests
- **CPU**: ~5.5 cores
- **Memory**: ~7.5 GB

### Total Resource Limits
- **CPU**: ~10 cores
- **Memory**: ~14 GB

### Storage Requirements
- **PostgreSQL**: 3 × 1Gi = 3Gi
- **Kafka**: 2Gi
- **MongoDB**: 1Gi
- **Elasticsearch**: 2Gi
- **Total**: 8Gi

### Recommended Minikube Configuration
```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g
```

---

## Deployment Order

### Phase 1: Storage & Messaging
1. PostgreSQL instances (auth, task, notification)
2. Redis
3. Kafka

### Phase 2: Observability Infrastructure
4. MongoDB
5. Elasticsearch
6. Graylog
7. Prometheus
8. Grafana
9. Jaeger

### Phase 3: Business Services
10. Auth Service
11. Task Service
12. Notification Service

### Phase 4: Gateway
13. KrakenD

---

## Port Forwarding Commands

```bash
# API Gateway
kubectl port-forward -n task-management svc/krakend 8080:8080

# Monitoring UIs
kubectl port-forward -n task-management svc/graylog 9000:9000
kubectl port-forward -n task-management svc/grafana 3000:3000
kubectl port-forward -n task-management svc/prometheus 9090:9090
kubectl port-forward -n task-management svc/jaeger 16686:16686

# Direct service access (for debugging)
kubectl port-forward -n task-management svc/auth-service 8081:8081
kubectl port-forward -n task-management svc/task-service 8082:8082
kubectl port-forward -n task-management svc/notification-service 8083:8083

# Databases (for debugging)
kubectl port-forward -n task-management svc/auth-postgres 5432:5432
kubectl port-forward -n task-management svc/task-postgres 5433:5432
kubectl port-forward -n task-management svc/notification-postgres 5434:5432

# Redis (for debugging)
kubectl port-forward -n task-management svc/redis 6379:6379

# Kafka (for debugging)
kubectl port-forward -n task-management svc/kafka 9092:9092
```

---

## Service URLs (After Port Forwarding)

| Service | URL | Credentials |
|---------|-----|-------------|
| KrakenD API | http://localhost:8080 | - |
| Graylog | http://localhost:9000 | admin/admin |
| Grafana | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Jaeger | http://localhost:16686 | - |
| Auth Service | http://localhost:8081 | - |
| Task Service | http://localhost:8082 | - |
| Notification Service | http://localhost:8083 | - |

---

## Verification Commands

```bash
# Check all pods
kubectl get pods -n task-management

# Check all services
kubectl get svc -n task-management

# Check persistent volumes
kubectl get pvc -n task-management

# Check HPA status
kubectl get hpa -n task-management

# Check resource usage
kubectl top pods -n task-management

# Check logs
kubectl logs -n task-management <pod-name>

# Describe pod (for troubleshooting)
kubectl describe pod -n task-management <pod-name>
```

---

## Conclusion

This system consists of **15-16 services** working together to provide:
- ✅ Complete microservices architecture
- ✅ Event-driven communication
- ✅ Centralized logging
- ✅ Comprehensive metrics
- ✅ Distributed tracing
- ✅ Data persistence
- ✅ Horizontal scaling
- ✅ High availability

All services are containerized, deployed on Kubernetes, and fully observable.

