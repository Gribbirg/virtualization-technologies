# Что такое среда выполнения контейнера. Назовите и опишите среды выполнения контейнеров, которые поддерживает Kubernetes

## Краткий ответ
Среда выполнения контейнера (Container Runtime) — это ПО, отвечающее за запуск контейнеров на узле. Kubernetes поддерживает runtime через интерфейс CRI (Container Runtime Interface). Основные поддерживаемые runtime: **containerd** (промышленный стандарт, легковесный), **CRI-O** (оптимизированный для Kubernetes), **Docker Engine** через cri-dockerd (deprecated). Все runtime должны реализовывать CRI спецификацию для взаимодействия с kubelet.

## Развёрнутый ответ

### Что такое Container Runtime

**Определение:**
Container Runtime (среда выполнения контейнера) — это низкоуровневое программное обеспечение, которое непосредственно отвечает за запуск и управление контейнерами на хосте.

**Основные задачи Container Runtime:**
- Загрузка образов контейнеров из реестров (registry)
- Распаковка образов в файловую систему
- Создание изолированных окружений (namespaces, cgroups)
- Запуск процессов внутри контейнеров
- Мониторинг состояния контейнеров
- Остановка и удаление контейнеров
- Управление жизненным циклом контейнеров

### Container Runtime Interface (CRI)

**Назначение:**
CRI — это стандартный интерфейс, определяющий взаимодействие между kubelet и container runtime.

**История:**
- До Kubernetes 1.5: жёсткая интеграция с Docker
- Kubernetes 1.5: введение CRI для поддержки разных runtime
- Kubernetes 1.20: deprecation dockershim
- Kubernetes 1.24: удаление встроенной поддержки Docker

**Архитектура CRI:**

```
kubelet
    ↓ (gRPC calls)
CRI Plugin (containerd, CRI-O, etc.)
    ↓
Low-level runtime (runc, kata-runtime, etc.)
    ↓
Linux kernel (namespaces, cgroups)
```

**CRI API состоит из двух сервисов:**

**1. RuntimeService:**
Управление контейнерами и Pod:
- RunPodSandbox: создание sandbox (изолированное окружение для Pod)
- StopPodSandbox: остановка sandbox
- RemovePodSandbox: удаление sandbox
- PodSandboxStatus: получение статуса
- CreateContainer: создание контейнера
- StartContainer: запуск контейнера
- StopContainer: остановка контейнера
- RemoveContainer: удаление контейнера
- ListContainers: список контейнеров
- ContainerStatus: статус контейнера
- ExecSync/Exec: выполнение команд в контейнере
- Attach: подключение к контейнеру

**2. ImageService:**
Управление образами:
- ListImages: список образов
- ImageStatus: информация об образе
- PullImage: загрузка образа
- RemoveImage: удаление образа

**Pod Sandbox:**
- Изолированное окружение для группы контейнеров в Pod
- Создаётся перед запуском контейнеров Pod
- Обеспечивает общую сеть и IPC namespace
- Обычно реализуется через pause container

### Уровни Container Runtime

**High-level runtime:**
- Реализуют CRI
- Управление образами
- Интеграция с CNI для сетей
- Примеры: containerd, CRI-O

**Low-level runtime:**
- Непосредственный запуск контейнеров
- Взаимодействие с ядром Linux
- OCI (Open Container Initiative) совместимые
- Примеры: runc, kata-runtime, gVisor

### Поддерживаемые Container Runtime

#### 1. containerd

**Описание:**
containerd — это промышленный стандарт container runtime, разработанный как core container runtime для Docker.

**Ключевые характеристики:**

*Архитектура:*
- Daemon на узле
- gRPC API
- CRI plugin для Kubernetes
- Использует runc как low-level runtime

*Компоненты:*
```
containerd
├── CRI Plugin (для Kubernetes)
├── Snapshotter (управление файловой системой)
├── Content Store (хранение blobs)
├── Metadata Store (метаданные)
└── Runtime (runc/kata/gVisor)
```

