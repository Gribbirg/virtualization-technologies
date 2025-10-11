# 🚀 Шпаргалка - Практическая работа 4

## ⚡ Быстрый запуск

```bash
cd practical-work-4

# Автоматическая проверка ВСЕХ требований
./full-validation.sh

# Или вручную
docker-compose up -d --build
```

## 📋 Критерии на 2 балла

| № | Критерий | Как проверить |
|---|----------|---------------|
| 1 | docker-compose файл | `docker-compose config --quiet` |
| 2 | Сервер принимает запросы | `curl http://localhost:8090/actuator/health` |
| 3 | СУБД обрабатывает значения | Adminer: http://localhost:8080 |
| 4 | Системы мониторинга работают | Prometheus, Grafana, GrayLog, Zabbix |
| 5 | Grafana + Prometheus | http://localhost:3000 → Dashboard |
| 6 | Экспорт логов в CSV | `curl http://localhost:8090/api/logs/mock-export` |
| 7 | Отдельные БД для мониторинга | zabbix-postgres, mongodb |
| 8 | Контейнеры запускаются | `docker-compose ps` |
| 9 | Документация | README.md (490+ строк) |
| 10 | Ответы на вопросы | README.md (раздел "Ответы") |

## 🌐 URL всех сервисов

```
Spring Boot:  http://localhost:8090
Adminer:      http://localhost:8080  (postgres/mirea_user/mirea_password/mirea_db)
Prometheus:   http://localhost:9090
Grafana:      http://localhost:3000  (admin/admin)
GrayLog:      http://localhost:9000  (admin/admin)
Zabbix:       http://localhost:8081  (Admin/zabbix)
```

## 🔧 CRUD команды

### Создать пользователя
```bash
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","firstName":"Test","lastName":"User"}'
```

### Получить пользователей
```bash
curl http://localhost:8090/api/users
```

### Создать продукт
```bash
curl -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"Gaming","price":1500.00,"stock":10}'
```

### Создать заказ (связь N:N)
```bash
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"totalAmount":1500.00,"productIds":[1]}'
```

### Экспорт логов в CSV
```bash
curl http://localhost:8090/api/logs/mock-export -o logs.csv
cat logs.csv
```

## 📸 Скриншоты для отчёта

1. docker-compose.yml
2. `docker-compose ps` - все контейнеры UP
3. Код моделей (User, Product, Order) с аннотациями
4. Терминал с CRUD запросами
5. Adminer - таблицы с данными
6. CSV файл с логами
7. Prometheus Targets (все UP)
8. Grafana Dashboard
9. GrayLog с логами
10. Zabbix веб-интерфейс

## 🛑 Управление

```bash
# Статус
docker-compose ps

# Логи
docker-compose logs -f spring-app

# Перезапуск сервиса
docker-compose restart spring-app

# Остановка
docker-compose down

# Полная очистка
docker-compose down -v
```

## 📚 Документация

- **VALIDATION_GUIDE.md** - полный гайд по проверке (10+ страниц)
- **README.md** - основная документация (490+ строк)
- **QUICKSTART.md** - быстрый старт за 3 шага
- **CHECKLIST.md** - детальный чеклист

## ✅ Структура проекта

```
✅ 3 модели данных (User, Product, Order)
✅ Связь 1:N (User → Orders)
✅ Связь N:N (Order ↔ Products)
✅ 4 контроллера (User, Product, Order, Log)
✅ 13 сервисов в docker-compose
✅ GELF логирование в GrayLog
✅ Grafana dashboard (10 панелей)
✅ Prometheus + postgres-exporter
✅ Zabbix (Server + Web + Agent)
✅ Отдельные БД для мониторинга
```

## 🎯 Одна команда для всего

```bash
# Запустить + проверить + показать результаты
./full-validation.sh
```

Этот скрипт:
- ✅ Проверит все файлы
- ✅ Запустит контейнеры
- ✅ Протестирует CRUD
- ✅ Проверит экспорт логов
- ✅ Проверит метрики
- ✅ Покажет процент готовности

**Время: 3-5 минут**

---

💡 **Совет:** Запустите `./full-validation.sh` перед защитой, чтобы убедиться что всё работает!

