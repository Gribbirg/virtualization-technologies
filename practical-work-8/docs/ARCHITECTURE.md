# System Architecture

## Overview

Task Management System is a microservices-based application deployed on Kubernetes with comprehensive observability stack.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              External Users                              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   KrakenD API Gateway  │
                    │    (LoadBalancer)      │
                    │   Port: 8080           │
                    └────────────┬───────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
                 ▼               ▼               ▼
        ┌────────────┐  ┌────────────┐  ┌────────────┐
        │   Auth     │  │   Task     │  │Notification│
        │  Service   │  │  Service   │  │  Service   │
        │  (8081)    │  │  (8082)    │  │  (8083)    │
        │  [2-5 pods]│  │ [2-5 pods] │  │ [2-4 pods] │
        └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
              │               │               │
              │               │               │
    ┌─────────┼───────────────┼───────────────┼─────────┐
    │         │               │               │         │
    │         ▼               ▼               ▼         │
    │  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
    │  │   Auth     │  │   Task     │  │Notification│ │
    │  │ PostgreSQL │  │ PostgreSQL │  │ PostgreSQL │ │
    │  │  (5432)    │  │  (5432)    │  │  (5432)    │ │
    │  │ [PV: 1Gi]  │  │ [PV: 1Gi]  │  │ [PV: 1Gi]  │ │
    │  └────────────┘  └────────────┘  └────────────┘ │
    │                                                   │
    │  ┌────────────┐         ┌────────────┐          │
    │  │   Redis    │         │   Kafka    │          │
    │  │  (6379)    │◄────────┤  (9092)    │          │
    │  │ Token Store│         │ Event Bus  │          │
    │  └────────────┘         └──────┬─────┘          │
    │         ▲                       │                │
    │         │                       │                │
    │         └───────────────────────┘                │
    │                                                   │
    └───────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │ Graylog │    │Prometheus│   │ Jaeger  │
    │ (9000)  │    │ (9090)   │   │ (16686) │
    │  Logs   │    │ Metrics  │   │ Traces  │
    └────┬────┘    └─────┬────┘   └─────────┘
         │               │
         ▼               ▼
    ┌─────────┐    ┌─────────┐
    │Elastic  │    │ Grafana │
    │ Search  │    │ (3000)  │
    │ (9200)  │    │Dashboard│
    └─────────┘    └─────────┘
         │
         ▼
    ┌─────────┐
    │ MongoDB │
    │ (27017) │
    └─────────┘
