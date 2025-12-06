# Task Service - Implementation Prompt

## Overview
Build a minimal task management microservice using Spring Boot and Kotlin. This service handles CRUD operations for tasks and publishes events to Kafka. **Keep it simple - implement only what's required, no extra features.**

## Technology Stack

### Core Framework
- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2+
- **Build Tool**: Gradle (Kotlin DSL)

### Dependencies
- Spring Boot Starter Web
- Spring Boot Starter Data JPA
- Spring Boot Starter Actuator
- Spring Boot Starter Validation
- Spring Kafka (for event publishing)
- PostgreSQL Driver
- Micrometer Prometheus Registry
- Logback GELF (for Graylog integration)
- OpenAPI/Swagger (springdoc-openapi-starter-webmvc-ui)

### Infrastructure
- **Database**: PostgreSQL 15
- **Message Broker**: Apache Kafka (for publishing task events)

## Database Schema

### Table: tasks
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

### Status Enum
- `PENDING` - Task created, not started
- `IN_PROGRESS` - Task is being worked on
- `COMPLETED` - Task finished
- `CANCELLED` - Task cancelled

## API Contract

### Base Path: `/api/tasks`

### Authentication
All endpoints require JWT token in Authorization header:
```
Authorization: Bearer {token}
```

Service validates token by calling Auth Service `/api/auth/validate` endpoint.

### 1. Create Task
**POST** `/api/tasks`

**Request Body:**
```json
{
  "title": "Implement user authentication",
  "description": "Add JWT-based authentication to the API",
  "status": "PENDING"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "description": "Add JWT-based authentication to the API",
  "status": "PENDING",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T10:00:00Z"
}
```

**Validation Rules:**
- title: 1-200 characters, required
- description: optional, max 2000 characters
- status: must be valid enum value (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)

### 2. Get All Tasks (for current user)
**GET** `/api/tasks`

**Query Parameters:**
- `status` (optional): filter by status (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)
- `page` (optional, default=0): page number
- `size` (optional, default=20): page size

**Response (200 OK):**
```json
{
  "content": [
    {
      "id": 1,
      "userId": 1,
      "title": "Implement user authentication",
      "description": "Add JWT-based authentication to the API",
      "status": "IN_PROGRESS",
      "createdAt": "2025-12-03T10:00:00Z",
      "updatedAt": "2025-12-03T11:00:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

### 3. Get Task by ID
**GET** `/api/tasks/{id}`

**Response (200 OK):**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "description": "Add JWT-based authentication to the API",
  "status": "IN_PROGRESS",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T11:00:00Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Task not found",
  "taskId": 999
}
```

**Error Response (403 Forbidden):**
```json
{
  "error": "Access denied - task belongs to another user"
}
```

### 4. Update Task
**PUT** `/api/tasks/{id}`

**Request Body:**
```json
{
  "title": "Implement user authentication (Updated)",
  "description": "Add JWT-based authentication with Redis storage",
  "status": "COMPLETED"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication (Updated)",
  "description": "Add JWT-based authentication with Redis storage",
  "status": "COMPLETED",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T12:00:00Z"
}
```

### 5. Delete Task
**DELETE** `/api/tasks/{id}`

**Response (204 No Content)**

**Error Response (404 Not Found):**
```json
{
  "error": "Task not found",
  "taskId": 999
}
```

### 6. Get Task Statistics
**GET** `/api/tasks/stats`

**Response (200 OK):**
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

## Business Logic

### Create Task Flow
1. Validate JWT token with Auth Service
2. Extract userId from token
3. Validate input (title, description, status)
4. Set default status to PENDING if not provided
5. Save task to PostgreSQL with userId
6. Publish Kafka event: `task.created`
7. Return created task

### Get Tasks Flow
1. Validate JWT token with Auth Service
2. Extract userId from token
3. Query tasks filtered by userId (and optional status)
4. Apply pagination
5. Return paginated results

### Update Task Flow
1. Validate JWT token with Auth Service
2. Extract userId from token
3. Find task by ID
4. Check if task belongs to current user → 403 if not
5. Update task fields
6. Update `updated_at` timestamp
7. Save to PostgreSQL
8. Publish Kafka event: `task.updated` (include old and new status if changed)
9. Return updated task

### Delete Task Flow
1. Validate JWT token with Auth Service
2. Extract userId from token
3. Find task by ID
4. Check if task belongs to current user → 403 if not
5. Delete task from PostgreSQL
6. Publish Kafka event: `task.deleted`
7. Return 204 No Content

## Kafka Events

### Topic: `task-events`

