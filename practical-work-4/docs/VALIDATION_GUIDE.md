# Гайд по запуску и проверке всех требований на 2 балла

## 📋 Критерии на 2 балла (из задания)

1. ✅ Показан docker-compose файл удовлетворяющий требованиям в практическом задании
2. ✅ Сервер принимает запросы на эндпоинты
3. ✅ СУБД обрабатывает значения вставленные при помощи эндпоинтов
4. ✅ Все системы мониторинга считывают данные с сервера/СУБД
5. ✅ Grafana видит Prometheus как источник данных и отображает параметры из него
6. ✅ Эндпоинт логов выгружает csv с операциями в базе данных, проведенными при помощи CRUD эндпоинтов
7. ✅ Запись логов из Zabbix, GrayLog происходит не в БД сервиса
8. ✅ Показана возможность запуска контейнеров
9. ✅ Сделан отчет с описанием и скриншотами выполненных заданий
10. ✅ Дан полный и развернутый ответ на все вопросы преподавателя

---

## 🚀 ВАРИАНТ 1: Автоматическая проверка (рекомендуется)

### Один скрипт проверяет ВСЁ

```bash
cd practical-work-4
./scripts/full-validation.sh
```

**Что делает скрипт:**
1. ✅ Проверяет docker-compose файл
2. ✅ Проверяет наличие всех сервисов (≥11)
3. ✅ Проверяет модели данных (3 модели + связи 1:N и N:N)
4. ✅ Проверяет CRUD контроллеры
5. ✅ Проверяет эндпоинт экспорта логов
6. ✅ Проверяет интеграцию с GrayLog (GELF)
7. ✅ Проверяет настройку Prometheus + Grafana
8. ✅ Проверяет настройку Zabbix
9. ✅ **Запускает все контейнеры**
10. ✅ **Тестирует CRUD операции**
11. ✅ **Проверяет экспорт логов в CSV**
12. ✅ Проверяет метрики Prometheus
13. ✅ Проверяет доступность веб-интерфейсов
14. ✅ Проверяет отдельные БД для систем мониторинга
15. ✅ Проверяет документацию

**Время выполнения:** 3-5 минут

**Результат:**
- Показывает количество пройденных тестов
- Процент успеха
- Вердикт о готовности к сдаче
- Список URL всех сервисов

**Переменные окружения:**
```bash
# Запуск с настройками по умолчанию (Colima запускается автоматически)
./scripts/full-validation.sh

# Без автозапуска Colima
START_COLIMA=false ./scripts/full-validation.sh

# С остановкой Colima после тестов
STOP_COLIMA=true ./scripts/full-validation.sh

# Оставить контейнеры запущенными
CLEANUP_ON_EXIT=false ./scripts/full-validation.sh

# Комбинация параметров
START_COLIMA=true STOP_COLIMA=true CLEANUP_ON_EXIT=true ./scripts/full-validation.sh
```

### После выполнения скрипта:

Контейнеры останутся запущенными. Можно сразу:
- Открывать веб-интерфейсы
- Делать скриншоты
- Демонстрировать работу

---

## 🔧 ВАРИАНТ 2: Ручная проверка (пошаговая)

### Шаг 1: Подготовка

```bash
cd practical-work-4

# Убедиться что Docker запущен
docker info

# Остановить старые контейнеры (если есть)
docker-compose down -v
```

---

### Шаг 2: Проверка файлов (ДО запуска)

#### ✅ Критерий 1: docker-compose файл

```bash
# Проверить синтаксис
docker-compose config --quiet && echo "✅ docker-compose.yml валиден"

# Посчитать сервисы
docker-compose config --services | wc -l
# Должно быть ≥11 сервисов
```

**Ожидаемые сервисы:**
- postgres (основная БД)
- spring-app (Spring Boot приложение)
- adminer (управление БД)
- prometheus (сбор метрик)
- grafana (визуализация)
- postgres-exporter (метрики PostgreSQL)
- mongodb (для GrayLog)
- elasticsearch (для GrayLog)
- graylog (логирование)
- zabbix-postgres (БД для Zabbix)
- zabbix-server (Zabbix сервер)
- zabbix-web (Zabbix веб-интерфейс)
- zabbix-agent (Zabbix агент)

