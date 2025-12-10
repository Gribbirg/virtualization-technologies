# Auth Service

Authentication microservice for Task Management System. Handles user registration, login, JWT token management with Redis storage, and publishes authentication events to Kafka.

## Technology Stack

- **Language**: Kotlin 1.9+
- **Framework**: Spring Boot 3.2+
- **Build Tool**: Gradle (Kotlin DSL)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Message Broker**: Apache Kafka
- **Container**: Docker
- **Orchestration**: Kubernetes (Helm)

## Features

- User registration with validation
- User login with JWT token generation
- Token storage in Redis (24h TTL)
- Token validation endpoint
- User logout (token invalidation)
- Get current user information
- Kafka event publishing (USER_REGISTERED, USER_LOGGED_IN, USER_LOGGED_OUT)
- Prometheus metrics export
- Graylog logging integration
- Health probes (liveness, readiness, startup)
- Horizontal Pod Autoscaling (2-5 replicas)

## API Endpoints

### Base Path: `/api/auth`

#### 1. Register User
**POST** `/api/auth/register`

Request:
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

Response (201 Created):
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "createdAt": "2025-12-03T10:00:00Z"
}
```

#### 2. Login
**POST** `/api/auth/login`

Request:
```json
{
  "username": "john_doe",
  "password": "SecurePass123!"
}
```

Response (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john_doe",
  "expiresIn": 86400
}
```

#### 3. Validate Token
**GET** `/api/auth/validate`

Headers:
```
Authorization: Bearer {token}
```

Response (200 OK):
```json
{
  "valid": true,
  "userId": 1,
  "username": "john_doe"
}
```

#### 4. Logout
**POST** `/api/auth/logout`

Headers:
```
Authorization: Bearer {token}
```

Response (200 OK):
```json
{
  "message": "Logged out successfully"
}
```

#### 5. Get Current User
**GET** `/api/auth/me`

Headers:
```
Authorization: Bearer {token}
```

Response (200 OK):
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "createdAt": "2025-12-03T10:00:00Z"
}
```

## Local Development

### Prerequisites

- Java 21
- Docker Desktop or Colima
- PostgreSQL 15
- Redis 7
- Apache Kafka

### Setup Infrastructure

```bash
# Start PostgreSQL
docker run -d --name auth-postgres \
  -e POSTGRES_DB=auth_db \
  -e POSTGRES_USER=auth_user \
  -e POSTGRES_PASSWORD=auth_password \
  -p 5432:5432 \
  postgres:15

# Start Redis
docker run -d --name auth-redis \
  -p 6379:6379 \
  redis:7-alpine

# Start Kafka (KRaft mode)
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ENABLE_KRAFT=yes \
  -e KAFKA_CFG_PROCESS_ROLES=broker,controller \
  -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
  bitnami/kafka:3.6
```

### Build and Run

```bash
# Build
./gradlew build

# Run
./gradlew bootRun

# Run tests
./gradlew test

# Generate test coverage report
./gradlew jacocoTestReport
```

Service will be available at: http://localhost:8081

### API Documentation

Swagger UI: http://localhost:8081/swagger-ui.html

### Health Checks

- Liveness: http://localhost:8081/actuator/health/liveness
- Readiness: http://localhost:8081/actuator/health/readiness
- Startup: http://localhost:8081/actuator/health/startup

### Metrics

Prometheus metrics: http://localhost:8081/actuator/prometheus

## Docker Build

```bash
# Build image
docker build -t auth-service:latest .

# Run container
docker run -d \
  -p 8081:8081 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=auth_db \
  -e DB_USERNAME=auth_user \
  -e DB_PASSWORD=auth_password \
  -e REDIS_HOST=host.docker.internal \
  -e REDIS_PORT=6379 \
  -e KAFKA_BOOTSTRAP_SERVERS=host.docker.internal:9092 \
  -e JWT_SECRET=your-secret-key \
  auth-service:latest
```

## Kubernetes Deployment

### Prerequisites

- Minikube running
- kubectl configured
- Helm 3 installed
- PostgreSQL, Redis, Kafka deployed in cluster

### Load Image to Minikube

```bash
# Build image
docker build -t auth-service:latest .

