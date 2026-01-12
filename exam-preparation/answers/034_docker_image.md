# Что такое образ Docker и для чего он нужен?

## Краткий ответ

Образ Docker (Docker Image) — это неизменяемый (immutable) шаблон, содержащий все необходимое для запуска приложения: код, среду выполнения, библиотеки, системные инструменты и конфигурации. Образ состоит из набора read-only слоев файловой системы, накладываемых друг на друга. Образы используются для создания контейнеров, обеспечивают портативность приложений, версионирование и возможность быстрого развертывания.

## Развёрнутый ответ

### Определение

Docker образ — это исполняемый пакет, который включает все необходимое для запуска приложения:
- Код приложения
- Runtime окружение (Node.js, Python, JVM и т.д.)
- Системные библиотеки
- Системные инструменты
- Переменные окружения
- Конфигурационные файлы
- Метаданные (CMD, ENTRYPOINT, EXPOSE и т.д.)

### Структура образа

#### Слоистая архитектура (Layered Architecture)

Образ состоит из нескольких read-only слоев, каждый из которых представляет инструкцию из Dockerfile:

```
┌─────────────────────────────────┐
│  Writable Container Layer       │ ← Добавляется при создании контейнера
├─────────────────────────────────┤
│  Layer 4: COPY app.py /app/     │ ← Read-only
├─────────────────────────────────┤
│  Layer 3: RUN pip install -r    │ ← Read-only
├─────────────────────────────────┤
│  Layer 2: COPY requirements.txt │ ← Read-only
├─────────────────────────────────┤
│  Layer 1: FROM python:3.9       │ ← Base image (Read-only)
└─────────────────────────────────┘
```

**Характеристики слоев**:
- Каждый слой — это diff по отношению к предыдущему
- Слои read-only и неизменяемы
- Слои могут быть shared между образами (экономия места)
- Идентифицируются SHA256 hash
- Union File System объединяет слои в единую файловую систему

**Copy-on-Write (CoW)**:
- При запуске контейнера создается writable layer поверх образа
- Изменения файлов происходят в writable layer
- Оригинальные файлы в образе остаются неизменными
- При изменении файла из нижних слоев, он копируется в writable layer

#### Метаданные образа

Образ содержит JSON-конфигурацию с метаданными:
- **Config**: команда запуска, переменные окружения, рабочая директория
- **Architecture**: x86_64, arm64 и т.д.
- **OS**: linux, windows
- **History**: история создания слоев
- **RootFS**: информация о слоях файловой системы

Просмотр метаданных:
```bash
docker inspect image_name
docker history image_name
```

### Типы образов

#### 1. Base Images (Базовые образы)

Образы, которые не имеют родительского образа, содержат минимальную ОС:
- `alpine` — минималистичный Linux (~5 MB)
- `ubuntu` — Ubuntu Linux
- `debian` — Debian Linux
- `scratch` — пустой образ для статических бинарей

**Пример**:
```dockerfile
FROM alpine:3.18
```

#### 2. Parent Images (Родительские образы)

Образы, построенные на базовых образах, добавляющие runtime:
- `python:3.9`
- `node:18`
- `openjdk:11`
- `nginx:alpine`

#### 3. Official Images (Официальные образы)

Образы, поддерживаемые Docker и сообществом:
- Проверены на безопасность
- Регулярно обновляются
- Оптимизированы по размеру
- Документированы

**Примеры**: nginx, redis, postgres, mysql, python, node

#### 4. User Images (Пользовательские образы)

Образы, созданные пользователями и организациями:
- Формат: `username/image_name:tag`
- Хранятся в Docker Hub или private registry
- Могут быть публичными или приватными

### Теги образов

**Формат**: `repository:tag`
- `nginx:latest` — последняя версия
- `nginx:1.21.0` — конкретная версия
- `nginx:1.21.0-alpine` — версия на Alpine Linux
- `myregistry.com/myapp:v1.0` — образ из private registry

**Значение latest**:
- Не обязательно последняя версия!
- Это просто default тег
- Best practice: всегда указывать конкретную версию

**Semantic versioning**:
```bash
nginx:1           # major version
nginx:1.21        # major.minor
nginx:1.21.0      # major.minor.patch
```

### Операции с образами

#### Поиск образов

```bash
# Поиск в Docker Hub
docker search nginx
docker search --filter stars=100 nginx

# Список локальных образов
docker images
docker images --filter dangling=true  # неиспользуемые слои
```

#### Загрузка образов

```bash
# Pull из registry
docker pull nginx
docker pull nginx:1.21.0
docker pull myregistry.com/myapp:latest

# Pull всех тегов
docker pull --all-tags nginx
```

#### Создание образов

**Из Dockerfile**:
```bash
docker build -t myapp:1.0 .
docker build -t myapp:1.0 -f Dockerfile.prod .
docker build --no-cache -t myapp:1.0 .
```

**Из контейнера** (commit):
```bash
docker commit container_id myimage:tag
docker commit -m "Added new feature" -a "Author" container_id myimage:tag
```

**Import из tar**:
```bash
docker import backup.tar myimage:tag
```

#### Тегирование образов