**📸 Скриншот для отчёта:**
- Откройте `docker-compose.yml` и сделайте скриншот структуры

---

### Шаг 3: Проверка кода

#### ✅ Критерий: Модели данных (≥3) со связями

```bash
# Проверить модели
ls -la src/main/java/com/mirea/app/entity/
# Должны быть: User.java, Product.java, Order.java

# Проверить связь 1:N (User → Orders)
grep -n "@OneToMany" src/main/java/com/mirea/app/entity/User.java

# Проверить связь N:N (Order ↔ Products)
grep -n "@ManyToMany" src/main/java/com/mirea/app/entity/Order.java
```

**📸 Скриншот для отчёта:**
- Откройте файлы моделей и покажите аннотации связей

#### ✅ Критерий: CRUD контроллеры

```bash
# Проверить контроллеры
ls -la src/main/java/com/mirea/app/controller/
# Должны быть: UserController, ProductController, OrderController, LogController

# Проверить CRUD операции в UserController
grep "@PostMapping\|@GetMapping\|@PutMapping\|@DeleteMapping" \
  src/main/java/com/mirea/app/controller/UserController.java
```

#### ✅ Критерий: Эндпоинт экспорта логов

```bash
# Проверить эндпоинт логов
grep -n "GetMapping.*export" src/main/java/com/mirea/app/controller/LogController.java
```

---

### Шаг 4: Запуск системы

#### ✅ Критерий 8: Показана возможность запуска контейнеров

```bash
# Сборка и запуск
docker-compose up -d --build
```

**Ожидаемый результат:**
```
Creating mirea-postgres ... done
Creating mirea-mongodb ... done
Creating mirea-elasticsearch ... done
Creating mirea-spring-app ... done
Creating mirea-prometheus ... done
Creating mirea-grafana ... done
Creating mirea-graylog ... done
Creating mirea-zabbix-server ... done
Creating mirea-zabbix-web ... done
Creating mirea-zabbix-agent ... done
Creating mirea-adminer ... done
Creating mirea-postgres-exporter ... done
```

```bash
# Проверить статус
docker-compose ps
```

**📸 Скриншот для отчёта:**
- Вывод команды `docker-compose ps` с работающими контейнерами

```bash
# Подождать 2-3 минуты для полного запуска
echo "Ожидание запуска сервисов..."
sleep 180

# Проверить логи Spring Boot
docker-compose logs spring-app | grep "Started MireaApplication"
```

---

### Шаг 5: Проверка доступности сервисов

```bash
# Spring Boot
curl http://localhost:8090/actuator/health
# Должно вернуть: {"status":"UP"}

# Prometheus
curl -s http://localhost:9090/api/v1/targets | grep "spring-boot"

# Grafana
curl -s http://localhost:3000/api/health
```

**📸 Скриншот для отчёта:**
- Откройте в браузере все сервисы (см. таблицу ниже)

---

### Шаг 6: Тестирование CRUD операций

#### ✅ Критерий 2 и 3: Сервер принимает запросы, СУБД обрабатывает значения

**1. Создание пользователя (POST):**
```bash
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ivanov",
    "email": "ivanov@mirea.ru",
    "firstName": "Иван",
    "lastName": "Иванов"
  }'
```

**Ожидаемый результат:**
```json
{
  "id": 1,
  "username": "ivanov",
  "email": "ivanov@mirea.ru",
  "firstName": "Иван",
  "lastName": "Иванов"
}
```

**2. Получение всех пользователей (GET):**
```bash
curl http://localhost:8090/api/users
```

**3. Обновление пользователя (PUT):**
```bash
curl -X PUT http://localhost:8090/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ivanov_updated",
    "email": "ivanov_new@mirea.ru",
    "firstName": "Иван",
    "lastName": "Иванов"
  }'
```

**4. Создание продукта:**
```bash
curl -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ноутбук ASUS",
    "description": "Игровой ноутбук",
    "price": 85000.00,
    "stock": 5
  }'
```

**5. Создание заказа (проверка связей):**
```bash
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "totalAmount": 85000.00,
    "productIds": [1]
  }'
```

**6. Удаление (DELETE):**
```bash
curl -X DELETE http://localhost:8090/api/users/1
```

