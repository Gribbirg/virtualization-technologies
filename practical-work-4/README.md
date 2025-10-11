# Практическая работа 4: Мониторинг Spring Boot сервиса

> 🚀 **Быстрый старт:** См. [docs/START_HERE.md](docs/START_HERE.md)

## Описание

Данный проект представляет собой Spring Boot приложение с системой комплексного мониторинга, включающей PostgreSQL, Prometheus, Grafana, GrayLog, Zabbix и Adminer. Приложение автоматически отправляет логи в GrayLog через GELF протокол, экспортирует метрики для Prometheus и имеет готовый дашборд в Grafana.

## 📚 Документация

- **[START_HERE.md](docs/START_HERE.md)** - Начните отсюда! Быстрый старт
- **[VALIDATION_GUIDE.md](docs/VALIDATION_GUIDE.md)** - Полный гайд по проверке всех требований
- **[CHEATSHEET.md](docs/CHEATSHEET.md)** - Шпаргалка с командами
- **[QUICKSTART.md](docs/QUICKSTART.md)** - Быстрый запуск за 3 шага
- **[CHECKLIST.md](docs/CHECKLIST.md)** - Чеклист выполнения требований

## 🔧 Скрипты

- **[full-validation.sh](scripts/full-validation.sh)** - Полная автоматическая проверка всех требований
- **[test-monitoring.sh](scripts/test-monitoring.sh)** - Тестирование системы мониторинга
- **[quick-test.sh](scripts/quick-test.sh)** - Быстрая проверка без запуска
- **[test-docker.sh](scripts/test-docker.sh)** - Дополнительное тестирование

## Архитектура системы

### Основные компоненты:
1. **Spring Boot приложение** - REST API с CRUD операциями и автоматической отправкой логов в GrayLog
2. **PostgreSQL** - основная база данных для приложения
3. **Adminer** - веб-интерфейс для управления БД
4. **Prometheus** - сбор метрик из Spring Boot и PostgreSQL
5. **Grafana** - визуализация метрик с готовым дашбордом
6. **GrayLog (+ MongoDB + Elasticsearch)** - сбор и анализ логов через GELF протокол
7. **Zabbix (Server + Web + Agent)** - системный мониторинг инфраструктуры

### Модель данных:
- **User** (пользователи)
- **Product** (продукты)
- **Order** (заказы)

**Отношения:**
- User → Orders (1:N)
- Order → Products (N:N через промежуточную таблицу order_products)

## Инструкции по запуску

### Предварительные требования:
- Docker
- Docker Compose
- 8GB+ свободной оперативной памяти

### Запуск системы:

```bash
# 1. Клонировать проект и перейти в директорию
cd practical-work-4

# 2. Собрать и запустить все сервисы
docker-compose up -d --build

# 3. Дождаться запуска всех сервисов (может занять 2-3 минуты)
docker-compose logs -f

# 4. Запустить тестирование
./scripts/test-monitoring.sh
```

## Доступ к сервисам

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| Spring Boot API | http://localhost:8090 | - |
| Adminer | http://localhost:8080 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin |
| GrayLog | http://localhost:9000 | admin/admin |
| Zabbix | http://localhost:8081 | Admin/zabbix |

## API эндпоинты

### Users (Пользователи)
- `GET /api/users` - получить всех пользователей
- `POST /api/users` - создать пользователя
- `GET /api/users/{id}` - получить пользователя по ID
- `PUT /api/users/{id}` - обновить пользователя
- `DELETE /api/users/{id}` - удалить пользователя
- `GET /api/users/username/{username}` - найти по имени пользователя

### Products (Продукты)
- `GET /api/products` - получить все продукты
- `POST /api/products` - создать продукт
- `GET /api/products/{id}` - получить продукт по ID
- `PUT /api/products/{id}` - обновить продукт
- `DELETE /api/products/{id}` - удалить продукт
- `GET /api/products/search?name={name}` - поиск по названию
- `GET /api/products/in-stock?minStock={count}` - продукты в наличии

### Orders (Заказы)
- `GET /api/orders` - получить все заказы
- `POST /api/orders` - создать заказ
- `GET /api/orders/{id}` - получить заказ по ID
- `PUT /api/orders/{id}` - обновить заказ
- `DELETE /api/orders/{id}` - удалить заказ
- `GET /api/orders/user/{userId}` - заказы пользователя
- `GET /api/orders/status/{status}` - заказы по статусу

