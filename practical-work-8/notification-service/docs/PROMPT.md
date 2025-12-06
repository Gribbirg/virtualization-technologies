# Notification Service - Implementation Prompt

## Overview
Build a minimal notification microservice using Spring Boot and Kotlin. This service consumes events from Kafka and stores notification records. **This is the simplest service - it just listens to Kafka and logs/stores notifications. Keep it minimal.**

## Technology Stack

### Core Framework
- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2+
- **Build Tool**: Gradle (Kotlin DSL)

### Dependencies
- Spring Boot Starter Web
- Spring Boot Starter Data JPA
- Spring Boot Starter Actuator
- Spring Kafka (for consuming events)
- PostgreSQL Driver
- Micrometer Prometheus Registry
- Logback GELF (for Graylog integration)
- OpenAPI/Swagger (springdoc-openapi-starter-webmvc-ui)

### Infrastructure
- **Database**: PostgreSQL 15
- **Message Broker**: Apache Kafka (for consuming events)

## Database Schema

### Table: notifications
```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_event_type ON notifications(event_type);
```

## API Contract

### Base Path: `/api/notifications`

### Authentication
All endpoints require JWT token in Authorization header:
```
Authorization: Bearer {token}
```

Service validates token by calling Auth Service `/api/auth/validate` endpoint.

### 1. Get All Notifications (for current user)
**GET** `/api/notifications`

**Query Parameters:**
- `unreadOnly` (optional, default=false): show only unread notifications
- `page` (optional, default=0): page number
- `size` (optional, default=20): page size

**Response (200 OK):**
```json
{
  "content": [
    {
      "id": 1,
      "userId": 1,
      "eventType": "TASK_CREATED",
      "message": "New task created: Implement user authentication",
      "metadata": {
        "taskId": 1,
        "taskTitle": "Implement user authentication"
      },
      "createdAt": "2025-12-03T10:00:00Z",
      "readAt": null
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

### 2. Get Notification by ID
**GET** `/api/notifications/{id}`

**Response (200 OK):**
```json
{
  "id": 1,
  "userId": 1,
  "eventType": "TASK_CREATED",
  "message": "New task created: Implement user authentication",
  "metadata": {
    "taskId": 1,
    "taskTitle": "Implement user authentication"
  },
  "createdAt": "2025-12-03T10:00:00Z",
  "readAt": null
}
```

### 3. Mark Notification as Read
**POST** `/api/notifications/{id}/read`

**Response (200 OK):**
```json
{
  "id": 1,
  "userId": 1,
  "eventType": "TASK_CREATED",
  "message": "New task created: Implement user authentication",
  "metadata": {
    "taskId": 1,
    "taskTitle": "Implement user authentication"
  },
  "createdAt": "2025-12-03T10:00:00Z",
  "readAt": "2025-12-03T10:30:00Z"
}
```

### 4. Mark All Notifications as Read
**POST** `/api/notifications/read-all`

**Response (200 OK):**
```json
{
  "message": "All notifications marked as read",
  "count": 5
}
```

### 5. Get Unread Count
**GET** `/api/notifications/unread-count`

**Response (200 OK):**
```json
{
  "userId": 1,
  "unreadCount": 3
}
```

### 6. Delete Notification
**DELETE** `/api/notifications/{id}`

**Response (204 No Content)**

## Business Logic

### Kafka Event Consumption

The service listens to multiple Kafka topics and creates notifications:

#### Topic: `auth-events`
Consumes events from Auth Service:
- `USER_REGISTERED` → "Welcome! Your account has been created"
- `USER_LOGGED_IN` → "You logged in from a new device" (optional, can be skipped)

#### Topic: `task-events`
Consumes events from Task Service:
- `TASK_CREATED` → "New task created: {title}"
- `TASK_UPDATED` → "Task updated: {title} - Status changed to {status}"
- `TASK_COMPLETED` → "Task completed: {title}"
- `TASK_DELETED` → "Task deleted: {title}"

### Event Processing Flow
1. Receive event from Kafka
2. Parse event JSON
3. Extract userId and event details
4. Generate human-readable message
5. Store notification in PostgreSQL
6. Log the notification creation

### Notification Message Templates

```kotlin
fun generateMessage(event: KafkaEvent): String {
    return when (event.eventType) {
        "USER_REGISTERED" -> "Welcome! Your account has been created successfully."
        "USER_LOGGED_IN" -> "You logged in to your account."
        "TASK_CREATED" -> "New task created: ${event.metadata["title"]}"
        "TASK_UPDATED" -> {
            val title = event.metadata["title"]
            val newStatus = event.metadata["newStatus"]
            "Task updated: $title - Status: $newStatus"
        }
        "TASK_COMPLETED" -> "Task completed: ${event.metadata["title"]} ✓"
        "TASK_DELETED" -> "Task deleted: ${event.metadata["title"]}"
        else -> "New notification"
    }
}
```

## Kafka Consumer Configuration

### Consumer Groups
- **Group ID**: `notification-service-group`
- **Auto Offset Reset**: earliest
- **Enable Auto Commit**: true

### Topics
- `auth-events` - Auth service events
- `task-events` - Task service events

### Error Handling
- If event processing fails, log error and continue (don't block consumer)
- Use `@RetryableTopic` for transient failures (max 3 retries)
- Dead letter topic: `notification-service-dlt`

## Logging Requirements

### Graylog Integration
- Log all API requests: HTTP method, URL, IP address, response status, userId
- Log all consumed Kafka events with details
- Use GELF protocol (UDP port 12201)

### Log Format
```
[NOTIFICATION-SERVICE] [INFO] Kafka event consumed: TASK_CREATED - User: 1 - Task: "Implement auth"
[NOTIFICATION-SERVICE] [INFO] Notification created: ID=1, User=1, Type=TASK_CREATED
[NOTIFICATION-SERVICE] [INFO] GET /api/notifications from 192.168.1.100 - Status: 200 - User: 1
[NOTIFICATION-SERVICE] [INFO] POST /api/notifications/1/read from 192.168.1.100 - Status: 200 - User: 1
[NOTIFICATION-SERVICE] [ERROR] Failed to process Kafka event: Invalid JSON format
```

## Monitoring & Metrics

### Prometheus Metrics (via Actuator)
- JVM metrics (heap, threads, GC)
- HTTP request metrics (rate, duration, status codes)
- Kafka consumer metrics (lag, rate, errors)
- Custom metrics:
  - `notifications_created_total` - Counter for created notifications
  - `notifications_read_total` - Counter for read notifications
  - `kafka_events_consumed_total` - Counter by event type
  - `kafka_events_failed_total` - Counter for failed event processing
  - `notifications_unread_gauge` - Gauge for unread notifications

### Health Checks
- **Liveness Probe**: `/actuator/health/liveness`
- **Readiness Probe**: `/actuator/health/readiness` (checks DB and Kafka connection)
- **Startup Probe**: `/actuator/health/startup`

## Configuration

### application.yml
```yaml
spring:
  application:
    name: notification-service
  
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:notification_db}
    username: ${DB_USERNAME:notification_user}
    password: ${DB_PASSWORD:notification_password}
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
    consumer:
      group-id: notification-service-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "*"