```bash
# Создать новый тег
docker tag myapp:1.0 myapp:latest
docker tag myapp:1.0 myregistry.com/myapp:1.0

# Multiple tags
docker tag myapp:1.0 myapp:1
docker tag myapp:1.0 myapp:1.0.0
```

#### Публикация образов

```bash
# Push в registry
docker login
docker push myapp:1.0
docker push myregistry.com/myapp:1.0
```

#### Удаление образов

```bash
# Удалить образ
docker rmi image_name
docker rmi image_id

# Удалить все unused образы
docker image prune

# Удалить все образы
docker rmi $(docker images -q)

# Удалить dangling образы
docker image prune --filter dangling=true
```

### Зачем нужны образы

#### 1. Портативность

**Проблема без Docker**:
- Приложение работает на dev машине, но падает на production
- "Works on my machine" проблема
- Различия в версиях библиотек и зависимостей

**Решение с Docker образами**:
- Образ содержит все зависимости
- Одинаковое окружение везде
- Гарантированная работа приложения

#### 2. Версионирование

**Version control для инфраструктуры**:
```bash
myapp:1.0.0  # Stable release
myapp:1.1.0  # New features
myapp:2.0.0  # Breaking changes
```

**Возможности**:
- Откат к предыдущей версии за секунды
- A/B testing разных версий
- История изменений
- Audit trail

#### 3. Быстрое развертывание

**Традиционное развертывание**:
1. Установка ОС
2. Установка runtime
3. Установка зависимостей
4. Копирование кода
5. Конфигурация
6. Запуск

**С Docker образами**:
```bash
docker run myapp:1.0  # Все в одной команде!
```

#### 4. Согласованность окружений

**Dev, Test, Staging, Production** — одинаковый образ:
- Нет различий в конфигурациях
- Нет проблем с dependency hell
- Предсказуемое поведение

#### 5. Изоляция приложений

**Несколько версий на одном хосте**:
```bash
docker run python:2.7 myapp-legacy
docker run python:3.9 myapp-new
```

Нет конфликтов зависимостей!

#### 6. Эффективность ресурсов

**Layer sharing**:
```
myapp-frontend:1.0 ─┐
                     ├─→ node:18 (shared)
myapp-backend:1.0  ─┘
```

Базовый образ хранится один раз, экономия места и bandwidth.

#### 7. CI/CD интеграция

**Pipeline**:
1. Commit code
2. Build image
3. Test image
4. Push to registry
5. Deploy to environment

**Автоматизация**:
```yaml
# GitLab CI example
build:
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker push myapp:$CI_COMMIT_SHA
```

#### 8. Микросервисная архитектура

**Каждый сервис — отдельный образ**:
```
user-service:1.0
payment-service:1.0
notification-service:1.0
```

**Преимущества**:
- Независимое развертывание
- Разные технологические стеки
- Масштабирование отдельных компонентов

#### 9. Безопасность

**Image scanning**:
```bash
docker scan myapp:1.0  # Поиск уязвимостей
```

**Image signing** (Docker Content Trust):
- Верификация publisher
- Защита от tampering
- Гарантия подлинности

**Base image updates**:
- Регулярные security patches
- Автоматический rebuild при обновлении базового образа

#### 10. Распространение приложений

**Docker Hub как "App Store"**:
- Скачать готовое приложение одной командой
- Готовые конфигурации
- Community support

**Пример**:
```bash
docker run -d -p 3000:3000 ghost  # CMS запущена!
docker run -d -p 8080:80 wordpress  # Blog запущен!
```

### Best Practices для образов

#### 1. Используйте официальные базовые образы

```dockerfile
FROM python:3.9-slim  # Official + slim variant
```

#### 2. Используйте конкретные версии

```dockerfile
FROM node:18.16.0-alpine  # Не используйте :latest
```

#### 3. Минимизируйте количество слоев

```dockerfile
# Плохо - много слоев
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Хорошо - один слой
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

#### 4. Используйте .dockerignore

```
node_modules
.git
*.log
.env
```

#### 5. Multi-stage builds

```dockerfile
# Build stage
FROM node:18 AS builder
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
COPY --from=builder /app/dist /app
CMD ["node", "app.js"]
```

Результат: меньший размер финального образа.

#### 6. Кэширование слоев

```dockerfile
# Хорошо - зависимости кэшируются
COPY package.json .
RUN npm install
COPY . .

# Плохо - при изменении кода переустанавливаются зависимости
COPY . .
RUN npm install
```

#### 7. Минимальные привилегии

```dockerfile
RUN adduser -D appuser
USER appuser
```

#### 8. Health checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
```

### Хранение и распространение

**Docker Registry**:
- Docker Hub (публичный)
- Amazon ECR
- Google GCR
- Azure ACR
- Private registry (Harbor, Artifactory)

**Storage**:
- Локально: `/var/lib/docker/`
- Registry: распределенное хранилище
- Deduplicated layers

## Источники

- Docker Documentation: Images and Layers
- Docker Best Practices Guide
- OCI Image Specification
- Docker Deep Dive by Nigel Poulton
- Dockerfile Best Practices (Docker Official)
- Container Image Security Best Practices