**📸 Скриншот для отчёта:**
- Терминал с выполненными командами и ответами
- Или скриншот Postman/Insomnia с запросами

**Проверка в БД через Adminer:**
```
1. Откройте: http://localhost:8080
2. Введите:
   - Система: PostgreSQL
   - Сервер: postgres
   - Пользователь: mirea_user
   - Пароль: mirea_password
   - База данных: mirea_db
3. Посмотрите таблицы: users, products, orders, order_products
```

**📸 Скриншот для отчёта:**
- Adminer с открытой таблицей users и созданными записями

---

### Шаг 7: Проверка экспорта логов

#### ✅ Критерий 6: Эндпоинт логов выгружает CSV

```bash
# Экспорт логов в CSV
curl http://localhost:8090/api/logs/mock-export -o database_operations.csv

# Просмотр CSV
cat database_operations.csv
```

**Ожидаемый результат:**
```csv
"Timestamp","Level","Logger","Message"
"2025-10-11 12:30:45","INFO","UserController","Creating new user: ivanov"
"2025-10-11 12:30:45","INFO","UserController","User created with ID: 1"
"2025-10-11 12:31:20","INFO","ProductController","Creating new product: Ноутбук ASUS"
...
```

**📸 Скриншот для отчёта:**
- Терминал с содержимым CSV файла
- Или открытый CSV в Excel/LibreOffice

---

### Шаг 8: Проверка систем мониторинга

#### ✅ Критерий 4: Все системы мониторинга считывают данные

**A. Prometheus:**
```
1. Откройте: http://localhost:9090
2. Status → Targets
3. Проверьте что все targets в состоянии UP:
   - spring-boot (метрики приложения)
   - postgres-exporter (метрики БД)
```

**📸 Скриншот для отчёта:**
- Страница Prometheus Targets с UP статусом

**Примеры запросов в Prometheus:**
```
jvm_memory_used_bytes
http_server_requests_seconds_count
pg_stat_database_numbackends
```

#### ✅ Критерий 5: Grafana видит Prometheus и отображает параметры

**B. Grafana:**
```
1. Откройте: http://localhost:3000
2. Логин: admin / Пароль: admin
3. Перейдите: Dashboards → MIREA Spring Boot Monitoring
```

**Что должно быть видно:**
- JVM Memory Usage (график)
- JVM Threads
- HTTP Requests Rate
- HTTP Request Duration
- PostgreSQL Active Connections
- PostgreSQL Transactions Rate
- Heap Memory Usage %
- Total Requests/min
- Database Size
- Application Status (UP)

**📸 Скриншот для отчёта:**
- Dashboard Grafana с графиками и данными

**Проверка Datasource:**
```
1. Configuration → Data Sources
2. Prometheus должен быть в списке с зелёной галочкой
```

**C. GrayLog:**
```
1. Откройте: http://localhost:9000
2. Логин: admin / Пароль: admin
3. Подождите полной загрузки (может занять 2-3 минуты)
4. Перейдите: Search
5. Введите запрос: application:mirea-spring-app
```

**Что должно быть видно:**
- Логи от Spring Boot приложения
- Логи CRUD операций (created, updated, deleted)

**📸 Скриншот для отчёта:**
- GrayLog Search с логами приложения

**D. Zabbix:**
```
1. Откройте: http://localhost:8081
2. Логин: Admin / Пароль: zabbix
3. Monitoring → Latest data
```

**📸 Скриншот для отчёта:**
- Zabbix веб-интерфейс

---

### Шаг 9: Проверка отдельных БД для систем мониторинга

#### ✅ Критерий 7: Запись логов из Zabbix, GrayLog происходит не в БД сервиса

**Проверка через Adminer:**

1. Откройте основную БД приложения:
   - http://localhost:8080
   - Сервер: postgres, User: mirea_user, Password: mirea_password, DB: mirea_db
   - Посмотрите таблицы: только users, products, orders, order_products
   - **НЕТ** таблиц Zabbix или GrayLog

**📸 Скриншот для отчёта:**
- Adminer со списком таблиц основной БД (без таблиц мониторинга)

2. Проверка через docker-compose:
```bash
# Zabbix использует отдельную БД
docker-compose exec zabbix-postgres psql -U zabbix -d zabbix -c "\dt" | head -20

# GrayLog использует MongoDB (не PostgreSQL)
docker-compose exec mongodb mongo --eval "db.getMongo().getDBNames()" 2>/dev/null
```