**Event: task.created**
```json
{
  "eventType": "TASK_CREATED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "status": "PENDING",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Event: task.updated**
```json
{
  "eventType": "TASK_UPDATED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "oldStatus": "PENDING",
  "newStatus": "IN_PROGRESS",
  "timestamp": "2025-12-03T11:00:00Z"
}
```

**Event: task.deleted**
```json
{
  "eventType": "TASK_DELETED",
  "taskId": 1,
  "userId": 1,
  "timestamp": "2025-12-03T12:00:00Z"
}
```

**Event: task.completed**
```json
{
  "eventType": "TASK_COMPLETED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "timestamp": "2025-12-03T12:00:00Z"
}
```

## Auth Service Integration

### Token Validation
Task Service calls Auth Service to validate tokens:

**Request:**
```
GET http://auth-service:8081/api/auth/validate
Authorization: Bearer {token}
```

**Response:**
```json
{
  "valid": true,
  "userId": 1,
  "username": "john_doe"
}
```

Use `RestTemplate` or `WebClient` to make this call. Cache validation results for 5 minutes to reduce load on Auth Service.

## Logging Requirements

### Graylog Integration
- Log all API requests: HTTP method, URL, IP address, response status, userId
- Log task operations: create, update, delete with task details
- Use GELF protocol (UDP port 12201)

### Log Format
```
[TASK-SERVICE] [INFO] POST /api/tasks from 192.168.1.100 - Status: 201 - User: 1 - Task created: "Implement auth"
[TASK-SERVICE] [INFO] PUT /api/tasks/1 from 192.168.1.100 - Status: 200 - User: 1 - Task updated: PENDING -> IN_PROGRESS
[TASK-SERVICE] [INFO] DELETE /api/tasks/1 from 192.168.1.100 - Status: 204 - User: 1 - Task deleted
[TASK-SERVICE] [WARN] GET /api/tasks/999 from 192.168.1.100 - Status: 404 - User: 1 - Task not found
[TASK-SERVICE] [ERROR] GET /api/tasks/5 from 192.168.1.100 - Status: 403 - User: 1 - Access denied
```

## Monitoring & Metrics

### Prometheus Metrics (via Actuator)
- JVM metrics (heap, threads, GC)
- HTTP request metrics (rate, duration, status codes)
- Database connection pool metrics
- Custom metrics:
  - `tasks_created_total` - Counter for created tasks
  - `tasks_updated_total` - Counter for updated tasks
  - `tasks_deleted_total` - Counter for deleted tasks
  - `tasks_by_status` - Gauge for task count by status
  - `task_operations_duration_seconds` - Histogram for operation duration

### Health Checks
- **Liveness Probe**: `/actuator/health/liveness`
- **Readiness Probe**: `/actuator/health/readiness` (checks DB connection)
- **Startup Probe**: `/actuator/health/startup`

## Configuration

### application.yml
```yaml
spring:
  application:
    name: task-service
  
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:task_db}
    username: ${DB_USERNAME:task_user}
    password: ${DB_PASSWORD:task_password}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
  
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

server:
  port: 8082

