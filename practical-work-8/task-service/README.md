# Task Service

Task Management microservice built with Spring Boot and Kotlin for Practical Work 8.

## Overview

Task Service provides CRUD operations for tasks with JWT authentication, Kafka event publishing, and comprehensive observability.

## Features

- ✅ Task CRUD operations (Create, Read, Update, Delete)
- ✅ Task filtering by status and pagination
- ✅ Task statistics endpoint
- ✅ JWT authentication via Auth Service
- ✅ Kafka event publishing (task.created, task.updated, task.deleted, task.completed)
- ✅ PostgreSQL database with indexes
- ✅ Token validation caching (5 minutes)
- ✅ Graylog logging via GELF
- ✅ Prometheus metrics
- ✅ Swagger/OpenAPI documentation
- ✅ Health probes (liveness, readiness, startup)
- ✅ Horizontal Pod Autoscaler support

## Technology Stack

- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2
- **Build Tool**: Gradle 8.5 (Kotlin DSL)
- **Database**: PostgreSQL 15
- **Message Broker**: Apache Kafka
- **Cache**: Caffeine (in-memory)
- **Logging**: Logback with GELF appender
- **Metrics**: Micrometer + Prometheus
- **API Docs**: SpringDoc OpenAPI

## Prerequisites

- Java 21
- Docker (for PostgreSQL and Kafka)
- Gradle 8.5+ (or use wrapper)

## Database Schema

```sql
CREATE TABLE tasks (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);
```

### Task Status Enum
- `PENDING` - Task created, not started
- `IN_PROGRESS` - Task is being worked on
- `COMPLETED` - Task finished
- `CANCELLED` - Task cancelled

## API Endpoints

### Base Path: `/api/tasks`

All endpoints require JWT token in Authorization header:
```
Authorization: Bearer {token}
```

### 1. Create Task
**POST** `/api/tasks`

**Request:**
```json
{
  "title": "Implement authentication",
  "description": "Add JWT-based auth",
  "status": "PENDING"
}
```