# Load to Minikube
minikube image load auth-service:latest
```

### Deploy with Helm

```bash
# Install
helm install auth-service ./helm/auth-service -n task-management --create-namespace

# Upgrade
helm upgrade auth-service ./helm/auth-service -n task-management

# Uninstall
helm uninstall auth-service -n task-management
```

### Verify Deployment

```bash
# Check pods
kubectl get pods -n task-management -l app=auth-service

# Check service
kubectl get svc -n task-management auth-service

# Check HPA
kubectl get hpa -n task-management auth-service-hpa

# View logs
kubectl logs -n task-management -l app=auth-service --tail=100 -f

# Port forward for testing
kubectl port-forward -n task-management svc/auth-service 8081:8081
```

### Test Endpoints

```bash
# Register user
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "TestPass123!"
  }'

# Login
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123!"
  }'

# Validate token (replace TOKEN with actual token)
curl -X GET http://localhost:8081/api/auth/validate \
  -H "Authorization: Bearer TOKEN"

# Get current user
curl -X GET http://localhost:8081/api/auth/me \
  -H "Authorization: Bearer TOKEN"

# Logout
curl -X POST http://localhost:8081/api/auth/logout \
  -H "Authorization: Bearer TOKEN"
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_NAME` | Database name | auth_db |
| `DB_USERNAME` | Database user | auth_user |
| `DB_PASSWORD` | Database password | auth_password |
| `REDIS_HOST` | Redis host | localhost |
| `REDIS_PORT` | Redis port | 6379 |
| `REDIS_PASSWORD` | Redis password | (empty) |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka servers | localhost:9092 |
| `JWT_SECRET` | JWT signing secret | (must be set) |
| `GRAYLOG_HOST` | Graylog host | localhost |
| `GRAYLOG_PORT` | Graylog GELF port | 12201 |

## Database Schema

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

## Kafka Events

### Topic: `auth-events`

**Event: USER_REGISTERED**
```json
{
  "eventType": "USER_REGISTERED",
  "userId": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Event: USER_LOGGED_IN**
```json
{
  "eventType": "USER_LOGGED_IN",
  "userId": 1,
  "username": "john_doe",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Event: USER_LOGGED_OUT**
```json
{
  "eventType": "USER_LOGGED_OUT",
  "userId": 1,
  "timestamp": "2025-12-03T10:00:00Z"
}
```

## Monitoring

### Prometheus Metrics

- `auth_registrations_total` - Total user registrations
- `auth_logins_total` - Total successful logins
- `auth_login_failures_total` - Total failed login attempts
- `jvm_memory_used_bytes` - JVM memory usage
- `http_server_requests_seconds` - HTTP request metrics

### Graylog Logs

All logs are sent to Graylog via GELF UDP protocol with fields:
- `application`: auth-service
- `level`: INFO, WARN, ERROR
- `http_method`: HTTP method
- `url`: Request URL
- `ip_address`: Client IP address
- `user_id`: User ID (when available)

## Troubleshooting

### Service won't start

Check database connection:
```bash
kubectl exec -n task-management auth-postgres-0 -- pg_isready -U auth_user
```

### Redis connection issues

Test Redis connectivity:
```bash
kubectl exec -n task-management -it redis-0 -- redis-cli ping
```

### Kafka not receiving events

Check Kafka topics:
```bash
kubectl exec -n task-management kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list
```

### View application logs

```bash
kubectl logs -n task-management -l app=auth-service --tail=100 -f
```

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
│   │   │       │   ├── TokenValidationResponse.kt
│   │   │       │   └── AuthEvent.kt
│   │   │       └── exception/
│   │   │           ├── GlobalExceptionHandler.kt
│   │   │           ├── UserAlreadyExistsException.kt
│   │   │           ├── InvalidCredentialsException.kt
│   │   │           └── InvalidTokenException.kt
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback-spring.xml
│   └── test/
│       └── kotlin/
│           └── com/taskmanagement/auth/
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
├── build.gradle.kts
├── settings.gradle.kts
├── Dockerfile
└── README.md
```

## Author

Gribkov A.S., IKBO-16-22

## License

Educational project for MIREA