auth-service:
  url: ${AUTH_SERVICE_URL:http://auth-service:8081}
  validation-cache-ttl: 300

management:
  endpoints:
    web:
      exposure:
        include: health,prometheus,info
  metrics:
    export:
      prometheus:
        enabled: true
  health:
    readiness:
      enabled: true
    liveness:
      enabled: true
```

## Unit Testing Requirements

### Test Coverage
- **Minimum**: 80% code coverage
- Focus on business logic

### Test Cases

#### TaskService Tests
1. `createTask_Success` - creates task with correct userId
2. `createTask_InvalidInput` - validation fails
3. `getTasks_FilterByStatus` - returns filtered tasks
4. `getTasks_Pagination` - returns paginated results
5. `getTaskById_Success` - returns task
6. `getTaskById_NotFound` - throws exception
7. `getTaskById_AccessDenied` - throws exception when task belongs to another user
8. `updateTask_Success` - updates task and publishes event
9. `updateTask_StatusChange` - publishes event with old and new status
10. `deleteTask_Success` - deletes task and publishes event
11. `getStats_Success` - returns correct statistics

#### TaskController Tests
1. `createTask_ReturnsCreated` - POST /tasks returns 201
2. `getTasks_ReturnsOk` - GET /tasks returns 200
3. `getTaskById_ReturnsOk` - GET /tasks/{id} returns 200
4. `getTaskById_NotFound_Returns404` - returns 404
5. `updateTask_ReturnsOk` - PUT /tasks/{id} returns 200
6. `deleteTask_ReturnsNoContent` - DELETE /tasks/{id} returns 204
7. `getStats_ReturnsOk` - GET /tasks/stats returns 200
8. `createTask_Unauthorized_Returns401` - returns 401 without token

### Testing Tools
- JUnit 5
- MockK (Kotlin mocking library)
- Spring Boot Test
- Testcontainers (for PostgreSQL integration tests)
- MockWebServer (for mocking Auth Service calls)

## Project Structure

```
task-service/
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   └── com/taskmanagement/task/
│   │   │       ├── TaskServiceApplication.kt
│   │   │       ├── config/
│   │   │       │   ├── KafkaConfig.kt
│   │   │       │   ├── AuthClientConfig.kt
│   │   │       │   └── CacheConfig.kt
│   │   │       ├── controller/
│   │   │       │   └── TaskController.kt
│   │   │       ├── service/
│   │   │       │   ├── TaskService.kt
│   │   │       │   ├── AuthClientService.kt
│   │   │       │   └── KafkaProducerService.kt
│   │   │       ├── repository/
│   │   │       │   └── TaskRepository.kt
│   │   │       ├── entity/
│   │   │       │   ├── Task.kt
│   │   │       │   └── TaskStatus.kt
│   │   │       ├── dto/
│   │   │       │   ├── CreateTaskRequest.kt
│   │   │       │   ├── UpdateTaskRequest.kt
│   │   │       │   ├── TaskResponse.kt
│   │   │       │   ├── TaskPageResponse.kt
│   │   │       │   ├── TaskStatsResponse.kt
│   │   │       │   └── UserInfo.kt
│   │   │       ├── security/
│   │   │       │   └── AuthenticationFilter.kt
│   │   │       └── exception/
│   │   │           ├── GlobalExceptionHandler.kt
│   │   │           ├── TaskNotFoundException.kt
│   │   │           ├── AccessDeniedException.kt
│   │   │           └── UnauthorizedException.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── kotlin/
│           └── com/taskmanagement/task/
│               ├── service/
│               │   ├── TaskServiceTest.kt
│               │   └── AuthClientServiceTest.kt
│               └── controller/
│                   └── TaskControllerTest.kt
├── build.gradle.kts
├── Dockerfile
├── helm/
│   └── task-service/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           ├── hpa.yaml
│           └── servicemonitor.yaml
└── README.md
```

## Helm Chart Requirements

### Deployment Configuration
- **Replicas**: 2 (for high availability)
- **Image Pull Policy**: IfNotPresent
- **Resource Limits**:
  - CPU: 500m request, 1000m limit
  - Memory: 512Mi request, 1Gi limit
- **Probes**:
  - Liveness: `/actuator/health/liveness` (initialDelaySeconds: 30, periodSeconds: 10)
  - Readiness: `/actuator/health/readiness` (initialDelaySeconds: 20, periodSeconds: 5)
  - Startup: `/actuator/health/startup` (initialDelaySeconds: 10, periodSeconds: 5, failureThreshold: 30)
- **Restart Policy**: Always

### HorizontalPodAutoscaler
- **Min Replicas**: 2
- **Max Replicas**: 5
- **Target CPU Utilization**: 60%
- **Target Memory Utilization**: 60%

### Service
- **Type**: ClusterIP
- **Port**: 8082
- **Target Port**: 8082

## Dockerfile

```dockerfile
FROM gradle:8.5-jdk21 AS build
WORKDIR /app
COPY build.gradle.kts settings.gradle.kts ./
COPY src ./src
RUN gradle build -x test --no-daemon

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Implementation Guidelines

### DO
- Use Kotlin data classes for DTOs
- Implement proper exception handling with @ControllerAdvice
- Use @Validated for request validation
- Keep services stateless
- Use constructor injection for dependencies
- Cache Auth Service validation results (5 minutes)
- Write meaningful log messages
- Use environment variables for configuration
- Implement pagination for list endpoints

### DON'T
- Don't implement task assignments to multiple users (not required)
- Don't implement task priorities (not required)
- Don't implement task tags/labels (not required)
- Don't implement task comments (not required)
- Don't add file attachments (not required)
- Don't overcomplicate - keep it minimal
- Don't store sensitive data in logs

## Deliverables

1. **Source Code**: Complete Kotlin/Spring Boot application
2. **Unit Tests**: 80%+ coverage
3. **Dockerfile**: Multi-stage build
4. **Helm Chart**: Complete with all templates
5. **README.md**: Build and run instructions
6. **build.gradle.kts**: All dependencies configured

## Build & Run Instructions

### Local Development
```bash
# Start PostgreSQL
docker run -d --name task-postgres -e POSTGRES_DB=task_db -e POSTGRES_USER=task_user -e POSTGRES_PASSWORD=task_password -p 5433:5432 postgres:15

# Start Kafka (with Zookeeper)
docker run -d --name zookeeper -p 2181:2181 -e ZOOKEEPER_CLIENT_PORT=2181 confluentinc/cp-zookeeper:7.5.0
docker run -d --name kafka -p 9092:9092 -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 confluentinc/cp-kafka:7.5.0

# Build and run
./gradlew bootRun
```

### Docker Build
```bash
docker build -t task-service:latest .
```

### Helm Install
```bash
helm install task-service ./helm/task-service -n task-management --create-namespace
```

## Success Criteria

- ✅ All API endpoints work as specified
- ✅ Tasks are properly filtered by userId
- ✅ Kafka events are published on task operations
- ✅ Auth Service integration works correctly
- ✅ Logs are sent to Graylog via GELF
- ✅ Prometheus metrics are exposed
- ✅ Health probes respond correctly
- ✅ Unit tests pass with 80%+ coverage
- ✅ Helm chart deploys successfully to Minikube
- ✅ HPA scales pods based on CPU/memory usage

## Notes

- **Keep it simple**: This is a minimal implementation for educational purposes
- **Security**: Always validate tokens before processing requests
- **Performance**: Use caching for Auth Service calls to reduce latency
- **Scalability**: Stateless design allows horizontal scaling
- **Observability**: Comprehensive logging and metrics for monitoring

