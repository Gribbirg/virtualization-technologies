# Опишите составные части архитектуры Docker

## Краткий ответ

Архитектура Docker состоит из клиент-серверных компонентов: Docker Client (CLI) для взаимодействия с пользователем, Docker Daemon (dockerd) — основной сервис, управляющий контейнерами и образами, containerd — среда выполнения контейнеров, runc — низкоуровневый runtime для запуска контейнеров, Docker Registry — хранилище образов (например, Docker Hub). Компоненты взаимодействуют через REST API, обеспечивая полный жизненный цикл контейнеров.

## Развёрнутый ответ

### Общая архитектура

Docker использует клиент-серверную архитектуру, где различные компоненты взаимодействуют между собой для управления контейнерами:

```
┌──────────────┐
│ Docker Client│ (docker CLI)
└──────┬───────┘
       │ REST API over Unix socket / TCP
       ↓
┌──────────────────────────────────────┐
│        Docker Daemon (dockerd)        │
│  ┌────────────────────────────────┐  │
│  │  API Server                    │  │
│  ├────────────────────────────────┤  │
│  │  Image Management              │  │
│  ├────────────────────────────────┤  │
│  │  Network Management            │  │
│  ├────────────────────────────────┤  │
│  │  Volume Management             │  │
│  └────────────┬───────────────────┘  │
└───────────────┼──────────────────────┘
                │ gRPC
                ↓
        ┌───────────────┐
        │  containerd   │ (high-level container runtime)
        └───────┬───────┘
                │
                ↓
            ┌───────┐
            │  runc │ (low-level container runtime)
            └───┬───┘
                │
                ↓
        ┌───────────────┐
        │  Container    │
        └───────────────┘

        ┌──────────────┐
        │Docker Registry│ (Docker Hub, private registry)
        └──────────────┘
```

### Основные компоненты

#### 1. Docker Client (docker)

**Назначение**: Интерфейс командной строки для взаимодействия пользователя с Docker.

**Функции**:
- Принимает команды от пользователя (docker run, docker build, docker pull и т.д.)
- Переводит команды в API-вызовы к Docker Daemon
- Отображает результаты выполнения команд
- Может взаимодействовать с удаленным Docker Daemon

**Взаимодействие**:
- Общается с Docker Daemon через REST API
- Использует Unix socket (`/var/run/docker.sock`) локально
- Может использовать TCP для удаленного подключения
- Поддерживает TLS для безопасного соединения

**Примеры команд**:
```bash
docker run nginx
docker build -t myapp:1.0 .
docker ps
docker images
```

#### 2. Docker Daemon (dockerd)

**Назначение**: Основной фоновый процесс, управляющий всеми Docker-объектами.

**Функции**:
- Прослушивает API-запросы от Docker Client
- Управляет жизненным циклом контейнеров
- Управляет образами (хранение, сборка, удаление)
- Управляет сетями Docker
- Управляет томами данных
- Взаимодействует с containerd для запуска контейнеров

**Подкомпоненты**:

**API Server**:
- Обрабатывает REST API запросы
- Аутентификация и авторизация
- Версионирование API
- Эндпоинты для всех Docker операций

**Image Manager**:
- Загрузка образов из registry
- Локальное хранение образов
- Управление слоями образов (layer cache)
- Построение образов из Dockerfile
- Тегирование и удаление образов

**Container Manager**:
- Создание контейнеров из образов
- Запуск, остановка, перезапуск контейнеров
- Управление жизненным циклом
- Мониторинг состояния контейнеров
- Управление ресурсами через cgroups

**Network Manager**:
- Создание и управление сетями
- Типы сетей: bridge, host, overlay, macvlan
- DNS для контейнеров
- Port mapping и forwarding
- Network policies

**Volume Manager**:
- Создание и управление томами
- Монтирование volumes в контейнеры
- Volume drivers для различных storage backends
- Backup и управление данными

**Конфигурация**:
- Конфигурационный файл: `/etc/docker/daemon.json`
- Настройки хранилища, сети, логирования
- Registry mirrors и insecure registries
- Resource constraints

#### 3. containerd

**Назначение**: Высокоуровневая среда выполнения контейнеров, управляющая их жизненным циклом.

**Функции**:
- Управление жизненным циклом контейнера
- Управление образами и snapshots
- Выполнение и мониторинг контейнеров
- Network namespace management
- Взаимодействие с низкоуровневыми runtimes (runc)

**Характеристики**:
- Выделен из Docker в отдельный проект CNCF
- Используется не только в Docker, но и в Kubernetes
- Модульная архитектура с плагинами
- gRPC API для взаимодействия
- Поддержка OCI-совместимых образов и runtimes

**Компоненты**:
- Content Store: хранение образов и слоев
- Snapshot Service: управление файловыми системами контейнеров
- Task Service: управление процессами контейнеров
- Metadata Store: метаданные о контейнерах и образах

#### 4. runc