**Response (201):**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement authentication",
  "description": "Add JWT-based auth",
  "status": "PENDING",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T10:00:00Z"
}
```

### 2. Get All Tasks
**GET** `/api/tasks?status=PENDING&page=0&size=20`

**Response (200):**
```json
{
  "content": [...],
  "page": 0,
  "size": 20,
  "totalElements": 5,
  "totalPages": 1
}
```

### 3. Get Task by ID
**GET** `/api/tasks/{id}`

### 4. Update Task
**PUT** `/api/tasks/{id}`

### 5. Delete Task
**DELETE** `/api/tasks/{id}`

**Response:** 204 No Content

### 6. Get Statistics
**GET** `/api/tasks/stats`

**Response:**
```json
{
  "userId": 1,
  "totalTasks": 10,
  "pendingTasks": 3,
  "inProgressTasks": 2,
  "completedTasks": 4,
  "cancelledTasks": 1
}
```

## Kafka Events

### Topic: `task-events`

**Event Types:**
- `TASK_CREATED` - Published when task is created
- `TASK_UPDATED` - Published when task is updated
- `TASK_COMPLETED` - Published when task status changes to COMPLETED
- `TASK_DELETED` - Published when task is deleted

**Example Event:**
```json
{
  "eventType": "TASK_CREATED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement authentication",
  "status": "PENDING",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | localhost | PostgreSQL host |
| `DB_PORT` | 5432 | PostgreSQL port |
| `DB_NAME` | task_db | Database name |
| `DB_USERNAME` | task_user | Database user |
| `DB_PASSWORD` | task_password | Database password |
| `KAFKA_BOOTSTRAP_SERVERS` | localhost:9092 | Kafka servers |
| `AUTH_SERVICE_URL` | http://auth-service:8081 | Auth Service URL |
| `GRAYLOG_HOST` | localhost | Graylog host |
| `GRAYLOG_PORT` | 12201 | Graylog GELF port |

## Local Development

### 1. Start Dependencies

```bash
# PostgreSQL
docker run -d --name task-postgres \
  -e POSTGRES_DB=task_db \
  -e POSTGRES_USER=task_user \
  -e POSTGRES_PASSWORD=task_password \
  -p 5433:5432 \
  postgres:15

# Kafka (requires Zookeeper or use KRaft mode)
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  confluentinc/cp-kafka:7.5.0
```

### 2. Build and Run

```bash
# Build
./gradlew build

# Run
./gradlew bootRun

# Or run JAR
java -jar build/libs/task-service-1.0.0.jar
```

### 3. Access Swagger UI

Open browser: http://localhost:8082/swagger-ui.html

## Docker Build

```bash
docker build -t task-service:latest .
```

## Kubernetes Deployment

### Using Helm

```bash
# Install
helm install task-service ./helm/task-service -n task-management --create-namespace

# Upgrade
helm upgrade task-service ./helm/task-service -n task-management

# Uninstall
helm uninstall task-service -n task-management
```

### Port Forward

```bash
kubectl port-forward -n task-management svc/task-service 8082:8082
```

## Monitoring

### Prometheus Metrics

Access: http://localhost:8082/actuator/prometheus

**Custom Metrics:**
- `tasks_created_total` - Counter for created tasks
- `tasks_updated_total` - Counter for updated tasks
- `tasks_deleted_total` - Counter for deleted tasks

### Health Checks

- **Liveness**: http://localhost:8082/actuator/health/liveness
- **Readiness**: http://localhost:8082/actuator/health/readiness
- **Startup**: http://localhost:8082/actuator/health/startup

### Logs

Logs are sent to Graylog via GELF UDP protocol.

**Log Fields:**
- `application` - Service name (task-service)
- `level` - Log level (INFO, WARN, ERROR)
- `message` - Log message
- `timestamp` - Event timestamp

## Testing

```bash
# Run all tests
./gradlew test

# Run with coverage
./gradlew test jacocoTestReport

# View coverage report
open build/reports/jacoco/test/html/index.html
```

## Project Structure

```
task-service/
├── src/
│   ├── main/
│   │   ├── kotlin/com/taskmanagement/task/
│   │   │   ├── TaskServiceApplication.kt
│   │   │   ├── config/
│   │   │   │   ├── KafkaConfig.kt
│   │   │   │   ├── AuthClientConfig.kt
│   │   │   │   └── CacheConfig.kt
│   │   │   ├── controller/
│   │   │   │   └── TaskController.kt
│   │   │   ├── service/
│   │   │   │   ├── TaskService.kt
│   │   │   │   ├── AuthClientService.kt
│   │   │   │   └── KafkaProducerService.kt
│   │   │   ├── repository/
│   │   │   │   └── TaskRepository.kt
│   │   │   ├── entity/
│   │   │   │   ├── Task.kt
│   │   │   │   └── TaskStatus.kt
│   │   │   ├── dto/
│   │   │   │   ├── CreateTaskRequest.kt
│   │   │   │   ├── UpdateTaskRequest.kt
│   │   │   │   ├── TaskResponse.kt
│   │   │   │   ├── TaskPageResponse.kt
│   │   │   │   ├── TaskStatsResponse.kt
│   │   │   │   └── UserInfo.kt
│   │   │   ├── security/
│   │   │   │   └── AuthenticationFilter.kt
│   │   │   └── exception/
│   │   │       ├── GlobalExceptionHandler.kt
│   │   │       ├── TaskNotFoundException.kt
│   │   │       ├── AccessDeniedException.kt
│   │   │       └── UnauthorizedException.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── kotlin/com/taskmanagement/task/
├── helm/task-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── hpa.yaml
│       ├── servicemonitor.yaml
│       ├── configmap.yaml
│       └── secret.yaml
├── build.gradle.kts
├── Dockerfile
└── README.md
```

## Troubleshooting

### Cannot connect to Auth Service

Check Auth Service is running and accessible:
```bash
curl http://auth-service:8081/actuator/health
```

### Cannot connect to PostgreSQL

Check database credentials and connection:
```bash
kubectl exec -n task-management task-postgres-0 -- pg_isready -U task_user
```

### Kafka events not published

Check Kafka is running:
```bash
kubectl logs -n task-management kafka-0
```

## Author

Gribkov A.S., IKBO-16-22

## License

Educational project for MIREA

