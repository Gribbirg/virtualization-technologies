# Что такое Dockerfile? Из чего состоит? Приведите пример применения.

## Краткий ответ

Dockerfile — это текстовый файл с инструкциями для автоматизированной сборки Docker-образа. Состоит из последовательности команд (FROM, RUN, COPY, ADD, WORKDIR, ENV, EXPOSE, CMD, ENTRYPOINT и др.), каждая из которых создает новый слой образа. Dockerfile описывает базовый образ, установку зависимостей, копирование файлов, настройку окружения и команду запуска приложения, обеспечивая воспроизводимость и автоматизацию сборки.

## Развёрнутый ответ

### Определение

Dockerfile — это декларативный файл с инструкциями по построению Docker-образа. Он позволяет:
- Автоматизировать создание образов
- Версионировать инфраструктуру (Infrastructure as Code)
- Документировать процесс сборки приложения
- Обеспечивать воспроизводимость окружения
- Делиться конфигурацией с командой

### Структура Dockerfile

#### Базовая структура

```dockerfile
# Комментарий
INSTRUCTION arguments

# Пример
FROM ubuntu:20.04
RUN apt-get update
```

**Особенности**:
- Инструкции не чувствительны к регистру, но convention — UPPERCASE
- Комментарии начинаются с `#`
- Инструкции выполняются последовательно сверху вниз
- Каждая инструкция (кроме некоторых) создает новый слой

### Основные инструкции Dockerfile

#### 1. FROM — Базовый образ

**Назначение**: Задает базовый образ для последующих инструкций.

**Синтаксис**:
```dockerfile
FROM image[:tag] [AS name]
FROM scratch  # Пустой образ
```

**Примеры**:
```dockerfile
FROM ubuntu:20.04
FROM python:3.9-slim
FROM node:18-alpine AS builder
FROM scratch  # Для статических бинарей
```

**Особенности**:
- Должна быть первой инструкцией (после parser directives и ARG)
- Может использоваться несколько раз (multi-stage builds)
- `AS name` для именования стадии в multi-stage builds

#### 2. RUN — Выполнение команд

**Назначение**: Выполняет команды во время сборки образа.

**Синтаксис**:
```dockerfile
# Shell form
RUN command param1 param2

# Exec form (preferred)
RUN ["executable", "param1", "param2"]
```

**Примеры**:
```dockerfile
# Установка пакетов
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Создание директорий
RUN mkdir -p /app/data

# Exec form
RUN ["/bin/bash", "-c", "echo hello"]
```

**Best practices**:
- Объединяйте связанные команды через `&&`
- Очищайте кэши пакетных менеджеров
- Используйте `\` для читаемости длинных команд

#### 3. CMD — Команда по умолчанию

**Назначение**: Задает команду по умолчанию для запуска контейнера.

**Синтаксис**:
```dockerfile
# Exec form (preferred)
CMD ["executable", "param1", "param2"]

# Shell form
CMD command param1 param2

# Parameters to ENTRYPOINT
CMD ["param1", "param2"]
```

**Примеры**:
```dockerfile
CMD ["python", "app.py"]
CMD ["nginx", "-g", "daemon off;"]
CMD npm start
```

**Особенности**:
- Может быть только одна CMD (последняя используется)
- Может быть переопределена при `docker run`
- Если есть ENTRYPOINT, CMD служит аргументами по умолчанию

#### 4. ENTRYPOINT — Точка входа

**Назначение**: Настраивает контейнер как исполняемый файл.

**Синтаксис**:
```dockerfile
# Exec form (preferred)
ENTRYPOINT ["executable", "param1"]

# Shell form
ENTRYPOINT command param1
```

**Примеры**:
```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]  # Можно переопределить аргументы

ENTRYPOINT ["docker-entrypoint.sh"]
```

**Отличия от CMD**:
- ENTRYPOINT сложнее переопределить (нужен --entrypoint)
- CMD легко переопределяется аргументами docker run
- Вместе: ENTRYPOINT как исполняемый файл, CMD как аргументы по умолчанию

#### 5. COPY — Копирование файлов

**Назначение**: Копирует файлы/директории из контекста сборки в образ.

**Синтаксис**:
```dockerfile
COPY [--chown=user:group] <src>... <dest>
COPY [--chown=user:group] ["<src>",... "<dest>"]
```

**Примеры**:
```dockerfile
COPY app.py /app/
COPY requirements.txt /app/
COPY . /app
COPY --chown=appuser:appgroup files/ /app/
COPY ["file with spaces.txt", "/app/"]
```

**Wildcards**:
```dockerfile
COPY *.py /app/
COPY file?.txt /app/
```

#### 6. ADD — Расширенное копирование

**Назначение**: Как COPY, но с дополнительными возможностями.

**Синтаксис**:
```dockerfile
ADD [--chown=user:group] <src>... <dest>
```

**Примеры**:
```dockerfile
# Обычное копирование
ADD app.py /app/