```

## Component Details

### Business Services Layer

#### 1. Auth Service
- **Purpose**: User authentication and authorization
- **Port**: 8081
- **Database**: auth-postgres (auth_db)
- **Cache**: Redis (token storage)
- **Replicas**: 2-5 (HPA at 60% CPU/Memory)
- **Resources**: 
  - Request: 500m CPU, 512Mi RAM
  - Limit: 1000m CPU, 1Gi RAM

**Responsibilities:**
- User registration
- User login (JWT generation)
- Token validation
- Token storage in Redis (24h TTL)
- Publish auth events to Kafka

**API Endpoints:**
- POST `/api/auth/register`
- POST `/api/auth/login`
- GET `/api/auth/validate`
- POST `/api/auth/logout`
- GET `/api/auth/me`

#### 2. Task Service
- **Purpose**: Task management
- **Port**: 8082
- **Database**: task-postgres (task_db)
- **Replicas**: 2-5 (HPA at 60% CPU/Memory)
- **Resources**: 
  - Request: 500m CPU, 512Mi RAM
  - Limit: 1000m CPU, 1Gi RAM

**Responsibilities:**
- CRUD operations for tasks
- Task filtering by status
- Task statistics
- Validate tokens with Auth Service
- Publish task events to Kafka

**API Endpoints:**
- POST `/api/tasks`
- GET `/api/tasks`
- GET `/api/tasks/{id}`
- PUT `/api/tasks/{id}`
- DELETE `/api/tasks/{id}`
- GET `/api/tasks/stats`

#### 3. Notification Service
- **Purpose**: Notification management
- **Port**: 8083
- **Database**: notification-postgres (notification_db)
- **Replicas**: 2-4 (HPA at 60% CPU/Memory)
- **Resources**: 
  - Request: 300m CPU, 256Mi RAM
  - Limit: 500m CPU, 512Mi RAM

**Responsibilities:**
- Consume events from Kafka
- Store notifications
- Notification CRUD operations
- Mark notifications as read

**API Endpoints:**
- GET `/api/notifications`
- GET `/api/notifications/{id}`
- POST `/api/notifications/{id}/read`
- POST `/api/notifications/read-all`
- GET `/api/notifications/unread-count`
- DELETE `/api/notifications/{id}`

### Data Layer

#### PostgreSQL Instances (3x)
- **Version**: PostgreSQL 15
- **Pattern**: 1 database per service
- **Storage**: PersistentVolume (1Gi each)
- **Resources per instance**:
  - Request: 250m CPU, 256Mi RAM
  - Limit: 500m CPU, 512Mi RAM

**Configuration:**
- Max connections: 100
- Shared buffers: 128MB
- Monitoring user: read-only access for Prometheus

**Databases:**
1. `auth_db` - users table
2. `task_db` - tasks table
3. `notification_db` - notifications table

#### Redis
- **Version**: Redis 7
- **Purpose**: JWT token storage
- **Storage**: Ephemeral (tokens expire in 24h)
- **Resources**:
  - Request: 100m CPU, 128Mi RAM
  - Limit: 200m CPU, 256Mi RAM

**Configuration:**
- Max memory: 128MB
- Eviction policy: allkeys-lru
- Persistence: AOF enabled

### Message Broker

#### Apache Kafka
- **Version**: 3.6+
- **Mode**: KRaft (no Zookeeper)
- **Replicas**: 1 broker (sufficient for dev/test)
- **Resources**:
  - Request: 500m CPU, 512Mi RAM
  - Limit: 1000m CPU, 1Gi RAM

**Topics:**
- `auth-events` (3 partitions)
  - USER_REGISTERED
  - USER_LOGGED_IN
  - USER_LOGGED_OUT
  
- `task-events` (3 partitions)
  - TASK_CREATED
  - TASK_UPDATED
  - TASK_COMPLETED
  - TASK_DELETED

**Consumer Groups:**
- `notification-service-group`

### API Gateway

#### KrakenD
- **Version**: 2.5+
- **Purpose**: Single entry point, routing, JWT validation
- **Replicas**: 2
- **Resources**:
  - Request: 200m CPU, 256Mi RAM
  - Limit: 500m CPU, 512Mi RAM

**Features:**
- Request routing to services
- JWT validation (for protected endpoints)
- Rate limiting
- Request/response transformation
- Metrics export (port 8090)
- Jaeger tracing integration

**Routes:**
- `/auth/*` → Auth Service
- `/tasks/*` → Task Service
- `/notifications/*` → Notification Service

### Observability Stack

#### Graylog (Logging)
- **Version**: 5.2
- **Components**:
  - Graylog Server (9000)
  - MongoDB 6.0 (metadata)
  - Elasticsearch 7.17 (log storage)
- **Input**: GELF UDP (port 12201)

**Resources (Graylog):**
- Request: 500m CPU, 1Gi RAM
- Limit: 1000m CPU, 2Gi RAM

**Log Fields:**
- application (service name)
- level (INFO, WARN, ERROR)
- message
- timestamp
- http_method
- url
- ip_address
- user_id

#### Prometheus (Metrics)
- **Version**: Latest
- **Scrape Interval**: 15s
- **Resources**:
  - Request: 300m CPU, 512Mi RAM
  - Limit: 500m CPU, 1Gi RAM

**Scrape Targets:**
- All 3 business services (Actuator endpoints)
- All 3 PostgreSQL instances (postgres_exporter)
- KrakenD metrics endpoint

**Metrics Collected:**
- JVM metrics (heap, threads, GC)
- HTTP metrics (rate, duration, status codes)
- Database metrics (connections, transactions)
- Kafka metrics (consumer lag)
- Custom business metrics

#### Grafana (Visualization)
- **Version**: Latest
- **Datasource**: Prometheus
- **Resources**:
  - Request: 200m CPU, 256Mi RAM
  - Limit: 500m CPU, 512Mi RAM

**Dashboards:**
1. Service Health Overview
2. HTTP Request Metrics
3. JVM Memory & Threads
4. Database Connections
5. Kafka Consumer Lag
6. Error Rates
7. Pod Resources

#### Jaeger (Tracing)
- **Version**: 1.52+
- **Mode**: All-in-one deployment
- **Resources**:
  - Request: 200m CPU, 256Mi RAM
  - Limit: 500m CPU, 512Mi RAM

**Traces:**
- Complete request flow through API Gateway
- Service-to-service calls
- Database queries
- Kafka message publishing

## Communication Patterns

### Synchronous Communication (REST)
```
User → KrakenD → Service → PostgreSQL
     ←         ←         ←
```

**Flow:**
1. User sends request to KrakenD
2. KrakenD validates JWT (if required)
3. KrakenD routes to appropriate service
4. Service processes request
5. Service queries database
6. Response flows back

### Asynchronous Communication (Kafka)
```
Auth Service → Kafka → Notification Service
Task Service →      →
```

**Flow:**
1. Service publishes event to Kafka topic
2. Kafka stores event
3. Notification Service consumes event
4. Notification created in database

### Token Validation
```
Task Service → Auth Service → Redis
             ←               ←
```

**Flow:**
1. Task Service extracts JWT from request
2. Task Service calls Auth Service `/validate`
3. Auth Service checks Redis for token
4. Auth Service verifies JWT signature
5. Returns user info if valid

## Data Flow Examples

### User Registration Flow
```
1. User → KrakenD POST /auth/register
2. KrakenD → Auth Service
3. Auth Service → PostgreSQL (insert user)
4. Auth Service → Kafka (USER_REGISTERED event)
5. Kafka → Notification Service
6. Notification Service → PostgreSQL (insert notification)
7. Auth Service → KrakenD → User (success response)
```

### Task Creation Flow
```
1. User → KrakenD POST /tasks (with JWT)
2. KrakenD → Task Service
3. Task Service → Auth Service /validate (check token)
4. Auth Service → Redis (check token exists)
5. Auth Service → Task Service (user info)
6. Task Service → PostgreSQL (insert task)
7. Task Service → Kafka (TASK_CREATED event)
8. Kafka → Notification Service
9. Notification Service → PostgreSQL (insert notification)
10. Task Service → KrakenD → User (task response)
```

### Notification Retrieval Flow
```
1. User → KrakenD GET /notifications (with JWT)
2. KrakenD → Notification Service
3. Notification Service → Auth Service /validate
4. Auth Service → Redis (check token)
5. Auth Service → Notification Service (user info)
6. Notification Service → PostgreSQL (query notifications)
7. Notification Service → KrakenD → User (notifications list)
```

## Kubernetes Resources

### Namespace
- `task-management` - all resources deployed here

### Deployments
- `auth-service` (2-5 replicas)
- `task-service` (2-5 replicas)
- `notification-service` (2-4 replicas)
- `krakend` (2 replicas)
- `graylog` (1 replica)
- `grafana` (1 replica)
- `jaeger` (1 replica)
- `prometheus` (1 replica)
- `redis` (1 replica)

### StatefulSets
- `auth-postgres` (1 replica)
- `task-postgres` (1 replica)
- `notification-postgres` (1 replica)
- `kafka` (1 replica)
- `mongodb` (1 replica)
- `elasticsearch` (1 replica)

### Services (ClusterIP)
- All deployments have corresponding services
- KrakenD also exposed as LoadBalancer

### PersistentVolumeClaims
- `auth-postgres-data` (1Gi)
- `task-postgres-data` (1Gi)
- `notification-postgres-data` (1Gi)
- `kafka-data` (2Gi)
- `mongodb-data` (1Gi)
- `elasticsearch-data` (2Gi)

### HorizontalPodAutoscalers
- `auth-service-hpa` (2-5 replicas, 60% CPU/Memory)
- `task-service-hpa` (2-5 replicas, 60% CPU/Memory)
- `notification-service-hpa` (2-4 replicas, 60% CPU/Memory)

### ConfigMaps
- Service configurations (non-sensitive)
- Kafka topics
- Prometheus scrape configs
- Grafana datasources
- KrakenD routing config

### Secrets
- Database credentials
- JWT secrets
- Redis passwords
- Graylog admin password

## Security Considerations

### Authentication & Authorization
- JWT tokens for user authentication
- Token validation on every protected request
- Tokens stored in Redis with TTL
- Secure password hashing (BCrypt)

### Network Security
- Services communicate within cluster (ClusterIP)
- Only KrakenD exposed externally (LoadBalancer)
- No direct access to databases from outside

### Secrets Management
- Sensitive data stored in Kubernetes Secrets
- Secrets mounted as environment variables
- No hardcoded credentials

### Database Security
- Separate databases per service
- Read-only monitoring user
- Connection pooling with limits

## Scalability

### Horizontal Scaling
- All services are stateless
- HPA scales based on CPU/Memory
- Multiple replicas for high availability

### Vertical Scaling
- Resource limits can be increased
- Database resources can be adjusted

### Data Scaling
- PostgreSQL can be upgraded to larger storage
- Kafka partitions allow parallel processing
- Redis can be configured with more memory

## High Availability

### Service Redundancy
- Multiple replicas for each service
- Load balancing via Kubernetes Services

### Data Persistence
- PostgreSQL with persistent volumes
- Data survives pod restarts

### Failure Recovery
- Liveness probes restart unhealthy pods
- Readiness probes remove unhealthy pods from service
- Kafka retains messages for reprocessing

## Monitoring Strategy

### Metrics Collection
- Prometheus scrapes all services every 15s
- Custom business metrics tracked
- Infrastructure metrics from Kubernetes

### Log Aggregation
- All services send logs to Graylog via GELF
- Centralized log search and analysis
- Log retention configurable

### Distributed Tracing
- Jaeger traces requests across services
- Performance bottleneck identification
- Error tracking

### Alerting (Future)
- Prometheus Alertmanager
- Alerts on high error rates
- Alerts on resource exhaustion

## Performance Considerations

### Caching
- Redis caches JWT tokens
- Reduces Auth Service load
- 5-minute cache for token validation

### Database Optimization
- Indexes on frequently queried columns
- Connection pooling
- Query optimization

### Asynchronous Processing
- Kafka decouples services
- Non-blocking event processing
- Improved response times

## Deployment Strategy

### Rolling Updates
- Zero-downtime deployments
- Gradual pod replacement
- Rollback capability

### Health Checks
- Startup probes for slow-starting services
- Readiness probes before serving traffic
- Liveness probes for failure detection

### Resource Management
- Resource requests guarantee minimum
- Resource limits prevent overconsumption
- QoS classes for pod prioritization

## Future Enhancements

### Potential Improvements
1. Add Redis cluster for HA
2. Add Kafka replication
3. Implement PostgreSQL replication
4. Add API rate limiting per user
5. Implement circuit breakers
6. Add service mesh (Istio/Linkerd)
7. Implement GitOps with ArgoCD
8. Add automated backups
9. Implement blue-green deployments
10. Add integration with external auth (OAuth2)

## Conclusion

This architecture provides:
- ✅ Microservices isolation
- ✅ Event-driven communication
- ✅ Comprehensive observability
- ✅ Horizontal scalability
- ✅ High availability
- ✅ Data persistence
- ✅ Security best practices
- ✅ Production-ready patterns