server:
  port: 8083

auth-service:
  url: ${AUTH_SERVICE_URL:http://auth-service:8081}

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

#### NotificationService Tests
1. `createNotification_Success` - creates notification
2. `getNotifications_FilterByUser` - returns user's notifications
3. `getNotifications_UnreadOnly` - returns only unread
4. `markAsRead_Success` - updates readAt timestamp
5. `markAllAsRead_Success` - marks all user notifications as read
6. `getUnreadCount_Success` - returns correct count
7. `deleteNotification_Success` - deletes notification

#### KafkaConsumer Tests
1. `consumeAuthEvent_UserRegistered` - creates welcome notification
2. `consumeTaskEvent_TaskCreated` - creates task notification
3. `consumeTaskEvent_TaskUpdated` - creates update notification
4. `consumeTaskEvent_TaskCompleted` - creates completion notification
5. `consumeInvalidEvent_HandlesGracefully` - logs error and continues

#### NotificationController Tests
1. `getNotifications_ReturnsOk` - GET /notifications returns 200
2. `getNotificationById_ReturnsOk` - GET /notifications/{id} returns 200
3. `markAsRead_ReturnsOk` - POST /notifications/{id}/read returns 200
4. `markAllAsRead_ReturnsOk` - POST /notifications/read-all returns 200
5. `getUnreadCount_ReturnsOk` - GET /notifications/unread-count returns 200
6. `deleteNotification_ReturnsNoContent` - DELETE /notifications/{id} returns 204

### Testing Tools
- JUnit 5
- MockK (Kotlin mocking library)
- Spring Boot Test
- Spring Kafka Test (for Kafka consumer testing)
- Testcontainers (for PostgreSQL and Kafka integration tests)

## Project Structure

```
notification-service/
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   └── com/taskmanagement/notification/
│   │   │       ├── NotificationServiceApplication.kt
│   │   │       ├── config/
│   │   │       │   ├── KafkaConsumerConfig.kt
│   │   │       │   └── AuthClientConfig.kt
│   │   │       ├── controller/
│   │   │       │   └── NotificationController.kt
│   │   │       ├── service/
│   │   │       │   ├── NotificationService.kt
│   │   │       │   ├── KafkaConsumerService.kt
│   │   │       │   └── AuthClientService.kt
│   │   │       ├── repository/
│   │   │       │   └── NotificationRepository.kt
│   │   │       ├── entity/
│   │   │       │   └── Notification.kt
│   │   │       ├── dto/
│   │   │       │   ├── NotificationResponse.kt
│   │   │       │   ├── NotificationPageResponse.kt
│   │   │       │   ├── UnreadCountResponse.kt
│   │   │       │   ├── MarkAllReadResponse.kt
│   │   │       │   └── KafkaEvent.kt
│   │   │       ├── security/
│   │   │       │   └── AuthenticationFilter.kt
│   │   │       └── exception/
│   │   │           ├── GlobalExceptionHandler.kt
│   │   │           ├── NotificationNotFoundException.kt
│   │   │           └── UnauthorizedException.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── kotlin/
│           └── com/taskmanagement/notification/
│               ├── service/
│               │   ├── NotificationServiceTest.kt
│               │   └── KafkaConsumerServiceTest.kt
│               └── controller/
│                   └── NotificationControllerTest.kt
├── build.gradle.kts
├── Dockerfile
├── helm/
│   └── notification-service/
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
  - CPU: 300m request, 500m limit
  - Memory: 256Mi request, 512Mi limit
- **Probes**:
  - Liveness: `/actuator/health/liveness` (initialDelaySeconds: 30, periodSeconds: 10)
  - Readiness: `/actuator/health/readiness` (initialDelaySeconds: 20, periodSeconds: 5)
  - Startup: `/actuator/health/startup` (initialDelaySeconds: 10, periodSeconds: 5, failureThreshold: 30)
- **Restart Policy**: Always

### HorizontalPodAutoscaler
- **Min Replicas**: 2
- **Max Replicas**: 4
- **Target CPU Utilization**: 60%
- **Target Memory Utilization**: 60%

### Service
- **Type**: ClusterIP
- **Port**: 8083
- **Target Port**: 8083

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
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Implementation Guidelines

### DO
- Use Kotlin data classes for DTOs
- Implement proper exception handling with @ControllerAdvice
- Keep Kafka consumer simple - just parse and store
- Use constructor injection for dependencies
- Write meaningful log messages for each consumed event
- Use environment variables for configuration
- Implement pagination for list endpoints
- Handle Kafka deserialization errors gracefully

### DON'T
- Don't implement email/SMS sending (not required)
- Don't implement push notifications (not required)
- Don't implement notification preferences (not required)
- Don't implement notification templates (use simple strings)
- Don't add notification channels (not required)
- Don't overcomplicate - this is the simplest service
- Don't block Kafka consumer on errors

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
docker run -d --name notification-postgres -e POSTGRES_DB=notification_db -e POSTGRES_USER=notification_user -e POSTGRES_PASSWORD=notification_password -p 5434:5432 postgres:15

# Start Kafka (with Zookeeper)
docker run -d --name zookeeper -p 2181:2181 -e ZOOKEEPER_CLIENT_PORT=2181 confluentinc/cp-zookeeper:7.5.0
docker run -d --name kafka -p 9092:9092 -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 confluentinc/cp-kafka:7.5.0

# Build and run
./gradlew bootRun
```

### Docker Build
```bash
docker build -t notification-service:latest .
```

### Helm Install
```bash
helm install notification-service ./helm/notification-service -n task-management --create-namespace
```

## Success Criteria

- ✅ All API endpoints work as specified
- ✅ Kafka events are consumed and stored as notifications
- ✅ Notifications are properly filtered by userId
- ✅ Auth Service integration works correctly
- ✅ Logs are sent to Graylog via GELF
- ✅ Prometheus metrics are exposed
- ✅ Health probes respond correctly
- ✅ Unit tests pass with 80%+ coverage
- ✅ Helm chart deploys successfully to Minikube
- ✅ HPA scales pods based on CPU/memory usage
- ✅ Kafka consumer handles errors gracefully

## Notes

- **Keep it simple**: This is the simplest service - just consume Kafka and store notifications
- **No external notifications**: Don't implement email/SMS/push - just store in DB
- **Error handling**: Log errors but don't stop consuming events
- **Scalability**: Multiple replicas can consume from same consumer group
- **Observability**: Log every consumed event for debugging

