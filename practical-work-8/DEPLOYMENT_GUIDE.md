# Руководство по развертыванию Task Management System

## Быстрый старт

### Автоматическое развертывание (рекомендуется)

```bash
# 1. Развернуть всю систему одной командой
./deploy-all.sh

# 2. Запустить port forwarding
./port-forward.sh

# 3. В другом терминале - протестировать систему
./test-system.sh
```

Это все! Система будет полностью развернута и готова к использованию.

## Описание скриптов

### `deploy-all.sh` - Главный скрипт развертывания

Автоматически выполняет все шаги развертывания:

1. ✅ Проверяет наличие необходимых инструментов (docker, kubectl, helm, minikube)
2. ✅ Запускает Docker/Colima если не запущен
3. ✅ Настраивает Minikube кластер (4 CPU, 8GB RAM)
4. ✅ Создает namespace `task-management`
5. ✅ Устанавливает инфраструктуру через Helm:
   - PostgreSQL (3 инстанса для каждого сервиса)
   - Redis (для хранения JWT токенов)
   - Kafka (для событий между сервисами)
   - Prometheus (сбор метрик)
   - Grafana (визуализация метрик)
   - Jaeger (распределенная трассировка)
6. ✅ Собирает Docker образы микросервисов
7. ✅ Загружает образы в Minikube
8. ✅ Разворачивает микросервисы (Auth, Task, Notification)
9. ✅ Проверяет статус развертывания
10. ✅ Создает скрипт port-forward.sh

**Время выполнения:** ~10-15 минут

### `port-forward.sh` - Проброс портов

Создает port forwarding для доступа к сервисам:

- **Auth Service:** http://localhost:8081
- **Task Service:** http://localhost:8082
- **Notification Service:** http://localhost:8083
- **Grafana:** http://localhost:3000 (admin/admin)
- **Prometheus:** http://localhost:9090
- **Jaeger:** http://localhost:16686

Запустите в отдельном терминале и оставьте работать.

### `test-system.sh` - Интеграционные тесты

Выполняет полный набор тестов:

1. ✅ Проверка health endpoints всех сервисов
2. ✅ Регистрация пользователя
3. ✅ Вход в систему (получение JWT токена)
4. ✅ Валидация токена
5. ✅ Создание задачи
6. ✅ Получение списка задач
7. ✅ Получение уведомлений
8. ✅ Статистика по задачам
9. ✅ Проверка Kafka топиков
10. ✅ Проверка подключений к БД
11. ✅ Проверка Redis

**Требование:** Должен быть запущен `port-forward.sh`

### `status.sh` - Статус системы

Показывает текущее состояние:
- Статус Minikube
- Список подов
- Список сервисов
- PVC (Persistent Volume Claims)
- Helm releases
- Использование ресурсов
- Последние события

### `cleanup.sh` - Очистка

Удаляет все компоненты системы:
- Микросервисы
- Инфраструктуру
- PVC
- Namespace
- Опционально: Minikube кластер

## Ручное развертывание

Если нужно выполнить шаги вручную:

### 1. Запуск Docker/Colima

```bash
# Если используете Colima
colima start --cpu 4 --memory 8 --disk 20

# Проверка
docker ps
```

### 2. Настройка Minikube

```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=20g \
  --kubernetes-version=v1.28.0

minikube addons enable metrics-server
```

### 3. Создание namespace

```bash
kubectl create namespace task-management
kubectl config set-context --current --namespace=task-management
```

### 4. Установка инфраструктуры

```bash
# Добавление Helm репозиториев
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# PostgreSQL для Auth Service
helm install auth-postgres bitnami/postgresql \
  --namespace task-management \
  --set auth.username=auth_user \
  --set auth.password=auth_password \
  --set auth.database=auth_db \
  --set primary.persistence.size=1Gi

# PostgreSQL для Task Service
helm install task-postgres bitnami/postgresql \
  --namespace task-management \
  --set auth.username=task_user \
  --set auth.password=task_password \
  --set auth.database=task_db \
  --set primary.persistence.size=1Gi

# PostgreSQL для Notification Service
helm install notification-postgres bitnami/postgresql \
  --namespace task-management \
  --set auth.username=notification_user \
  --set auth.password=notification_password \
  --set auth.database=notification_db \
  --set primary.persistence.size=1Gi

# Redis
helm install redis bitnami/redis \
  --namespace task-management \
  --set auth.password=redis_password \
  --set master.persistence.enabled=false \
  --set replica.replicaCount=0

# Kafka
helm install kafka bitnami/kafka \
  --namespace task-management \
  --set kraft.enabled=true \
  --set controller.replicaCount=1 \
  --set broker.replicaCount=1

# Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace task-management \
  --set alertmanager.enabled=false \
  --set pushgateway.enabled=false

# Grafana
helm install grafana grafana/grafana \
  --namespace task-management \
  --set adminPassword=admin

# Jaeger
helm install jaeger jaegertracing/jaeger \
  --namespace task-management \
  --set allInOne.enabled=true \
  --set storage.type=memory
```