*Преимущества:*
- Легковесный (меньше накладных расходов чем Docker)
- Высокая производительность
- CNCF graduated project
- Активное развитие и поддержка
- Используется по умолчанию в большинстве дистрибутивов Kubernetes
- Модульная архитектура

*Функциональность:*
- Управление полным жизненным циклом контейнеров
- Передача образов и хранение
- Выполнение контейнеров с runc
- Поддержка OCI образов и runtime спецификации
- Snapshots файловой системы (overlayfs, btrfs, zfs)

*Установка и настройка:*
```bash
# Установка containerd
apt-get install containerd

# Конфигурация
/etc/containerd/config.toml
```

```toml
# config.toml
version = 2
[plugins."io.containerd.grpc.v1.cri"]
  [plugins."io.containerd.grpc.v1.cri".containerd]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        SystemdCgroup = true
```

*CLI tools:*
- **ctr**: низкоуровневый CLI для containerd
- **crictl**: CLI для CRI-совместимых runtime
- **nerdctl**: Docker-compatible CLI для containerd

*Использование:*
```bash
# crictl для работы с контейнерами
crictl ps
crictl images
crictl logs <container-id>
crictl exec -it <container-id> /bin/sh

# ctr для низкоуровневых операций
ctr containers ls
ctr images ls
```

*Kubelet конфигурация:*
```yaml
# /var/lib/kubelet/config.yaml
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
```

**Экосистема containerd:**
- Docker использует containerd под капотом
- Поддержка различных low-level runtimes
- Интеграция с Kubernetes, Docker, Podman

#### 2. CRI-O

**Описание:**
CRI-O — это легковесная container runtime специально разработанная для Kubernetes. Реализует только CRI спецификацию, без дополнительного функционала.

**Ключевые характеристики:**

*Философия:*
- "Born from Kubernetes, for Kubernetes"
- Минималистичный подход
- Только то, что нужно для CRI
- Никаких лишних возможностей

*Архитектура:*
```
CRI-O
├── conmon (container monitor)
├── runc (low-level runtime)
├── Storage (containers/storage library)
└── Networking (CNI integration)
```

*Преимущества:*
- Оптимизирован для Kubernetes use cases
- Минимальные накладные расходы
- Соответствие OCI стандартам
- Безопасность (меньше attack surface)
- Активно используется в OpenShift

*Функциональность:*
- Поддержка OCI контейнеров и образов
- Интеграция с runc и других OCI-совместимых runtimes
- Загрузка образов из различных registries
- Управление сетью через CNI
- Управление хранилищем через containers/storage

*Компоненты:*

**conmon (container monitor):**
- Отслеживает контейнеры
- Собирает логи
- Обрабатывает TTY
- Обеспечивает connection между CRI-O и контейнером

**Storage:**
- Использует containers/storage library
- Поддержка overlay, devicemapper
- Copy-on-write файловые системы

*Установка и настройка:*
```bash
# Установка CRI-O
apt-get install cri-o

# Конфигурация
/etc/crio/crio.conf
```

```toml
# crio.conf
[crio]
  storage_driver = "overlay"

[crio.runtime]
  default_runtime = "runc"
  conmon = "/usr/bin/conmon"

[crio.network]
  network_dir = "/etc/cni/net.d/"
  plugin_dirs = ["/opt/cni/bin/"]
```

*CLI tool:*
```bash
# crictl для работы с CRI-O
crictl --runtime-endpoint unix:///var/run/crio/crio.sock ps
crictl images
```

*Kubelet конфигурация:*
```yaml
# /var/lib/kubelet/config.yaml
containerRuntimeEndpoint: unix:///var/run/crio/crio.sock
imageServiceEndpoint: unix:///var/run/crio/crio.sock
```

**Использование в production:**
- Red Hat OpenShift (по умолчанию)
- SUSE CaaS Platform
- Различные on-premise Kubernetes кластеры

