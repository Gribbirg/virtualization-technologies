# Опишите устройство Docker-образа

## Краткий ответ

Docker-образ — это иммутабельный многослойный шаблон для создания контейнеров, состоящий из read-only слоёв (layers), каждый из которых представляет изменения файловой системы. Слои организованы по принципу union file system, совместно используются между образами (экономия места), и имеют хэш-идентификацию через SHA256. При запуске контейнера добавляется writable слой поверх read-only слоёв образа.

## Развёрнутый ответ

Docker-образ является фундаментальной концепцией контейнеризации. Понимание его внутреннего устройства критично для эффективного использования Docker.

### 1. Общая концепция Docker-образа

### Определение

Docker-образ — это:
- **Иммутабельный (неизменяемый)** шаблон для контейнеров
- **Многослойная** файловая система
- **Самодостаточный** пакет со всеми зависимостями
- **Версионируемый** через теги
- **Портативный** между разными системами

### Отличие образа от контейнера

```
┌────────────────────────────────┐
│    Running Container           │
│  ┌──────────────────────────┐  │
│  │  Writable Layer (R/W)    │  │ ← Изменения контейнера
│  └──────────────────────────┘  │
├────────────────────────────────┤
│         Docker Image           │
│  ┌──────────────────────────┐  │
│  │  Layer 4 (Read-Only)     │  │
│  ├──────────────────────────┤  │
│  │  Layer 3 (Read-Only)     │  │
│  ├──────────────────────────┤  │
│  │  Layer 2 (Read-Only)     │  │
│  ├──────────────────────────┤  │
│  │  Layer 1 (Read-Only)     │  │ ← Базовый слой
│  └──────────────────────────┘  │
└────────────────────────────────┘

Image = Read-only layers (неизменяемые)
Container = Image + Writable layer (изменяемый)
```

### 2. Слоистая архитектура (Layered Architecture)

### Концепция слоёв (Layers)

Каждый слой представляет собой:
- **Набор изменений файловой системы** (файлы добавлены, изменены или удалены)
- **Результат выполнения одной инструкции** в Dockerfile
- **Иммутабельную единицу** с уникальным идентификатором

**Пример Dockerfile и слои:**

```dockerfile
FROM ubuntu:22.04              # Layer 1: Базовый образ Ubuntu
RUN apt-get update             # Layer 2: Обновление пакетов
RUN apt-get install -y nginx   # Layer 3: Установка nginx
COPY index.html /var/www/html  # Layer 4: Копирование файла
RUN echo "v1.0" > /version.txt # Layer 5: Создание файла
CMD ["nginx", "-g", "daemon off;"]  # Не создаёт слой (metadata)
```

**Соответствующая структура слоёв:**

```
┌──────────────────────────────────┐
│ Layer 5: /version.txt            │  ← sha256:def456...
├──────────────────────────────────┤
│ Layer 4: /var/www/html/index.html│ ← sha256:cde345...
├──────────────────────────────────┤
│ Layer 3: nginx files             │  ← sha256:bcd234...
├──────────────────────────────────┤
│ Layer 2: updated apt cache       │  ← sha256:abc123...
├──────────────────────────────────┤
│ Layer 1: Ubuntu base filesystem  │  ← sha256:890xyz...
└──────────────────────────────────┘
```

### Инструкции создающие слои

**Создают новый layer:**
- `FROM` — базовый слой
- `RUN` — выполнение команд
- `COPY` — копирование файлов с хоста
- `ADD` — копирование + распаковка архивов

**Не создают layer (только metadata):**
- `CMD` — команда запуска по умолчанию
- `ENTRYPOINT` — точка входа
- `ENV` — переменные окружения
- `EXPOSE` — открытые порты
- `VOLUME` — точки монтирования
- `USER` — пользователь
- `WORKDIR` — рабочая директория
- `LABEL` — метаданные

### 3. Union File System

### Принцип работы

Union FS объединяет несколько read-only слоёв в единую файловую систему:

```
Логическое представление:
/
├── bin/
├── etc/
│   └── nginx/
├── var/
│   └── www/
│       └── html/
│           └── index.html
└── version.txt

Физическое хранение:
Layer 1: /bin/, /etc/ (кроме nginx/)
Layer 2: /var/ (кроме www/)
Layer 3: /etc/nginx/, /var/www/
Layer 4: /var/www/html/index.html
Layer 5: /version.txt
```

### Storage Drivers

Docker поддерживает различные драйверы для union file system:

**OverlayFS (рекомендуется для Linux):**
```
/var/lib/docker/overlay2/
├── <layer-id>/
│   ├── diff/           # Содержимое слоя
│   ├── link            # Короткий идентификатор
│   ├── lower           # Ссылка на нижние слои
│   └── work/           # Рабочая директория
```

**Другие драйверы:**
- **AUFS** — legacy, не в mainline kernel
- **Btrfs** — использует нативные снапшоты
- **ZFS** — использует нативные клоны
- **Device Mapper** — block-level CoW
- **VFS** — без оптимизаций (для тестирования)

### Copy-on-Write (CoW)

**Механизм оптимизации:**

```
1. Чтение файла:
   - Поиск в слоях сверху вниз
   - Возврат первого найденного

2. Изменение файла:
   - Файл копируется в writable layer контейнера
   - Изменения происходят в копии
   - Оригинал в read-only слое остаётся неизменным

3. Удаление файла:
   - Создаётся whiteout файл в writable layer
   - Файл скрывается, но остаётся в нижних слоях
```

**Пример:**
```bash
# В образе есть /app/config.json (в read-only слое)
# Контейнер изменяет файл
echo '{"changed": true}' > /app/config.json

# Файл копируется в writable layer
# Оригинал остаётся в образе
# Другие контейнеры видят оригинальный файл
```

### 4. Идентификация и хэширование

### Content-addressable Storage

Каждый слой идентифицируется через **SHA256 хэш** его содержимого:

```bash
# Просмотр слоёв образа
docker image inspect nginx:alpine

"RootFS": {
    "Type": "layers",
    "Layers": [
        "sha256:8921db27df2831fa6eaa85321205a2470c669b855f3ec95d5a3c2b46de0442c9",
        "sha256:b3efc9c2304e9be5f18d91c5e4a70b47e0e75c5bf6f8bc0c3bc0a4d4e1a0a1ef",
        "sha256:7f55c2fc64d471e0b63e9e5a6b9fbc6c7a7c6cd2ef8e6e9d7a0b3e2c1d4e5f6a"
    ]
}
```

### Content Addressability преимущества

**1. Дедупликация:**
```bash
# Два образа используют одинаковый базовый слой
docker pull nginx:1.24
docker pull nginx:1.25

# Ubuntu base layer загружается только один раз
# Экономия дискового пространства и трафика
```

**2. Верификация целостности:**
```bash
# Docker проверяет хэш при pull
# Гарантия неизменности данных
# Защита от tampering
```

**3. Кэширование:**
```bash
# Слой с тем же хэшем не пересобирается
docker build -t myapp:v1 .
# При повторной сборке используются кэшированные слои
```

### 5. Метаданные образа

### Image Manifest

Manifest описывает структуру образа:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "size": 7023,
    "digest": "sha256:abc123..."
  },
  "layers": [
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "size": 2789669,
      "digest": "sha256:layer1..."
    },
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "size": 108,
      "digest": "sha256:layer2..."
    }
  ]
}
```

### Image Configuration

Конфигурация содержит метаданные и историю:

```json
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": ["nginx", "-g", "daemon off;"],
    "WorkingDir": "/app",
    "ExposedPorts": {"80/tcp": {}},
    "Volumes": {"/data": {}}
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:layer1...",
      "sha256:layer2...",
      "sha256:layer3..."
    ]
  },
  "history": [
    {
      "created": "2024-01-10T12:00:00Z",
      "created_by": "/bin/sh -c apt-get update",
      "empty_layer": false
    },
    {
      "created": "2024-01-10T12:05:00Z",
      "created_by": "/bin/sh -c #(nop) CMD [\"nginx\"]",
      "empty_layer": true
    }
  ]
}
```

### 6. Хранение образов на диске

### Структура директорий Docker

```bash
/var/lib/docker/
├── image/
│   └── overlay2/
│       ├── distribution/        # Manifest данные
│       ├── imagedb/
│       │   └── content/
│       │       └── sha256/      # Image configurations
│       │           └── abc123...json
│       ├── layerdb/
│       │   └── sha256/          # Layer metadata
│       │       ├── def456.../
│       │       │   ├── cache-id # Ссылка на overlay2
│       │       │   ├── diff     # Layer diff ID
│       │       │   ├── size     # Размер слоя
│       │       │   └── parent   # Родительский слой
│       │       └── ...
│       └── repositories.json    # Теги образов
├── overlay2/                    # Actual layer data
│   ├── <cache-id>/
│   │   ├── diff/                # Файлы слоя
│   │   ├── link                 # Короткий ID
│   │   ├── lower                # Нижние слои
│   │   └── work/                # Рабочая директория
│   └── l/                       # Символические ссылки
└── containers/                  # Container data
```

### Пример осмотра слоёв

```bash
# Инспекция образа
docker image inspect nginx:alpine