### 5. Сборка и загрузка образов

```bash
# Auth Service
cd auth-service
docker build -t auth-service:latest .
minikube image load auth-service:latest

# Task Service
cd ../task-service
docker build -t task-service:latest .
minikube image load task-service:latest

# Notification Service
cd ../notification-service
docker build -t notification-service:latest .
minikube image load notification-service:latest
```

### 6. Развертывание микросервисов

```bash
# Auth Service
helm install auth-service ./auth-service/helm/auth-service \
  --namespace task-management \
  --set image.repository=auth-service \
  --set image.tag=latest \
  --set image.pullPolicy=Never

# Task Service
helm install task-service ./task-service/helm/task-service \
  --namespace task-management \
  --set image.repository=task-service \
  --set image.tag=latest \
  --set image.pullPolicy=Never

# Notification Service
helm install notification-service ./notification-service/helm/notification-service \
  --namespace task-management \
  --set image.repository=notification-service \
  --set image.tag=latest \
  --set image.pullPolicy=Never
```

## Проверка развертывания

```bash
# Статус подов
kubectl get pods -n task-management

# Логи сервиса
kubectl logs -n task-management -l app=auth-service --tail=50 -f

# Статус системы
./status.sh
```

## Использование API

### 1. Регистрация пользователя

```bash
curl -X POST http://localhost:8081/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

### 2. Вход в систему

```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "testuser",
    "password": "Test123!"
  }'
```

Сохраните полученный токен в переменную:
```bash
TOKEN="your-jwt-token-here"
```

### 3. Создание задачи

```bash
curl -X POST http://localhost:8082/api/tasks \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement authentication",
    "description": "Add JWT-based auth",
    "status": "PENDING"
  }'
```

### 4. Получение задач

```bash
curl -X GET http://localhost:8082/api/tasks \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Получение уведомлений

```bash
curl -X GET http://localhost:8083/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

## Мониторинг

### Grafana
- URL: http://localhost:3000
- Логин: admin
- Пароль: admin

Добавьте Prometheus как datasource:
- URL: http://prometheus-server:80

### Prometheus
- URL: http://localhost:9090

Примеры запросов:
```promql
# Request rate
rate(http_server_requests_seconds_count[5m])

# Memory usage
jvm_memory_used_bytes

# Database connections
hikaricp_connections_active
```

### Jaeger
- URL: http://localhost:16686

Просмотр трейсов запросов через все сервисы.

## Troubleshooting

### Проблема: Поды не запускаются

```bash
# Проверить статус
kubectl get pods -n task-management

# Посмотреть описание пода
kubectl describe pod <pod-name> -n task-management

# Посмотреть логи
kubectl logs <pod-name> -n task-management
```

### Проблема: Нет подключения к БД

```bash
# Проверить PostgreSQL
kubectl exec -n task-management auth-postgres-postgresql-0 -- pg_isready

# Проверить секреты
kubectl get secrets -n task-management
```

### Проблема: Kafka не работает

```bash
# Проверить Kafka
kubectl logs -n task-management -l app.kubernetes.io/name=kafka

# Список топиков
kubectl exec -n task-management kafka-0 -- \
  kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Проблема: Minikube не запускается

```bash
# Удалить и создать заново
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192
```

## Требования к системе

- **CPU:** 4 ядра минимум
- **RAM:** 8GB минимум
- **Disk:** 20GB свободного места
- **OS:** macOS, Linux, Windows (с WSL2)

## Необходимое ПО

- Docker Desktop или Colima
- Minikube
- kubectl
- Helm 3
- curl (для тестирования)
- jq (опционально, для форматирования JSON)

## Полезные команды

```bash
# Перезапустить под
kubectl rollout restart deployment auth-service -n task-management

# Масштабировать сервис
kubectl scale deployment auth-service --replicas=3 -n task-management

# Посмотреть использование ресурсов
kubectl top pods -n task-management

# Получить IP Minikube
minikube ip

# Открыть dashboard
minikube dashboard
```

## Архитектура

```
┌─────────────┐
│   Клиент    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Auth Service│ ──► PostgreSQL
│   (8081)    │ ──► Redis
│             │ ──► Kafka
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Task Service│ ──► PostgreSQL
│   (8082)    │ ──► Kafka
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│Notification Srv  │ ──► PostgreSQL
│     (8083)       │ ◄── Kafka
└──────────────────┘
       │
       ▼
┌──────────────────┐
│   Monitoring     │
│ Prometheus       │
│ Grafana          │
│ Jaeger           │
└──────────────────┘
```

## Автор

Грибков А.С., ИКБО-16-22

## Лицензия

Учебный проект для МИРЭА