# Автоматическая распаковка tar
ADD archive.tar.gz /app/

# Скачивание из URL
ADD https://example.com/file.zip /tmp/
```

**Отличия от COPY**:
- ADD распаковывает локальные tar/gz архивы
- ADD может скачивать файлы по URL
- Рекомендуется использовать COPY, если не нужны особые возможности ADD

#### 7. WORKDIR — Рабочая директория

**Назначение**: Устанавливает рабочую директорию для последующих инструкций.

**Синтаксис**:
```dockerfile
WORKDIR /path/to/directory
```

**Примеры**:
```dockerfile
WORKDIR /app
COPY . .
RUN npm install

# Относительные пути
WORKDIR /app
WORKDIR subdir  # Теперь /app/subdir
```

**Особенности**:
- Создает директорию, если не существует
- Можно использовать переменные: `WORKDIR $HOME/app`
- Влияет на CMD, ENTRYPOINT, RUN, COPY, ADD

#### 8. ENV — Переменные окружения

**Назначение**: Устанавливает переменные окружения.

**Синтаксис**:
```dockerfile
ENV <key>=<value> ...
ENV <key> <value>  # Устаревший синтаксис
```

**Примеры**:
```dockerfile
ENV NODE_ENV=production
ENV APP_HOME=/app PORT=8080

# Использование
WORKDIR $APP_HOME
EXPOSE $PORT
```

**Особенности**:
- Доступны во время сборки и в контейнере
- Можно переопределить при docker run: `-e KEY=value`
- Влияют на все последующие инструкции

#### 9. ARG — Аргументы сборки

**Назначение**: Определяет переменные для передачи во время сборки.

**Синтаксис**:
```dockerfile
ARG <name>[=<default value>]
```

**Примеры**:
```dockerfile
ARG VERSION=latest
ARG BUILD_DATE
ARG PYTHON_VERSION=3.9

FROM python:${PYTHON_VERSION}
RUN echo "Building version ${VERSION}"
```

**Использование**:
```bash
docker build --build-arg VERSION=1.0 --build-arg BUILD_DATE=$(date) .
```

**Отличия от ENV**:
- ARG доступен только во время сборки
- ENV доступен и при сборке, и в runtime
- ARG не сохраняется в финальном образе (безопаснее для секретов)

#### 10. EXPOSE — Документирование портов

**Назначение**: Документирует, какие порты слушает контейнер.

**Синтаксис**:
```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

**Примеры**:
```dockerfile
EXPOSE 80
EXPOSE 8080 8443
EXPOSE 80/tcp
EXPOSE 53/udp
```

**Особенности**:
- Не публикует порты автоматически
- Документация для пользователей образа
- Используется в `docker run -P` для автоматического mapping

#### 11. VOLUME — Точки монтирования

**Назначение**: Создает точку монтирования для external volumes.

**Синтаксис**:
```dockerfile
VOLUME ["/data"]
VOLUME /var/log /var/db
```

**Примеры**:
```dockerfile
VOLUME ["/app/data"]
VOLUME /var/lib/mysql
```

**Особенности**:
- Данные в volume переживают контейнер
- Volume создается автоматически при docker run
- Изменения в volume не попадают в образ при docker commit

#### 12. USER — Пользователь

**Назначение**: Устанавливает пользователя для выполнения команд.

**Синтаксис**:
```dockerfile
USER <user>[:<group>]
USER <UID>[:<GID>]
```

**Примеры**:
```dockerfile
RUN adduser -D appuser
USER appuser

USER 1000:1000
```

**Best practice**: Не запускайте приложения от root!

#### 13. LABEL — Метаданные

**Назначение**: Добавляет метаданные к образу.

**Синтаксис**:
```dockerfile
LABEL <key>=<value> <key>=<value> ...
```

**Примеры**:
```dockerfile
LABEL version="1.0"
LABEL description="My application"
LABEL maintainer="dev@example.com"
LABEL com.example.version="1.0" \
      com.example.release-date="2024-01-13"
```

#### 14. HEALTHCHECK — Проверка здоровья

**Назначение**: Определяет команду для проверки работоспособности.

**Синтаксис**:
```dockerfile
HEALTHCHECK [OPTIONS] CMD command
HEALTHCHECK NONE  # Отключить
```

**Примеры**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
```

**Опции**:
- `--interval=DURATION` (default: 30s)
- `--timeout=DURATION` (default: 30s)
- `--start-period=DURATION` (default: 0s)
- `--retries=N` (default: 3)

#### 15. ONBUILD — Триггеры

**Назначение**: Добавляет инструкции, выполняемые при использовании образа как базового.

**Синтаксис**:
```dockerfile
ONBUILD INSTRUCTION
```

**Примеры**:
```dockerfile
# В базовом образе
ONBUILD COPY . /app
ONBUILD RUN npm install

