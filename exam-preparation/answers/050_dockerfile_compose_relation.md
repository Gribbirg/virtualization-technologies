# Как соотносятся между собой файлы Dockerfile и Docker-Compose?

## Краткий ответ
Dockerfile и docker-compose.yml решают разные задачи: Dockerfile описывает, КАК собрать образ одного контейнера (инструкции по сборке), а docker-compose.yml описывает, КАК запустить и связать несколько контейнеров вместе (оркестрация многоконтейнерного приложения). Dockerfile создает образ, docker-compose использует готовые образы для запуска сервисов.

## Развёрнутый ответ

### Dockerfile: Создание образов контейнеров

**Назначение:**
Dockerfile — это текстовый файл с инструкциями для автоматической сборки Docker-образа. Он описывает шаги, необходимые для создания образа: базовый образ, установка зависимостей, копирование файлов, настройка окружения.

**Основные инструкции:**
```dockerfile
# Базовый образ
FROM node:18-alpine

# Установка рабочей директории
WORKDIR /app

# Копирование файлов зависимостей
COPY package*.json ./

# Установка зависимостей
RUN npm ci --only=production

# Копирование исходного кода
COPY . .

# Открытие порта
EXPOSE 3000

# Команда запуска
CMD ["node", "server.js"]
```

**Ключевые инструкции:**
- `FROM` — базовый образ
- `RUN` — выполнение команд при сборке
- `COPY/ADD` — копирование файлов в образ
- `WORKDIR` — установка рабочей директории
- `ENV` — переменные окружения
- `EXPOSE` — документирование портов
- `CMD/ENTRYPOINT` — команда запуска контейнера

**Результат:**
Создается неизменяемый (immutable) образ, который можно запускать множество раз, получая идентичные контейнеры.

**Команды работы:**
```bash
# Сборка образа
docker build -t my-app:v1 .

# Запуск контейнера из образа
docker run -p 3000:3000 my-app:v1
```

### Docker Compose: Оркестрация многоконтейнерных приложений

**Назначение:**
docker-compose.yml — это декларативный YAML-файл для определения и запуска многоконтейнерных приложений. Он описывает сервисы, сети, volumes и их взаимосвязи.

**Пример docker-compose.yml:**
```yaml
version: '3.8'

services:
  # Frontend сервис
  web:
    build: ./frontend                # Сборка из Dockerfile
    # или
    # image: my-frontend:v1          # Использование готового образа
    ports:
      - "80:80"
    depends_on:
      - api
    environment:
      - API_URL=http://api:3000
    networks:
      - app-network

  # Backend API сервис
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - REDIS_URL=redis://redis:6379
    volumes:
      - ./backend:/app
      - /app/node_modules
    networks:
      - app-network

  # База данных
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

  # Кэш
  redis:
    image: redis:7-alpine
    networks:
      - app-network

volumes:
  db-data:

networks:
  app-network:
    driver: bridge
```

**Основные секции:**
- `services` — описание контейнеров
- `networks` — виртуальные сети
- `volumes` — persistent storage
- `configs` — конфигурационные файлы
- `secrets` — чувствительные данные

**Команды работы:**
```bash
# Запуск всех сервисов
docker-compose up

# Запуск в фоновом режиме
docker-compose up -d

# Остановка и удаление контейнеров
docker-compose down

# Просмотр логов
docker-compose logs -f

# Масштабирование сервиса
docker-compose up -d --scale api=3
```

## Взаимосвязь Dockerfile и docker-compose.yml

### 1. Разделение ответственности

**Dockerfile → "Как собрать":**
- Описывает процесс сборки образа
- Определяет содержимое контейнера
- Создает слои файловой системы
- Устанавливает зависимости и конфигурирует приложение

**docker-compose.yml → "Как запустить":**
- Описывает запуск и связывание контейнеров
- Определяет runtime-конфигурацию
- Управляет сетями и volumes
- Координирует взаимодействие между сервисами

### 2. Использование образов в Compose

**Вариант 1: Использование готового образа**
```yaml
services:
  web:
    image: nginx:alpine  # Образ из Docker Hub
```

**Вариант 2: Сборка из Dockerfile**
```yaml
services:
  api:
    build: ./api  # Dockerfile находится в ./api/Dockerfile
```

**Вариант 3: Сборка с параметрами**
```yaml
services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile.prod
      args:
        - NODE_ENV=production
        - VERSION=1.2.3
```

### 3. Build-time vs Runtime конфигурация

**Build-time (Dockerfile):**
```dockerfile
# Устанавливается ПРИ СБОРКЕ образа
FROM python:3.11
RUN pip install flask sqlalchemy
COPY . /app
WORKDIR /app
# Эти значения "запечены" в образ
ENV DEFAULT_PORT=5000
```

**Runtime (docker-compose.yml):**
```yaml
services:
  app:
    image: my-python-app
    # Устанавливается ПРИ ЗАПУСКЕ контейнера
    environment:
      - PORT=8080              # Переопределяет DEFAULT_PORT
      - DATABASE_URL=postgres://...
    ports:
      - "8080:8080"
    volumes:
      - ./config:/app/config
```

### 4. Паттерны совместного использования

**Паттерн 1: Отдельные Dockerfile для каждого сервиса**
```
project/
├── docker-compose.yml
├── frontend/
│   ├── Dockerfile
│   └── src/
├── backend/
│   ├── Dockerfile
│   └── src/
└── worker/
    ├── Dockerfile
    └── src/
```

```yaml
# docker-compose.yml
services:
  frontend:
    build: ./frontend
  backend:
    build: ./backend
  worker:
    build: ./worker
```

