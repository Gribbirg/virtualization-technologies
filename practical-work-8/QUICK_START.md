# Quick Start Guide

## Автоматическое развертывание за 3 команды

### 1. Развернуть систему

```bash
./deploy-all.sh
```

Этот скрипт автоматически:
- ✅ Запустит Docker/Colima
- ✅ Настроит Minikube (4 CPU, 8GB RAM)
- ✅ Установит инфраструктуру (PostgreSQL, Redis, Kafka, Prometheus, Grafana, Jaeger)
- ✅ Соберет и загрузит Docker образы
- ✅ Развернет микросервисы (Auth, Task, Notification)

⏱️ **Время:** ~10-15 минут

### 2. Запустить port forwarding

```bash
./port-forward.sh
```

Оставьте этот терминал открытым. Сервисы будут доступны:
- Auth Service: http://localhost:8081
- Task Service: http://localhost:8082
- Notification Service: http://localhost:8083
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686

### 3. Протестировать систему

В **новом терминале**:

```bash
./test-system.sh
```

Этот скрипт выполнит полный набор интеграционных тестов.

## Проверка статуса

```bash
./status.sh
```

## Очистка

```bash
./cleanup.sh
```

## Ручное тестирование API

### Регистрация

```bash
curl -X POST http://localhost:8081/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"user1","email":"user1@test.com","password":"Pass123!"}'
```

### Вход

```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"user1","password":"Pass123!"}'
```

Сохраните токен из ответа:
```bash
TOKEN="your-token-here"
```

### Создание задачи

```bash
curl -X POST http://localhost:8082/api/tasks \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My Task","description":"Test","status":"PENDING"}'
```

### Получение задач

```bash
curl http://localhost:8082/api/tasks \
  -H "Authorization: Bearer $TOKEN"
```

### Получение уведомлений

```bash
curl http://localhost:8083/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

## Доступные скрипты

| Скрипт | Описание |
|--------|----------|
| `deploy-all.sh` | Полное развертывание системы |
| `port-forward.sh` | Проброс портов для доступа к сервисам |
| `test-system.sh` | Интеграционные тесты |
| `status.sh` | Статус системы |
| `cleanup.sh` | Удаление всех компонентов |

## Мониторинг

### Grafana
http://localhost:3000 (admin/admin)

### Prometheus
http://localhost:9090

### Jaeger
http://localhost:16686

## Логи

```bash
# Auth Service
kubectl logs -n task-management -l app=auth-service -f

# Task Service
kubectl logs -n task-management -l app=task-service -f

# Notification Service
kubectl logs -n task-management -l app=notification-service -f
```

## Troubleshooting

### Проблема: Docker не запущен

```bash
colima start --cpu 4 --memory 8 --disk 20
```

### Проблема: Поды не запускаются

```bash
kubectl get pods -n task-management
kubectl describe pod <pod-name> -n task-management
kubectl logs <pod-name> -n task-management
```

### Проблема: Port forwarding не работает

Убедитесь, что все поды в статусе `Running`:
```bash
kubectl get pods -n task-management
```

Перезапустите port forwarding:
```bash
pkill -f "kubectl port-forward"
./port-forward.sh
```

## Требования

- **CPU:** 4 ядра
- **RAM:** 8GB
- **Disk:** 20GB
- **ПО:** Docker, Minikube, kubectl, Helm 3

## Подробная документация

См. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) для детальных инструкций.

---

**Автор:** Грибков А.С., ИКБО-16-22  
**Проект:** Практическая работа №8 - Микросервисная система управления задачами


