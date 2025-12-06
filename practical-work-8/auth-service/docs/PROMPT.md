# Auth Service - Implementation Prompt

## Overview
Build a minimal authentication microservice using Spring Boot and Kotlin. This service handles user registration, login, and JWT token management with Redis storage. **Keep it simple - implement only what's required, no extra features.**

## Technology Stack

### Core Framework
- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2+
- **Build Tool**: Gradle (Kotlin DSL)

### Dependencies
- Spring Boot Starter Web
- Spring Boot Starter Data JPA
- Spring Boot Starter Data Redis
- Spring Boot Starter Security
- Spring Boot Starter Actuator
- Spring Boot Starter Validation
- Spring Kafka (for event publishing)
- PostgreSQL Driver
- JWT Library (io.jsonwebtoken:jjwt-api:0.12.3)
- Micrometer Prometheus Registry
- Logback GELF (for Graylog integration)
- OpenAPI/Swagger (springdoc-openapi-starter-webmvc-ui)

### Infrastructure
- **Database**: PostgreSQL 15
- **Cache/Token Storage**: Redis 7
- **Message Broker**: Apache Kafka (for publishing auth events)

## Database Schema

### Table: users
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
```

### Redis Storage
- **Key Pattern**: `auth:token:{token}` → stores user_id
- **TTL**: 24 hours (86400 seconds)

## API Contract

### Base Path: `/api/auth`

### 1. Register User
**POST** `/api/auth/register`

**Request Body:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "createdAt": "2025-12-03T10:00:00Z"
}
```

**Validation Rules:**
- username: 3-50 characters, alphanumeric + underscore
- email: valid email format
- password: minimum 8 characters

### 2. Login
**POST** `/api/auth/login`

**Request Body:**
```json
{
  "username": "john_doe",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john_doe",
  "expiresIn": 86400
}
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Invalid credentials"
}
```

### 3. Validate Token
**GET** `/api/auth/validate`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "valid": true,
  "userId": 1,
  "username": "john_doe"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "valid": false,
  "error": "Invalid or expired token"
}
```

### 4. Logout
**POST** `/api/auth/logout`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

### 5. Get Current User
**GET** `/api/auth/me`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "createdAt": "2025-12-03T10:00:00Z"
}
```

## Business Logic

### Registration Flow
1. Validate input (username, email, password)
2. Check if username or email already exists → return 409 Conflict
3. Hash password using BCrypt
4. Save user to PostgreSQL
5. Publish Kafka event: `user.registered` with userId, username
6. Return user data (without password)

### Login Flow
1. Validate credentials against PostgreSQL
2. Generate JWT token (HS256, 24h expiration)
3. Store token in Redis: key=`auth:token:{token}`, value=userId, TTL=24h
4. Publish Kafka event: `user.logged_in` with userId, username
5. Return token and user info

### Token Validation Flow
1. Extract token from Authorization header
2. Check if token exists in Redis
3. Verify JWT signature and expiration
4. Return user info if valid

### Logout Flow
1. Extract token from Authorization header
2. Delete token from Redis
3. Publish Kafka event: `user.logged_out` with userId
4. Return success message

## Kafka Events

### Topic: `auth-events`