**Паттерн 2: Многоэтапная сборка (multi-stage Dockerfile)**
```dockerfile
# Dockerfile
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --only=production
CMD ["node", "dist/server.js"]
```

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: builder  # Использовать промежуточный stage для dev
```

**Паттерн 3: Разные Dockerfile для dev и prod**
```
project/
├── Dockerfile              # Production
├── Dockerfile.dev          # Development
├── docker-compose.yml      # Production
└── docker-compose.dev.yml  # Development
```

```yaml
# docker-compose.dev.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - ./src:/app/src  # Hot reload для dev
```

### 5. Build arguments и environment variables

**Build arguments (ARG) в Dockerfile:**
```dockerfile
FROM node:18
ARG NODE_ENV=development
ARG APP_VERSION=1.0.0

RUN echo "Building for ${NODE_ENV}"
# ARG доступен только во время сборки
```

**Передача build args через docker-compose:**
```yaml
services:
  app:
    build:
      context: .
      args:
        - NODE_ENV=production
        - APP_VERSION=1.2.3
```

**Environment variables (ENV) — runtime:**
```yaml
services:
  app:
    image: my-app
    environment:
      - DATABASE_URL=${DATABASE_URL}  # Из .env файла
      - API_KEY=secret_key
```

### 6. Caching и оптимизация

**Оптимизация Dockerfile для кэширования:**
```dockerfile
# Плохо — изменение любого файла инвалидирует все слои
COPY . /app
RUN npm install

# Хорошо — изменение кода не влияет на установку зависимостей
COPY package*.json /app/
RUN npm install
COPY . /app
```

**Использование кэша в Compose:**
```bash
# Принудительная пересборка без кэша
docker-compose build --no-cache

# Сборка с pull новых версий базовых образов
docker-compose build --pull
```

## Типичные сценарии использования

### Сценарий 1: Микросервисная архитектура

**Структура проекта:**
```
microservices/
├── docker-compose.yml
├── user-service/
│   ├── Dockerfile
│   └── src/
├── order-service/
│   ├── Dockerfile
│   └── src/
├── payment-service/
│   ├── Dockerfile
│   └── src/
└── api-gateway/
    ├── Dockerfile
    └── src/
```

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  user-service:
    build: ./user-service
    environment:
      - SERVICE_NAME=user-service
      - DATABASE_URL=postgresql://...

  order-service:
    build: ./order-service
    depends_on:
      - user-service

  payment-service:
    build: ./payment-service
    depends_on:
      - order-service

  api-gateway:
    build: ./api-gateway
    ports:
      - "80:80"
    depends_on:
      - user-service
      - order-service
      - payment-service
```

### Сценарий 2: Development и Production окружения

**Dockerfile (универсальный):**
```dockerfile
FROM node:18 AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM base AS development
RUN npm install  # включая dev dependencies
CMD ["npm", "run", "dev"]

FROM base AS production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

**docker-compose.yml (production):**
```yaml
services:
  app:
    build:
      context: .
      target: production
    restart: always
```

**docker-compose.dev.yml (development):**
```yaml
services:
  app:
    build:
      context: .
      target: development
    volumes:
      - ./src:/app/src  # Hot reload
    command: npm run dev
```

**Запуск:**
```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose up
```

### Сценарий 3: Использование внешних образов

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  # Собственное приложение
  app:
    build: .
    depends_on:
      - db
      - redis

  # Внешние сервисы (готовые образы)
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=secret

  redis:
    image: redis:7-alpine

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

## Распространенные ошибки и best practices

### Ошибка 1: Смешивание build и runtime конфигурации

**Плохо:**
```dockerfile
# Жестко заданные значения в Dockerfile
ENV DATABASE_URL=postgresql://localhost:5432/db
```

**Хорошо:**
```dockerfile
# Значение по умолчанию, которое можно переопределить
ENV DATABASE_URL=postgresql://localhost:5432/db
```

```yaml
# docker-compose.yml — переопределение для разных окружений
services:
  app:
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

### Ошибка 2: Большие образы

**Плохо:**
```dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3 python3-pip ...
```

**Хорошо:**
```dockerfile
FROM python:3.11-slim
# Минимальный базовый образ
```

### Ошибка 3: Установка зависимостей при каждой сборке

**Плохо:**
```dockerfile
COPY . /app
RUN pip install -r requirements.txt
```

**Хорошо:**
```dockerfile
COPY requirements.txt /app/
RUN pip install -r requirements.txt
COPY . /app
```

### Best Practice 1: .dockerignore

```
# .dockerignore
node_modules
.git
.env
*.log
Dockerfile
docker-compose.yml
```

### Best Practice 2: Health checks

**Dockerfile:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1
```

**docker-compose.yml:**
```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Best Practice 3: Использование .env файла

**.env:**
```
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret
DATABASE_URL=postgresql://admin:secret@db:5432/mydb
```

**docker-compose.yml:**
```yaml
services:
  app:
    environment:
      - DATABASE_URL=${DATABASE_URL}
  db:
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
```

## Выводы

**Dockerfile и docker-compose.yml — комплементарные инструменты:**

- **Dockerfile** решает задачу "как создать образ контейнера"
- **docker-compose.yml** решает задачу "как запустить и связать контейнеры"
- Они работают на разных уровнях абстракции
- Dockerfile создает building blocks, docker-compose их оркестрирует
- Для сложных приложений оба файла необходимы
- Правильное использование обоих инструментов повышает воспроизводимость и упрощает развертывание

## Источники
- Docker Official Documentation on Dockerfile reference
- Docker Compose Official Documentation
- "Docker Deep Dive" by Nigel Poulton
- Docker best practices guides
- Real-world multi-container application examples
