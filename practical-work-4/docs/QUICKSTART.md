# Быстрый старт

## Минимальные требования

- Docker
- Docker Compose
- 8GB+ свободной RAM
- Свободные порты: 5432, 8080, 8081, 8090, 9000, 9090, 3000

## Запуск за 3 шага

### 1. Запуск системы

```bash
cd practical-work-4
docker-compose up -d --build
```

Первый запуск займёт 5-10 минут (скачивание образов, сборка приложения).

### 2. Ожидание готовности

```bash
# Следите за логами
docker-compose logs -f spring-app

# Дождитесь сообщения "Started MireaApplication"
```

Или подождите 2-3 минуты после запуска всех контейнеров.

### 3. Проверка работы

```bash
# Автоматическое тестирование
./scripts/test-monitoring.sh

# Или ручная проверка
curl http://localhost:8090/actuator/health
```

## Доступ к сервисам

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| Spring Boot API | http://localhost:8090 | - |
| Adminer (БД) | http://localhost:8080 | см. ниже* |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin |
| GrayLog | http://localhost:9000 | admin/admin |
| Zabbix | http://localhost:8081 | Admin/zabbix |

*Adminer: Server=`postgres`, User=`mirea_user`, Password=`mirea_password`, Database=`mirea_db`

## Быстрые тесты

### Создать пользователя
```bash
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","firstName":"Test","lastName":"User"}'
```

### Получить всех пользователей
```bash
curl http://localhost:8090/api/users
```

### Экспортировать логи в CSV
```bash
curl http://localhost:8090/api/logs/mock-export -o logs.csv
cat logs.csv
```

### Просмотр метрик
```bash
curl http://localhost:8090/actuator/prometheus | grep jvm_memory
```

## Просмотр дашбордов

1. **Grafana**: http://localhost:3000 (admin/admin)
   - Перейдите в Dashboards → MIREA Spring Boot Monitoring
   
2. **Prometheus**: http://localhost:9090
   - Query: `jvm_memory_used_bytes`
   
3. **GrayLog**: http://localhost:9000 (admin/admin)
   - Search → `application:mirea-spring-app`

## Остановка

```bash
# Остановить без удаления данных
docker-compose down

# Остановить и удалить все данные
docker-compose down -v
```

## Решение проблем

### Контейнеры не запускаются
```bash
# Проверить логи
docker-compose logs

# Пересоздать контейнеры
docker-compose down -v
docker-compose up -d --build
```

### Spring Boot не стартует
```bash
# Проверить логи приложения
docker-compose logs spring-app

# Часто помогает просто подождать ещё минуту
```

### Нет данных в Grafana
```bash
# Проверить Prometheus targets
curl http://localhost:9090/api/v1/targets

# Должны быть UP: spring-boot, postgres-exporter
```

### GrayLog не принимает логи
```bash
# Проверить, что GrayLog полностью запустился (занимает 2-3 минуты)
docker-compose logs graylog | grep "Started"
```

## Полезные команды

```bash
# Статус всех контейнеров
docker-compose ps

# Логи конкретного сервиса
docker-compose logs -f spring-app

# Перезапустить сервис
docker-compose restart spring-app

# Пересобрать только приложение
docker-compose up -d --build spring-app

# Проверить использование ресурсов
docker stats
```

## Для отчёта

Все инструкции по получению скриншотов - в README.md раздел "Получение скриншотов для отчёта".

