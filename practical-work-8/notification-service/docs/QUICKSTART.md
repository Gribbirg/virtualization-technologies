# Notification Service - Quick Start

## Быстрый старт для разработки

### 1. Запуск зависимостей

```bash
# PostgreSQL
docker run -d --name notification-postgres \
  -e POSTGRES_DB=notification_db \
  -e POSTGRES_USER=notification_user \
  -e POSTGRES_PASSWORD=notification_password \
  -p 5434:5432 \
  postgres:15

# Kafka + Zookeeper
docker run -d --name zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  confluentinc/cp-zookeeper:7.5.0

docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  confluentinc/cp-kafka:7.5.0

# Подождите 30 секунд для инициализации Kafka
sleep 30
```

### 2. Создание топиков Kafka

```bash
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic auth-events \
  --partitions 3 \
  --replication-factor 1

docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic task-events \
  --partitions 3 \
  --replication-factor 1
```

### 3. Запуск приложения

```bash
./gradlew bootRun
```

### 4. Проверка работоспособности

```bash
# Health check
curl http://localhost:8083/actuator/health

# Prometheus metrics
curl http://localhost:8083/actuator/prometheus
```

### 5. Тестирование Kafka consumer

```bash
# Отправить тестовое событие
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic task-events \
  --property "parse.key=true" \
  --property "key.separator=:"

# Введите (нажмите Enter после каждой строки):
key1:{"eventType":"TASK_CREATED","userId":1,"metadata":{"title":"Test Task"}}
```

### 6. Проверка логов

```bash
# Проверить, что уведомление создано
# В логах приложения должно появиться:
# [NOTIFICATION-SERVICE] [INFO] Kafka event consumed: TASK_CREATED - User: 1
# [NOTIFICATION-SERVICE] [INFO] Notification created: ID=1, User=1, Type=TASK_CREATED
```

## Быстрый старт для Kubernetes

### 1. Сборка образа

```bash
docker build -t notification-service:latest .
```

### 2. Загрузка в Minikube

```bash
minikube image load notification-service:latest
```

### 3. Развертывание

```bash
helm install notification-service ./helm/notification-service \
  -n task-management \
  --create-namespace
```

### 4. Проверка статуса

```bash
kubectl get pods -n task-management -l app=notification-service
kubectl logs -n task-management -l app=notification-service
```

### 5. Port forwarding

```bash
kubectl port-forward -n task-management svc/notification-service 8083:8083
```

## Тестирование

```bash
# Запуск всех тестов
./gradlew test

# Запуск с отчетом о покрытии
./gradlew test jacocoTestReport

# Просмотр отчета
open build/reports/jacoco/test/html/index.html
```

## Остановка

```bash
# Остановить приложение: Ctrl+C

# Остановить Docker контейнеры
docker stop notification-postgres kafka zookeeper
docker rm notification-postgres kafka zookeeper

# Удалить из Kubernetes
helm uninstall notification-service -n task-management
```

## Troubleshooting

### Проблема: Kafka не подключается
```bash
# Проверить статус Kafka
docker logs kafka

# Проверить топики
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

### Проблема: PostgreSQL не подключается
```bash
# Проверить статус
docker logs notification-postgres

# Подключиться к БД
docker exec -it notification-postgres psql -U notification_user -d notification_db
```

### Проблема: Приложение не стартует
```bash
# Проверить Java версию (нужна 21)
java -version

# Очистить build
./gradlew clean

# Пересобрать
./gradlew build
```

