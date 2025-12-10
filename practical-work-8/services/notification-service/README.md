# Notification Service

Микросервис уведомлений для Task Management System. Потребляет события из Kafka и предоставляет API для управления уведомлениями.

## Технологии

- **Язык**: Kotlin 1.9+
- **Фреймворк**: Spring Boot 3.2+
- **Сборка**: Gradle (Kotlin DSL)
- **База данных**: PostgreSQL 15
- **Message Broker**: Apache Kafka
- **Мониторинг**: Prometheus, Grafana, Jaeger
- **Логирование**: Graylog (GELF)

## Функциональность

### Kafka Consumer
Сервис слушает события из топиков:
- `auth-events` - события аутентификации
- `task-events` - события задач

### API Endpoints

**Base Path**: `/api/notifications`

#### 1. Получить все уведомления
```bash
GET /api/notifications?unreadOnly=false&page=0&size=20
Authorization: Bearer {token}
```

#### 2. Получить уведомление по ID
```bash
GET /api/notifications/{id}
Authorization: Bearer {token}
```

#### 3. Отметить как прочитанное
```bash
POST /api/notifications/{id}/read
Authorization: Bearer {token}
```

#### 4. Отметить все как прочитанные
```bash
POST /api/notifications/read-all
Authorization: Bearer {token}
```

#### 5. Получить количество непрочитанных
```bash
GET /api/notifications/unread-count
Authorization: Bearer {token}
```

#### 6. Удалить уведомление
```bash
DELETE /api/notifications/{id}
Authorization: Bearer {token}
```

## Структура базы данных

### Таблица: notifications
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

## Локальная разработка

### Требования
- Java 21
- Gradle 8.5+
- PostgreSQL 15
- Apache Kafka 3.6+

### Запуск зависимостей

#### PostgreSQL
```bash
docker run -d --name notification-postgres \
  -e POSTGRES_DB=notification_db \
  -e POSTGRES_USER=notification_user \
  -e POSTGRES_PASSWORD=notification_password \
  -p 5434:5432 \
  postgres:15
```

#### Kafka
```bash
# Zookeeper
docker run -d --name zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  confluentinc/cp-zookeeper:7.5.0

# Kafka
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  confluentinc/cp-kafka:7.5.0
```

### Запуск приложения
```bash
./gradlew bootRun
```

Сервис будет доступен на `http://localhost:8083`

## Сборка Docker образа

```bash
docker build -t notification-service:latest .
```

## Развертывание в Kubernetes

### С помощью Helm

```bash
helm install notification-service ./helm/notification-service \
  -n task-management \
  --create-namespace
```

### Проверка статуса
```bash
kubectl get pods -n task-management -l app=notification-service
kubectl logs -n task-management -l app=notification-service
```

### Port Forwarding
```bash
kubectl port-forward -n task-management svc/notification-service 8083:8083
```

## Конфигурация

### Переменные окружения

| Переменная | Описание | По умолчанию |
|-----------|----------|--------------|
| `DB_HOST` | Хост PostgreSQL | localhost |
| `DB_PORT` | Порт PostgreSQL | 5432 |
| `DB_NAME` | Имя базы данных | notification_db |
| `DB_USERNAME` | Пользователь БД | notification_user |
| `DB_PASSWORD` | Пароль БД | notification_password |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka серверы | localhost:9092 |
| `AUTH_SERVICE_URL` | URL Auth Service | http://auth-service:8081 |
| `GRAYLOG_HOST` | Хост Graylog | localhost |
| `GRAYLOG_PORT` | Порт Graylog GELF | 12201 |

## Мониторинг

### Health Checks
- **Liveness**: `GET /actuator/health/liveness`
- **Readiness**: `GET /actuator/health/readiness`
- **Startup**: `GET /actuator/health/startup`

### Prometheus Metrics
```bash
curl http://localhost:8083/actuator/prometheus
```

### Custom Metrics
- `notifications_created_total` - Счетчик созданных уведомлений
- `notifications_read_total` - Счетчик прочитанных уведомлений
- `kafka_events_consumed_total` - Счетчик обработанных Kafka событий
- `kafka_events_failed_total` - Счетчик ошибок обработки событий
- `notifications_unread_gauge` - Количество непрочитанных уведомлений

## Тестирование

### Запуск тестов
```bash
./gradlew test
```

### Отчет о покрытии
```bash
./gradlew jacocoTestReport
```

Отчет будет доступен в `build/reports/jacoco/test/html/index.html`

## Логирование

Сервис отправляет логи в Graylog через GELF UDP (порт 12201).

### Формат логов
```
[NOTIFICATION-SERVICE] [INFO] Kafka event consumed: TASK_CREATED - User: 1 - Topic: task-events
[NOTIFICATION-SERVICE] [INFO] Notification created: ID=1, User=1, Type=TASK_CREATED
[NOTIFICATION-SERVICE] [INFO] GET /api/notifications from 192.168.1.100 - Status: 200 - User: 1
```

### Поля логов
- `application` - notification-service
- `level` - INFO, WARN, ERROR
- `message` - Текст сообщения
- `http_method` - HTTP метод
- `url` - URL запроса
- `ip_address` - IP адрес клиента
- `user_id` - ID пользователя

## Обработка событий Kafka

### Типы событий

#### Auth Events (топик: auth-events)
- `USER_REGISTERED` → "Welcome! Your account has been created successfully."
- `USER_LOGGED_IN` → "You logged in to your account."

#### Task Events (топик: task-events)
- `TASK_CREATED` → "New task created: {title}"
- `TASK_UPDATED` → "Task updated: {title} - Status: {status}"
- `TASK_COMPLETED` → "Task completed: {title} ✓"
- `TASK_DELETED` → "Task deleted: {title}"

### Retry Policy
- Максимум 3 попытки
- Backoff: 1s, 2s, 4s
- Dead Letter Topic: `notification-service-dlt`

## Архитектура

```
┌─────────────┐
│   Kafka     │
│ (Events)    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│ KafkaConsumerService    │
│ - Consume events        │
│ - Create notifications  │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ NotificationService     │
│ - Business logic        │
│ - CRUD operations       │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ NotificationRepository  │
│ - Database access       │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    PostgreSQL           │
│  (notification_db)      │
└─────────────────────────┘
```

## Troubleshooting

### Проблема: Kafka consumer не получает сообщения
**Решение**: 
```bash
# Проверить топики
kubectl exec -n task-management kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list

# Проверить consumer group
kubectl exec -n task-management kafka-0 -- kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group notification-service-group
```

### Проблема: Не удается подключиться к БД
**Решение**:
```bash
# Проверить подключение
kubectl exec -n task-management notification-postgres-0 -- pg_isready -U notification_user

# Проверить credentials
kubectl get secret notification-service-secret -n task-management -o yaml
```

### Проблема: Логи не попадают в Graylog
**Решение**:
```bash
# Проверить GELF input в Graylog
# Проверить переменные окружения GRAYLOG_HOST и GRAYLOG_PORT
kubectl describe pod -n task-management -l app=notification-service
```

## Автор

Грибков А.С., ИКБО-16-22

## Лицензия

Учебный проект для МИРЭА