# Просмотр истории слоёв
docker history nginx:alpine

IMAGE          CREATED        CREATED BY                                      SIZE
a6eb2a334a9f   2 weeks ago    CMD ["nginx" "-g" "daemon off;"]                0B
<missing>      2 weeks ago    STOPSIGNAL SIGQUIT                              0B
<missing>      2 weeks ago    EXPOSE map[80/tcp:{}]                           0B
<missing>      2 weeks ago    RUN /bin/sh -c apt-get install nginx # buil…   54.3MB
<missing>      2 weeks ago    RUN /bin/sh -c apt-get update # buildkit        42.1MB
<missing>      3 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      3 weeks ago    /bin/sh -c #(nop) ADD file:xyz in /             77.8MB

# Просмотр содержимого слоя
docker save nginx:alpine -o nginx.tar
tar -xf nginx.tar
ls -la
# manifest.json, config.json, <layer-hash>/layer.tar
```

### 7. Оптимизация размера образа

### Best Practices для слоёв

**1. Объединение RUN команд:**

```dockerfile
# Плохо - создаёт 3 слоя
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get clean

# Хорошо - создаёт 1 слой
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**2. Порядок инструкций (для cache):**

```dockerfile
# Оптимальный порядок
FROM node:18-alpine

# Редко меняющиеся слои - первыми
WORKDIR /app

# Зависимости раньше кода
COPY package*.json ./
RUN npm ci --production

# Код приложения - последним (меняется часто)
COPY . .

CMD ["node", "server.js"]
```

**3. Multi-stage builds:**

```dockerfile
# Stage 1: Build
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Production
FROM alpine:3.18
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]

# Итоговый образ содержит только бинарник
# Размер: ~10 MB вместо ~800 MB
```

**4. .dockerignore:**

```
# .dockerignore - не копировать в образ
node_modules/
.git/
*.log
.env
README.md
```

### Инструменты анализа

```bash
# Dive - анализ слоёв
dive nginx:alpine

# Docker slim - оптимизация образов
docker-slim build --target myapp:1.0

# Проверка размеров слоёв
docker history --no-trunc --human nginx:alpine
```

### 8. Distribution и Registry

### Загрузка и скачивание образов

**Pull процесс:**
```bash
docker pull nginx:alpine

# 1. Получение manifest от registry
# 2. Проверка локальных слоёв по digest
# 3. Загрузка недостающих слоёв
# 4. Верификация через SHA256
# 5. Сохранение в local storage
```

**Push процесс:**
```bash
docker push myregistry.com/myapp:1.0

# 1. Чтение локальных слоёв
# 2. Проверка существующих слоёв в registry
# 3. Загрузка новых слоёв
# 4. Создание и загрузка manifest
# 5. Создание tag в registry
```

### Image Tags и Digest

```bash
# Tag - человекочитаемое имя
nginx:1.24
nginx:1.24-alpine
nginx:latest

# Digest - неизменяемый идентификатор
nginx@sha256:abc123def456...

# Pull по digest (гарантия версии)
docker pull nginx@sha256:abc123def456...
```

### 9. Multi-platform образы

### Image Index (Manifest List)

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
  "manifests": [
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 1234,
      "digest": "sha256:amd64...",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 1234,
      "digest": "sha256:arm64...",
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    }
  ]
}
```

**Использование:**
```bash
# Docker автоматически выбирает правильную платформу
docker pull nginx:alpine
# На x86_64 - загружает amd64 образ
# На ARM Mac - загружает arm64 образ
# На Raspberry Pi - загружает arm/v7 образ

# Явное указание платформы
docker pull --platform linux/arm64 nginx:alpine
```

### 10. Open Container Initiative (OCI)

### OCI Image Specification

Docker образы совместимы с OCI спецификацией:

**Компоненты OCI образа:**
1. **Image Manifest** — описание слоёв
2. **Image Configuration** — метаданные запуска
3. **Filesystem Layers** — tar.gz архивы с файлами

**Совместимость:**
```bash
# Docker образы работают с:
- containerd
- CRI-O
- Podman
- Kubernetes (через containerd/CRI-O)
```

## Источники

- Docker Documentation: Image specification
- OCI Image Specification v1.0
- "Docker Deep Dive" by Nigel Poulton
- Docker Storage Drivers documentation
- "Container Security" by Liz Rice (chapter on images)
- Docker Registry HTTP API V2 specification
- OverlayFS kernel documentation