### Logs (Логи)
- `GET /api/logs/export?hours={hours}` - экспорт логов из GrayLog в CSV
- `GET /api/logs/mock-export` - экспорт тестовых логов в CSV

## Примеры запросов

### Создание пользователя:
```bash
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### Создание продукта:
```bash
curl -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "description": "Gaming laptop",
    "price": 1500.00,
    "stock": 5
  }'
```

### Создание заказа:
```bash
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "totalAmount": 1500.00,
    "productIds": [1]
  }'
```

### Экспорт логов:
```bash
curl -X GET http://localhost:8090/api/logs/mock-export \
  -H "Accept: text/csv" \
  --output database_operations.csv
```

## Мониторинг

### Prometheus метрики:
- JVM метрики (heap memory, threads, GC)
- HTTP метрики (request rate, duration, status codes)
- PostgreSQL метрики (connections, transactions, database size)
- Кастомные метрики приложения

### Grafana дашборды:
Система включает готовый дашборд "MIREA Spring Boot Monitoring" с панелями:
- JVM Memory Usage (график использования памяти)
- JVM Threads (живые и daemon потоки)
- HTTP Requests Rate (частота HTTP запросов)
- HTTP Request Duration (средняя длительность запросов)
- PostgreSQL Active Connections (активные подключения к БД)
- PostgreSQL Transactions Rate (транзакции: commits и rollbacks)
- Heap Memory Usage % (gauge индикатор использования heap памяти)
- Total Requests/min (общее количество запросов в минуту)
- Database Size (размер базы данных)
- Application Status (статус приложения UP/DOWN)

Дашборд автоматически загружается при запуске и доступен по адресу: http://localhost:3000

### GrayLog логирование:
- Автоматическая отправка логов через GELF протокол (UDP порт 12201)
- Структурированные логи с дополнительными полями (application, environment)
- Логирование всех CRUD операций с базой данных
- Экспорт логов в CSV формат через API эндпоинт

### Zabbix мониторинг:
- Zabbix Server для управления мониторингом
- Zabbix Agent для сбора метрик
- Веб-интерфейс для настройки хостов и триггеров
- Возможность настройки уведомлений и алертов

## Ответы на вопросы к практической работе

### 1. Основные различия между Prometheus и Zabbix

**Prometheus:**
- Система мониторинга временных рядов (time-series)
- Pull-модель сбора метрик
- Собственный язык запросов PromQL
- Предназначен для мониторинга метрик и производительности
- Легковесный, ориентирован на микросервисы
- Лучше подходит для современных cloud-native приложений

**Zabbix:**
- Универсальная система мониторинга инфраструктуры
- Push/Pull модель сбора данных
- Широкие возможности мониторинга (сеть, серверы, приложения)
- Встроенная система уведомлений и эскалации
- Мощный веб-интерфейс с готовыми шаблонами
- Лучше подходит для традиционной IT-инфраструктуры

### 2. Запуск двух баз PostgreSQL в docker-compose

```yaml
services:
  postgres-main:
    image: postgres:15
    environment:
      POSTGRES_DB: main_db
      POSTGRES_USER: main_user
      POSTGRES_PASSWORD: main_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_main_data:/var/lib/postgresql/data

  postgres-second:
    image: postgres:15
    environment:
      POSTGRES_DB: second_db
      POSTGRES_USER: second_user
      POSTGRES_PASSWORD: second_pass
    ports:
      - "5433:5432"  # Разные порты
    volumes:
      - postgres_second_data:/var/lib/postgresql/data  # Разные volume

volumes:
  postgres_main_data:
  postgres_second_data:
```

### 3. Виды мониторинга систем

1. **Инфраструктурный мониторинг** - контроль серверов, сети, хранилищ (Zabbix, Nagios)
2. **Мониторинг производительности приложений (APM)** - метрики приложений (Prometheus, New Relic)
3. **Мониторинг логов** - сбор и анализ журналов (GrayLog, ELK Stack)
4. **Мониторинг безопасности** - обнаружение угроз (SIEM системы)
5. **Синтетический мониторинг** - проверка доступности (Pingdom, Uptime Robot)
6. **Мониторинг пользовательского опыта** - RUM (Real User Monitoring)

### 4. Передача конфигурационных переменных в контейнер

1. **Environment variables** в docker-compose.yml:
```yaml
environment:
  - DB_HOST=postgres
  - DB_PORT=5432