**Назначение**: Низкоуровневая среда выполнения контейнеров, непосредственно создающая и запускающая контейнеры.

**Функции**:
- Создание контейнера согласно OCI спецификации
- Настройка namespaces (PID, Network, Mount, IPC, UTS, User)
- Настройка cgroups для ограничения ресурсов
- Настройка файловой системы контейнера
- Запуск процесса внутри контейнера
- Применение security profiles (SELinux, AppArmor, seccomp)

**Характеристики**:
- Реализация OCI Runtime Specification
- Написан на Go
- CLI инструмент для управления контейнерами
- Может использоваться независимо от Docker
- Основа для других runtimes

**Процесс создания контейнера**:
1. Получает OCI bundle (config.json + rootfs)
2. Создает namespaces
3. Настраивает cgroups
4. Монтирует файловую систему
5. Применяет security constraints
6. Выполняет процесс контейнера

#### 5. Docker Registry

**Назначение**: Хранилище Docker-образов для распространения.

**Типы**:

**Docker Hub** (hub.docker.com):
- Публичный registry от Docker Inc.
- Официальные образы (nginx, postgres, redis и т.д.)
- Пользовательские репозитории
- Automated builds
- Vulnerability scanning

**Private Registry**:
- Docker Registry (open-source)
- Self-hosted решение
- Контроль над образами
- Интеграция с корпоративной инфраструктурой

**Third-party Registries**:
- Amazon ECR (Elastic Container Registry)
- Google Container Registry (GCR)
- Azure Container Registry (ACR)
- GitLab Container Registry
- Harbor, Artifactory и другие

**Функции**:
- Хранение образов
- Контроль доступа (аутентификация, авторизация)
- Версионирование образов через теги
- API для push/pull операций
- Image signing и верификация
- Webhook notifications

#### 6. Дополнительные компоненты

**shim процесс**:
- Промежуточный процесс между containerd и runc
- Позволяет containerd быть независимым от жизни контейнера
- Перехватывает STDOUT/STDERR контейнера
- Отчитывается о статусе контейнера

**Docker Compose**:
- Инструмент для определения и запуска многоконтейнерных приложений
- YAML-файл для описания сервисов
- Управление зависимостями между контейнерами
- Сетевое взаимодействие между сервисами

**Docker Swarm**:
- Встроенная оркестрация кластера
- Управление множеством Docker hosts
- Service discovery и load balancing
- Rolling updates и rollback
- Secrets management

### Поток взаимодействия

#### Пример: docker run nginx

1. **Docker Client** получает команду `docker run nginx`
2. **Docker Client** отправляет REST API запрос к **Docker Daemon**
3. **Docker Daemon** проверяет наличие образа `nginx` локально
4. Если образа нет — **Docker Daemon** скачивает его из **Docker Registry**
5. **Docker Daemon** передает запрос на создание контейнера в **containerd** через gRPC
6. **containerd** подготавливает snapshot файловой системы из образа
7. **containerd** вызывает **runc** для создания контейнера
8. **runc** создает namespaces, настраивает cgroups, монтирует FS
9. **runc** запускает процесс nginx внутри контейнера
10. **shim** процесс следит за контейнером и отчитывается **containerd**
11. **containerd** сообщает **Docker Daemon** о статусе
12. **Docker Daemon** возвращает результат **Docker Client**
13. **Docker Client** отображает информацию пользователю

### Хранение данных

**Образы**:
- Хранятся в `/var/lib/docker/` (по умолчанию)
- Storage drivers: overlay2, aufs, btrfs, zfs, devicemapper
- Слоистая структура с copy-on-write

**Контейнеры**:
- Writable layer поверх read-only образа
- Метаданные контейнера
- Логи контейнера

**Volumes**:
- Персистентное хранилище данных
- Независимы от жизненного цикла контейнера
- Могут быть shared между контейнерами

### Сетевая архитектура

**Network drivers**:
- **bridge**: default, виртуальный мост на хосте
- **host**: контейнер использует сеть хоста напрямую
- **overlay**: для multi-host networking (Swarm)
- **macvlan**: присвоение MAC-адреса контейнеру
- **none**: отключение сети

**Компоненты**:
- Docker proxy (docker-proxy): port forwarding
- iptables rules: NAT и filtering
- Virtual Ethernet pairs (veth): связь контейнер-хост

### Безопасность

**Механизмы**:
- Namespaces для изоляции
- Cgroups для ограничения ресурсов
- Capabilities: тонкая настройка привилегий
- SELinux/AppArmor: mandatory access control
- Seccomp: фильтрация системных вызовов
- User namespaces: rootless containers

**Docker Content Trust**:
- Подпись образов
- Верификация publisher'а
- Защита от tampering

## Источники

- Docker Documentation: Architecture Overview
- Docker Engine API Reference
- containerd Documentation
- Open Container Initiative Specifications
- Docker Deep Dive by Nigel Poulton
- Docker Under the Hood (Docker Blog)