# При FROM этого образа, эти инструкции выполнятся автоматически
```

#### 16. STOPSIGNAL — Сигнал остановки

**Назначение**: Устанавливает сигнал для остановки контейнера.

**Синтаксис**:
```dockerfile
STOPSIGNAL signal
```

**Примеры**:
```dockerfile
STOPSIGNAL SIGTERM
STOPSIGNAL SIGKILL
```

#### 17. SHELL — Оболочка по умолчанию

**Назначение**: Переопределяет shell для RUN, CMD, ENTRYPOINT.

**Синтаксис**:
```dockerfile
SHELL ["executable", "parameters"]
```

**Примеры**:
```dockerfile
SHELL ["/bin/bash", "-c"]
SHELL ["powershell", "-command"]
```

### Примеры применения

#### Пример 1: Простое Python приложение

```dockerfile
# Используем официальный Python образ
FROM python:3.9-slim

# Метаданные
LABEL maintainer="dev@example.com"
LABEL version="1.0"

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файл зависимостей
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем код приложения
COPY . .

# Создаем пользователя без root привилегий
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Документируем порт
EXPOSE 5000

# Переменные окружения
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import requests; requests.get('http://localhost:5000/health')"

# Команда запуска
CMD ["python", "app.py"]
```

**Сборка и запуск**:
```bash
docker build -t myapp:1.0 .
docker run -d -p 5000:5000 myapp:1.0
```

#### Пример 2: Node.js приложение с multi-stage build

```dockerfile
# Стадия 1: Сборка
FROM node:18-alpine AS builder

WORKDIR /app

# Копируем package files
COPY package*.json ./

# Устанавливаем зависимости
RUN npm ci --only=production

# Копируем исходники
COPY . .

# Собираем приложение
RUN npm run build

# Стадия 2: Production
FROM node:18-alpine

WORKDIR /app

# Копируем зависимости из builder
COPY --from=builder /app/node_modules ./node_modules

# Копируем собранное приложение
COPY --from=builder /app/dist ./dist

# Создаем пользователя
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Меняем владельца файлов
RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

ENV NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "dist/server.js"]
```

**Преимущества multi-stage**:
- Финальный образ не содержит build tools
- Меньший размер (только production зависимости)
- Более безопасный (меньше attack surface)

#### Пример 3: Nginx с кастомной конфигурацией

```dockerfile
FROM nginx:1.21-alpine

# Копируем кастомную конфигурацию
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Копируем статические файлы
COPY --chown=nginx:nginx public/ /usr/share/nginx/html/

# Переменные окружения
ENV NGINX_PORT=80

# Expose port
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# nginx уже имеет правильный ENTRYPOINT, не нужно переопределять
```

#### Пример 4: Java Spring Boot приложение

```dockerfile
# Stage 1: Build
FROM maven:3.8-openjdk-17 AS builder

WORKDIR /app

# Копируем pom.xml для кэширования зависимостей
COPY pom.xml .
RUN mvn dependency:go-offline

# Копируем исходники и собираем
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Runtime
FROM openjdk:17-slim

WORKDIR /app

# Копируем JAR из builder stage
COPY --from=builder /app/target/*.jar app.jar

# Создаем пользователя
RUN useradd -r -u 1001 -g root appuser
USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -Xms256m"

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

#### Пример 5: С использованием ARG для гибкости

```dockerfile
# Аргументы сборки
ARG PYTHON_VERSION=3.9
ARG ALPINE_VERSION=3.18

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

# Build-time метаданные
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$VCS_REF

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

**Сборка с аргументами**:
```bash
docker build \
  --build-arg PYTHON_VERSION=3.10 \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg VERSION=1.0.0 \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  -t myapp:1.0.0 .
```

### Best Practices

#### 1. Используйте .dockerignore

```
# .dockerignore
node_modules/
npm-debug.log
.git/
.gitignore
*.md
.env
.DS_Store
```

#### 2. Минимизируйте слои

```dockerfile
# Плохо
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Хорошо
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

#### 3. Порядок для лучшего кэширования

```dockerfile
# Хорошо - зависимости кэшируются
COPY package.json .
RUN npm install
COPY . .

# Плохо - при изменении кода переустановка зависимостей
COPY . .
RUN npm install
```

#### 4. Используйте конкретные теги

```dockerfile
# Хорошо
FROM node:18.16.0-alpine

# Плохо
FROM node:latest
```

#### 5. Не храните секреты в образе

```dockerfile
# Плохо
ENV API_KEY=secret123

# Хорошо - передавайте при запуске
# docker run -e API_KEY=secret123 myapp
```

#### 6. Multi-stage для оптимизации размера

Используйте для отделения build dependencies от runtime.

## Источники

- Docker Documentation: Dockerfile Reference
- Docker Best Practices: Writing Dockerfiles
- Open Container Initiative Specifications
- Dockerfile Best Practices (Docker Official Blog)
- The Twelve-Factor App
- Docker for Developers by Richard Bullington-McGuire