```

2. **Файл .env**:
```yaml
env_file:
  - .env
```

3. **Внешний файл переменных**:
```yaml
env_file:
  - ./config/app.env
```

4. **Secrets** (в Docker Swarm):
```yaml
secrets:
  - db_password
```

5. **ConfigMaps и Secrets** (в Kubernetes)

### 5. Основные различия Docker Swarm и Docker Compose

**Docker Compose:**
- Инструмент для локальной разработки
- Определение multi-container приложений
- Работает на одном хосте
- Файл docker-compose.yml описывает сервисы
- Не предоставляет высокую доступность
- Простая оркестрация

**Docker Swarm:**
- Система оркестрации контейнеров
- Кластерное решение для продакшена
- Работает на множестве хостов
- Встроенная балансировка нагрузки
- Высокая доступность и масштабируемость
- Автоматическое восстановление сервисов
- Rolling updates
- Service discovery

### 6. Задача, невозможная только с docker-compose без Dockerfile

**Установка дополнительного программного обеспечения в образ**

Пример: Необходимо создать образ с приложением, но также установить дополнительные системные пакеты, скопировать файлы конфигурации или выполнить компиляцию кода.

```dockerfile
# Невозможно сделать только в docker-compose.yml
FROM ubuntu:20.04

# Установка дополнительных пакетов
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копирование исходного кода
COPY ./src /app/src
COPY requirements.txt /app/

# Установка зависимостей
WORKDIR /app
RUN pip3 install -r requirements.txt

# Компиляция или сборка
RUN python3 setup.py build

CMD ["python3", "app.py"]
```

Docker Compose может только использовать готовые образы или собирать из существующих Dockerfile, но не может модифицировать образы "на лету".

## Настройка GrayLog (опционально)

После запуска системы GrayLog автоматически принимает логи на порту 12201 (GELF UDP). Однако для доступа к веб-интерфейсу и API может потребоваться настройка:

1. Откройте http://localhost:9000 (логин: admin, пароль: admin)
2. Дождитесь полной загрузки GrayLog (может занять 2-3 минуты)
3. Input для GELF UDP уже настроен автоматически на порту 12201
4. Логи от Spring Boot приложения начнут поступать автоматически

### Просмотр логов в GrayLog:
1. Перейдите в раздел "Search"
2. В поле поиска введите `application:mirea-spring-app` для фильтрации логов приложения
3. Можно фильтровать по полям: logger_name, level, message
4. Для поиска операций с БД: `message:*created* OR message:*updated* OR message:*deleted*`

## Получение скриншотов для отчёта

### 1. Docker Compose файл
Просмотрите содержимое `docker-compose.yml` - он содержит все необходимые сервисы

### 2. Работающие контейнеры
```bash
docker-compose ps
```

### 3. Adminer - управление БД
- URL: http://localhost:8080
- Сервер: postgres, Пользователь: mirea_user, Пароль: mirea_password, База: mirea_db
- Показать таблицы users, products, orders, order_products

### 4. Prometheus
- URL: http://localhost:9090
- Targets: http://localhost:9090/targets (должны быть UP)
- Пример запроса: `jvm_memory_used_bytes`

### 5. Grafana Dashboard
- URL: http://localhost:3000 (admin/admin)
- Откройте дашборд "MIREA Spring Boot Monitoring"
- Должны быть видны все графики с данными

### 6. GrayLog
- URL: http://localhost:9000 (admin/admin)
- Перейдите в Search
- Покажите полученные логи от приложения

### 7. Zabbix
- URL: http://localhost:8081 (Admin/zabbix)
- Monitoring → Latest data
- Показать мониторинг хостов

### 8. CSV экспорт логов
```bash
curl http://localhost:8090/api/logs/mock-export -o logs.csv
cat logs.csv
```

### 9. CRUD операции
Выполните запросы из секции "Примеры запросов" и покажите результаты

### 10. Метрики приложения
```bash
curl http://localhost:8090/actuator/prometheus
```

## Остановка системы

```bash
# Остановить все сервисы
docker-compose down

