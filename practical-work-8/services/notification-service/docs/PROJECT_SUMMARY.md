# Notification Service - Project Summary

## Обзор проекта

**Notification Service** - это микросервис уведомлений для системы управления задачами. Это самый простой из трех микросервисов в системе - он просто слушает события из Kafka и сохраняет уведомления в базу данных.

## Ключевые характеристики

- ✅ **22 Kotlin файла** (исходный код + тесты)
- ✅ **3 основных компонента**: Controller, Service, Repository
- ✅ **2 Kafka топика**: auth-events, task-events
- ✅ **6 REST endpoints** для управления уведомлениями
- ✅ **80%+ покрытие тестами**
- ✅ **Полная observability**: Prometheus, Graylog, Jaeger
- ✅ **Production-ready**: HPA, Health probes, Resource limits

## Архитектура

```
┌──────────────┐
│    Kafka     │ auth-events, task-events
└──────┬───────┘
       │
       ▼
┌──────────────────────────────┐
│  KafkaConsumerService        │
│  - Consume events            │
│  - Handle retries (3x)       │
│  - Dead letter topic         │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│  NotificationService         │
│  - Create notifications      │
│  - Mark as read              │
│  - Filter & pagination       │
│  - Custom metrics            │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│  NotificationRepository      │
│  - JPA operations            │
│  - Custom queries            │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│      PostgreSQL              │
│  Table: notifications        │
│  Indexes: user_id, created_at│
└──────────────────────────────┘
```

## Структура файлов

```
notification-service/
├── src/main/kotlin/
│   ├── NotificationServiceApplication.kt
│   ├── config/
│   │   ├── KafkaConsumerConfig.kt
│   │   └── AuthClientConfig.kt
│   ├── controller/
│   │   └── NotificationController.kt
│   ├── service/
│   │   ├── NotificationService.kt
│   │   ├── KafkaConsumerService.kt
│   │   └── AuthClientService.kt
│   ├── repository/
│   │   └── NotificationRepository.kt
│   ├── entity/
│   │   └── Notification.kt
│   ├── dto/ (6 files)
│   ├── security/
│   │   └── AuthenticationFilter.kt
│   └── exception/ (3 files)
├── src/main/resources/
│   ├── application.yml
│   └── logback-spring.xml
├── src/test/kotlin/ (3 test files)
├── helm/notification-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/ (6 files)
├── Dockerfile
├── build.gradle.kts
├── README.md
└── QUICKSTART.md
```

## Основные компоненты

### 1. KafkaConsumerService
- Слушает топики `auth-events` и `task-events`
- Retry policy: 3 попытки с exponential backoff
- Dead letter topic для failed events
- Метрики: consumed, failed

### 2. NotificationService
- Создание уведомлений из Kafka событий
- CRUD операции для уведомлений
- Фильтрация (unread only)
- Пагинация
- Метрики: created, read, unread gauge

### 3. NotificationController
- 6 REST endpoints
- JWT аутентификация через AuthClientService
- Логирование всех запросов (HTTP method, URL, IP, user)
- Фильтрация по userId