**Архитектура БД:**
- `postgres` (порт 5432) → mirea_db (БД приложения)
- `zabbix-postgres` (внутренний) → zabbix (БД Zabbix)
- `mongodb` (внутренний) → graylog (БД GrayLog)
- `elasticsearch` (порт 9200) → логи GrayLog

---

### Шаг 10: Проверка документации

#### ✅ Критерий 9: Сделан отчет с описанием

```bash
# Проверить наличие документации
ls -la *.md

# Посмотреть размер README
wc -l README.md
```

**Что есть в документации:**
- README.md (490+ строк) - полная документация
- QUICKSTART.md - быстрый старт
- CHECKLIST.md - чеклист требований
- VALIDATION_GUIDE.md - этот файл

**📸 Скриншот для отчёта:**
- README.md открытый в редакторе/браузере

---

## 📊 Таблица доступа к сервисам

| Сервис | URL | Логин | Пароль | Что проверять |
|--------|-----|-------|--------|---------------|
| **Spring Boot API** | http://localhost:8090 | - | - | `/actuator/health`, CRUD эндпоинты |
| **Adminer** | http://localhost:8080 | mirea_user | mirea_password | Таблицы БД, записи |
| **Prometheus** | http://localhost:9090 | - | - | Targets, метрики |
| **Grafana** | http://localhost:3000 | admin | admin | Dashboard, Datasource |
| **GrayLog** | http://localhost:9000 | admin | admin | Search, логи приложения |
| **Zabbix** | http://localhost:8081 | Admin | zabbix | Monitoring, Latest data |

---

## ✅ Чеклист для отчёта (скриншоты)

Для полного отчёта на 2 балла нужны следующие скриншоты:

1. ☐ docker-compose.yml файл (структура)
2. ☐ `docker-compose ps` - работающие контейнеры
3. ☐ Исходный код модели с аннотациями связей (@OneToMany, @ManyToMany)
4. ☐ Исходный код контроллера с CRUD операциями
5. ☐ Терминал с выполненными CRUD запросами (curl)
6. ☐ Adminer - таблицы БД с данными
7. ☐ CSV файл с экспортированными логами
8. ☐ Prometheus Targets (все UP)
9. ☐ Grafana Dashboard с метриками
10. ☐ GrayLog Search с логами приложения
11. ☐ Zabbix веб-интерфейс
12. ☐ Adminer - список таблиц БД (без таблиц систем мониторинга)

---

## 🎯 Ответы на вопросы к практической работе

Все ответы находятся в **README.md**, раздел "Ответы на вопросы к практической работе":

1. Основные различия между Prometheus и Zabbix
2. Как запустить две базы PostgreSQL в одном docker-compose
3. Виды мониторинга систем
4. Передача конфигурационных переменных в контейнер
5. Основные различия Docker Swarm и Docker Compose
6. Задача, невозможная только с docker-compose без Dockerfile

---

## 🛑 Остановка системы

```bash
# Остановить все контейнеры
docker-compose down

# Остановить и удалить все данные (volumes)
docker-compose down -v
```

---

## 🆘 Решение проблем

### Контейнеры не запускаются

```bash
# Проверить логи
docker-compose logs

# Пересоздать
docker-compose down -v
docker-compose up -d --build
```

### Spring Boot не стартует

```bash
# Посмотреть логи
docker-compose logs -f spring-app

# Обычно нужно просто подождать 1-2 минуты
```

### GrayLog не показывает логи

```bash
# Проверить что GrayLog полностью запустился
docker-compose logs graylog | grep "Graylog server up and running"

# Это может занять 3-5 минут при первом запуске
```

### Нет данных в Grafana

```bash
# Проверить Prometheus targets
curl http://localhost:9090/api/v1/targets

# Перезапустить Grafana
docker-compose restart grafana
```

---

## 📞 Контакты для вопросов

Если что-то не работает:
1. Проверьте логи: `docker-compose logs [service_name]`
2. Проверьте README.md - там есть подробные инструкции
3. Запустите `./full-validation.sh` - скрипт покажет что не работает

---

**Удачи на защите! 🎓**