**Event: user.registered**
```json
{
  "eventType": "USER_REGISTERED",
  "userId": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Event: user.logged_in**
```json
{
  "eventType": "USER_LOGGED_IN",
  "userId": 1,
  "username": "john_doe",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Event: user.logged_out**
```json
{
  "eventType": "USER_LOGGED_OUT",
  "userId": 1,
  "timestamp": "2025-12-03T10:00:00Z"
}
```

## Logging Requirements

### Graylog Integration
- Log all API requests: HTTP method, URL, IP address, response status
- Log authentication events: login success/failure, registration, logout
- Use GELF protocol (UDP port 12201)

### Log Format
```
[AUTH-SERVICE] [INFO] POST /api/auth/login from 192.168.1.100 - Status: 200 - User: john_doe
[AUTH-SERVICE] [WARN] POST /api/auth/login from 192.168.1.100 - Status: 401 - Failed login attempt
[AUTH-SERVICE] [INFO] POST /api/auth/register - New user registered: john_doe
```

## Monitoring & Metrics

### Prometheus Metrics (via Actuator)
- JVM metrics (heap, threads, GC)
- HTTP request metrics (rate, duration, status codes)
- Custom metrics:
  - `auth_registrations_total` - Counter for registrations
  - `auth_logins_total` - Counter for successful logins
  - `auth_login_failures_total` - Counter for failed logins
  - `auth_active_tokens` - Gauge for active tokens in Redis

### Health Checks
- **Liveness Probe**: `/actuator/health/liveness`
- **Readiness Probe**: `/actuator/health/readiness`
- **Startup Probe**: `/actuator/health/startup`

## Configuration

### application.yml
```yaml
spring:
  application:
    name: auth-service
  
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:auth_db}
    username: ${DB_USERNAME:auth_user}
    password: ${DB_PASSWORD:auth_password}
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
  
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      timeout: 2000ms
  
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

server:
  port: 8081

jwt:
  secret: ${JWT_SECRET:your-256-bit-secret-key-change-in-production}
  expiration: 86400000

management:
  endpoints:
    web:
      exposure:
        include: health,prometheus,info
  metrics:
    export:
      prometheus:
        enabled: true
```

## Unit Testing Requirements

### Test Coverage
- **Minimum**: 80% code coverage
- Focus on business logic, not boilerplate

### Test Cases

#### UserService Tests
1. `registerUser_Success` - successful registration
2. `registerUser_DuplicateUsername` - throws exception
3. `registerUser_DuplicateEmail` - throws exception
4. `registerUser_InvalidInput` - validation fails
5. `login_Success` - returns token
6. `login_InvalidCredentials` - throws exception
7. `validateToken_ValidToken` - returns user info
8. `validateToken_ExpiredToken` - throws exception
9. `logout_Success` - removes token from Redis

#### AuthController Tests
1. `register_ReturnsCreated` - POST /register returns 201
2. `login_ReturnsToken` - POST /login returns 200 with token
3. `validate_ValidToken_ReturnsOk` - GET /validate returns 200
4. `validate_InvalidToken_ReturnsUnauthorized` - returns 401
5. `logout_Success_ReturnsOk` - POST /logout returns 200
6. `me_ValidToken_ReturnsUser` - GET /me returns user data

### Testing Tools
- JUnit 5
- MockK (Kotlin mocking library)
- Spring Boot Test
- Testcontainers (for PostgreSQL and Redis integration tests)

## Project Structure

```
auth-service/
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   └── com/taskmanagement/auth/
│   │   │       ├── AuthServiceApplication.kt
│   │   │       ├── config/
│   │   │       │   ├── SecurityConfig.kt
│   │   │       │   ├── RedisConfig.kt
│   │   │       │   └── KafkaConfig.kt
│   │   │       ├── controller/
│   │   │       │   └── AuthController.kt
│   │   │       ├── service/
│   │   │       │   ├── AuthService.kt
│   │   │       │   ├── TokenService.kt
│   │   │       │   └── KafkaProducerService.kt
│   │   │       ├── repository/
│   │   │       │   └── UserRepository.kt
│   │   │       ├── entity/
│   │   │       │   └── User.kt
│   │   │       ├── dto/
│   │   │       │   ├── RegisterRequest.kt
│   │   │       │   ├── LoginRequest.kt
│   │   │       │   ├── LoginResponse.kt
│   │   │       │   ├── UserResponse.kt
│   │   │       │   └── TokenValidationResponse.kt
│   │   │       └── exception/
│   │   │           ├── GlobalExceptionHandler.kt
│   │   │           ├── UserAlreadyExistsException.kt
│   │   │           └── InvalidCredentialsException.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── kotlin/
│           └── com/taskmanagement/auth/
│               ├── service/
│               │   ├── AuthServiceTest.kt
│               │   └── TokenServiceTest.kt
│               └── controller/
│                   └── AuthControllerTest.kt
├── build.gradle.kts
├── Dockerfile
├── helm/
│   └── auth-service/
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
- **Port**: 8081
- **Target Port**: 8081

### ConfigMap
- Application configuration (non-sensitive)
- Kafka topics
- Redis configuration

### Secret
- Database credentials
- JWT secret
- Redis password

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
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Implementation Guidelines

### DO
- Use Kotlin data classes for DTOs
- Use Spring Security for password hashing (BCryptPasswordEncoder)
- Implement proper exception handling with @ControllerAdvice
- Use @Validated for request validation
- Keep services stateless
- Use constructor injection for dependencies
- Write meaningful log messages
- Use environment variables for configuration

### DON'T
- Don't implement user roles/permissions (not required)
- Don't implement password reset (not required)
- Don't implement email verification (not required)
- Don't add refresh tokens (not required)
- Don't overcomplicate - keep it minimal
- Don't store sensitive data in logs
- Don't use field injection (@Autowired on fields)

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
docker run -d --name auth-postgres -e POSTGRES_DB=auth_db -e POSTGRES_USER=auth_user -e POSTGRES_PASSWORD=auth_password -p 5432:5432 postgres:15

# Start Redis
docker run -d --name auth-redis -p 6379:6379 redis:7-alpine

# Start Kafka (with Zookeeper)
docker run -d --name zookeeper -p 2181:2181 -e ZOOKEEPER_CLIENT_PORT=2181 confluentinc/cp-zookeeper:7.5.0
docker run -d --name kafka -p 9092:9092 -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 confluentinc/cp-kafka:7.5.0

# Build and run
./gradlew bootRun
```

### Docker Build
```bash
docker build -t auth-service:latest .
```

### Helm Install
```bash
helm install auth-service ./helm/auth-service -n task-management --create-namespace
```

## Success Criteria

- ✅ All API endpoints work as specified
- ✅ JWT tokens are stored in Redis with TTL
- ✅ Kafka events are published on auth actions
- ✅ Logs are sent to Graylog via GELF
- ✅ Prometheus metrics are exposed
- ✅ Health probes respond correctly
- ✅ Unit tests pass with 80%+ coverage
- ✅ Helm chart deploys successfully to Minikube
- ✅ HPA scales pods based on CPU/memory usage

## Notes

- **Keep it simple**: This is a minimal implementation for educational purposes
- **Security**: Use strong JWT secrets in production
- **Performance**: Redis reduces database load for token validation
- **Scalability**: Stateless design allows horizontal scaling
- **Observability**: Comprehensive logging and metrics for monitoring