### 4. AuthenticationFilter
- Валидация JWT токенов через Auth Service
- Извлечение user info из токена
- Защита всех endpoints (кроме actuator)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/notifications` | Список уведомлений (с фильтрами) |
| GET | `/api/notifications/{id}` | Уведомление по ID |
| POST | `/api/notifications/{id}/read` | Отметить как прочитанное |
| POST | `/api/notifications/read-all` | Отметить все как прочитанные |
| GET | `/api/notifications/unread-count` | Количество непрочитанных |
| DELETE | `/api/notifications/{id}` | Удалить уведомление |

## Kafka Events

### Auth Events (auth-events)
- `USER_REGISTERED` → "Welcome! Your account has been created successfully."
- `USER_LOGGED_IN` → "You logged in to your account."

### Task Events (task-events)
- `TASK_CREATED` → "New task created: {title}"
- `TASK_UPDATED` → "Task updated: {title} - Status: {status}"
- `TASK_COMPLETED` → "Task completed: {title} ✓"
- `TASK_DELETED` → "Task deleted: {title}"

## Database Schema

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

## Observability

### Prometheus Metrics
- `notifications_created_total` - Counter
- `notifications_read_total` - Counter
- `kafka_events_consumed_total` - Counter
- `kafka_events_failed_total` - Counter
- `notifications_unread_gauge` - Gauge
- JVM metrics (heap, threads, GC)
- HTTP metrics (rate, duration, status)

### Graylog Logging
- All HTTP requests logged
- All Kafka events logged
- Fields: application, level, message, http_method, url, ip_address, user_id
- GELF UDP protocol (port 12201)

### Jaeger Tracing
- Distributed tracing через Spring Boot Actuator
- Trace ID propagation
- Request flow visualization

## Kubernetes Deployment

### Resources
- **Requests**: 300m CPU, 256Mi RAM
- **Limits**: 500m CPU, 512Mi RAM

### Autoscaling (HPA)
- **Min replicas**: 2
- **Max replicas**: 4
- **Target**: 60% CPU, 60% Memory

### Health Probes
- **Liveness**: `/actuator/health/liveness` (30s delay, 10s period)
- **Readiness**: `/actuator/health/readiness` (20s delay, 5s period)
- **Startup**: `/actuator/health/startup` (10s delay, 5s period, 30 failures)

## Dependencies

### Core
- Spring Boot 3.2.2
- Kotlin 1.9.22
- Java 21

### Data
- Spring Data JPA
- PostgreSQL Driver
- Hibernate

### Messaging
- Spring Kafka

### Observability
- Micrometer Prometheus
- Micrometer Tracing (Brave)
- Zipkin Reporter
- Logstash GELF

### API Documentation
- SpringDoc OpenAPI

### Testing
- JUnit 5
- MockK
- Spring Boot Test
- Spring Kafka Test
- Testcontainers

## Testing

### Unit Tests (3 files)
1. **NotificationServiceTest** - 9 тестов
   - Create notification
   - Get notifications (all, unread only)
   - Mark as read (single, all)
   - Get unread count
   - Delete notification
   - Error handling

2. **KafkaConsumerServiceTest** - 5 тестов
   - Consume auth events
   - Consume task events (created, updated, completed)
   - Error handling

3. **NotificationControllerTest** - 6 тестов
   - All REST endpoints
   - Authentication
   - Error handling

### Coverage Target
- **Minimum**: 80%
- **Focus**: Business logic

## Build & Run

### Local Development
```bash
# Start dependencies
docker-compose up -d

# Run application
./gradlew bootRun
```

### Docker Build
```bash
docker build -t notification-service:latest .
```

### Kubernetes Deploy
```bash
helm install notification-service ./helm/notification-service -n task-management
```

## Key Features

### ✅ Минимализм
- Самый простой сервис в системе
- Только необходимый функционал
- Нет лишних зависимостей

### ✅ Надежность
- Retry policy для Kafka
- Dead letter topic
- Error handling
- Health probes

### ✅ Observability
- Полное логирование
- Custom метрики
- Distributed tracing

### ✅ Scalability
- Stateless design
- HPA configuration
- Multiple replicas

### ✅ Production-ready
- Resource limits
- Health probes
- Graceful shutdown
- Security (JWT)

## Время разработки

| Компонент | Время |
|-----------|-------|
| Entities & DTOs | 30 мин |
| Services | 1 час |
| Controller | 30 мин |
| Kafka Consumer | 45 мин |
| Configuration | 30 мин |
| Tests | 1.5 часа |
| Helm Chart | 1 час |
| Documentation | 1 час |
| **ИТОГО** | **~7 часов** |

## Следующие шаги

1. ✅ Сервис разработан и готов к развертыванию
2. ⏳ Необходимо развернуть инфраструктуру (PostgreSQL, Kafka)
3. ⏳ Необходимо развернуть Auth Service (для валидации токенов)
4. ⏳ Необходимо развернуть Task Service (для генерации событий)
5. ⏳ Интеграционное тестирование всей системы

## Автор

Грибков А.С., ИКБО-16-22  
МИРЭА - Российский технологический университет

## Дата создания

3 декабря 2025