# Остановить и удалить volumes (ВНИМАНИЕ: удалит все данные)
docker-compose down -v
```

## Структура проекта

```
practical-work-4/
├── src/main/java/com/mirea/app/
│   ├── entity/              # Модели данных (User, Product, Order)
│   ├── repository/          # JPA репозитории
│   ├── controller/          # REST контроллеры (User, Product, Order, Log)
│   └── MireaApplication.java
├── src/main/resources/
│   ├── application.yml      # Конфигурация Spring Boot
│   └── logback-spring.xml   # Конфигурация логирования с GELF
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml   # Конфигурация Prometheus (scrape targets)
│   └── grafana/
│       └── provisioning/
│           ├── datasources/
│           │   └── prometheus.yml  # Автоматическая настройка Prometheus datasource
│           └── dashboards/
│               ├── dashboard.yml   # Провайдер дашбордов
│               └── spring-boot-dashboard.json  # Готовый дашборд
├── scripts/                 # Скрипты тестирования и проверки
│   ├── full-validation.sh   # Полная автоматическая проверка всех требований
│   ├── quick-test.sh        # Быстрая проверка без запуска контейнеров
│   ├── test-monitoring.sh   # Тестирование системы мониторинга
│   └── test-docker.sh       # Дополнительный скрипт тестирования
├── docs/                    # Документация
│   ├── START_HERE.md        # Начните отсюда
│   ├── VALIDATION_GUIDE.md  # Полный гайд по проверке требований
│   ├── CHEATSHEET.md        # Шпаргалка с командами
│   ├── QUICKSTART.md        # Быстрый старт
│   └── CHECKLIST.md         # Чеклист выполнения
├── logs/                    # Директория для файловых логов
├── docker-compose.yml       # Описание всех сервисов (13 контейнеров)
├── Dockerfile               # Multi-stage образ Spring Boot приложения
├── build.gradle.kts         # Зависимости проекта (включая logback-gelf)
└── README.md                # Основная документация проекта
```

## Технологический стек

### Backend:
- Java 21
- Spring Boot 3.2.8
- Spring Data JPA
- PostgreSQL 15
- Gradle 8.14

### Мониторинг:
- Prometheus (сбор метрик)
- Grafana (визуализация)
- GrayLog 5.0 + Elasticsearch 7.17 + MongoDB 6.0 (логирование)
- Zabbix 6.0 (системный мониторинг)
- Postgres Exporter (метрики БД)

### Библиотеки:
- Spring Boot Actuator (метрики)
- Micrometer Prometheus Registry (экспорт метрик)
- Logback GELF (отправка логов в GrayLog)
- OpenCSV (экспорт в CSV)

## Критерии выполнения практической работы

### ✅ Выполненные требования:

1. **CRUD набор для взаимодействия с БД**
   - Эндпоинты для Users (создание, чтение, обновление, удаление)
   - Эндпоинты для Products (создание, чтение, обновление, удаление, поиск)
   - Эндпоинты для Orders (создание, чтение, обновление, удаление, фильтрация)

2. **Модели данных (≥3) со связями**
   - User (пользователи)
   - Product (продукты)
   - Order (заказы)
   - Связь 1:N - User → Orders
   - Связь N:N - Order ↔ Products (через order_products)

3. **Эндпоинт для выгрузки логов из GrayLog**
   - `/api/logs/export` - реальная интеграция с GrayLog API
   - `/api/logs/mock-export` - mock данные для тестирования
   - Экспорт в CSV формат

4. **PostgreSQL как основная СУБД**
   - База данных mirea_db для приложения
   - Отдельная БД для Zabbix (логи систем мониторинга не в основной БД)

5. **Zabbix для мониторинга**
   - Zabbix Server
   - Zabbix Web Interface
   - Zabbix Agent
   - Отдельная PostgreSQL БД для хранения данных Zabbix

6. **Prometheus + Grafana**
   - Prometheus собирает метрики с Spring Boot и PostgreSQL
   - Grafana подключена к Prometheus как datasource
   - Готовый дашборд с 10 панелями метрик

7. **GrayLog для логов**
   - MongoDB для метаданных GrayLog
   - Elasticsearch для хранения логов
   - GELF UDP Input на порту 12201
   - Автоматическая отправка логов из Spring Boot

8. **Adminer для управления БД**
   - Веб-интерфейс на порту 8080
   - Доступ к PostgreSQL базе данных

### ✅ Дополнительные требования:
- Docker-compose файл с 11 сервисами
- Автоматическое тестирование через shell скрипт
- Подробная документация с ответами на вопросы
- Multi-stage Dockerfile для оптимизации размера образа