#### 3. Docker Engine (Deprecated)

**Описание:**
Docker Engine — это популярная платформа контейнеризации, которая исторически была основным runtime для Kubernetes.

**Статус поддержки:**
- Kubernetes 1.20: dockershim deprecated
- Kubernetes 1.24: dockershim удалён из kubelet
- Текущая поддержка: через внешний cri-dockerd adapter

**Почему Docker deprecated:**
- Docker не реализует CRI напрямую
- Требовался dockershim (прослойка) в kubelet
- Дополнительные накладные расходы
- Усложнение поддержки и разработки kubelet

**Архитектура Docker:**
```
kubelet
    ↓
dockershim (или cri-dockerd)
    ↓
Docker Engine
    ↓
containerd
    ↓
runc
```

**cri-dockerd:**
- Внешний адаптер CRI для Docker
- Замена встроенного dockershim
- Поддерживается Mirantis и Docker
- Позволяет продолжать использовать Docker

*Установка cri-dockerd:*
```bash
# Установка cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
make
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd
```

*Kubelet конфигурация:*
```yaml
containerRuntimeEndpoint: unix:///var/run/cri-dockerd.sock
```

**Важно понимать:**
- Удаление поддержки Docker не влияет на Docker-образы
- OCI образы работают с любым runtime
- Образы, собранные Docker, работают в containerd/CRI-O
- Docker всё ещё полезен для разработки и сборки образов

### Альтернативные Low-level Runtimes

Помимо стандартного runc, существуют альтернативные low-level runtimes:

#### kata-runtime (Kata Containers)

**Описание:**
- Легковесные виртуальные машины как контейнеры
- Каждый контейнер в отдельной VM
- Усиленная изоляция

**Преимущества:**
- Лучшая безопасность и изоляция
- Совместимость с OCI
- Защита от escape атак

**Использование с containerd:**
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
```

#### gVisor

**Описание:**
- User-space kernel для контейнеров
- Runsc runtime
- Перехват syscalls

**Преимущества:**
- Дополнительная изоляция
- Меньше attack surface
- Sandbox для небезопасных workloads

**Использование с containerd:**
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
```

#### Firecracker

**Описание:**
- Микро-VM от AWS
- KVM-based virtualization
- Очень быстрый запуск

### Выбор Container Runtime

**Рекомендации:**

**containerd:**
- Лучший выбор для большинства случаев
- Используется по умолчанию в managed Kubernetes (GKE, EKS, AKS)
- Стабильный и производительный
- Широкая поддержка

**CRI-O:**
- Для чистых Kubernetes окружений
- Red Hat/OpenShift экосистема
- Минималистичный подход

**Docker (через cri-dockerd):**
- Если есть сильная зависимость от Docker
- Legacy системы
- Не рекомендуется для новых установок

**Критерии выбора:**
- Производительность
- Footprint (использование ресурсов)
- Экосистема и инструменты
- Поддержка и сообщество
- Специфические требования (безопасность, изоляция)

### Миграция между Runtime

**containerd ← Docker:**
```bash
# 1. Остановить kubelet
systemctl stop kubelet

# 2. Удалить контейнеры Docker (опционально)
docker ps -q | xargs docker stop
docker ps -aq | xargs docker rm

# 3. Установить containerd
apt-get install containerd

# 4. Настроить kubelet
# В /var/lib/kubelet/config.yaml:
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock

# 5. Запустить kubelet
systemctl start kubelet
```

**Важно:**
- Образы нужно заново загружать (не копируются автоматически)
- Pod будут перезапущены
- Требуется время простоя узла

## Источники
- Официальная документация Kubernetes: Container Runtimes (kubernetes.io/docs/setup/production-environment/container-runtimes/)
- containerd Documentation (containerd.io)
- CRI-O Documentation (cri-o.io)
- OCI Specifications (opencontainers.org)
- Kubernetes CRI Specification
