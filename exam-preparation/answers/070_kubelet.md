# Что такое Kubelet?

## Краткий ответ
**kubelet** — это агент узла (node agent), работающий на каждом узле Kubernetes кластера. Основные функции: регистрация узла в кластере, получение PodSpecs от API server, обеспечение запуска контейнеров согласно спецификации через Container Runtime Interface (CRI), выполнение проверок работоспособности (liveness/readiness probes), отправка статусов Pod и узла в API server, управление volumes. kubelet — это главный компонент узла, отвечающий за выполнение workloads.

## Развёрнутый ответ

### Описание kubelet

**Определение:**
kubelet — это основной агент узла, который регистрирует узел в кластере и обеспечивает выполнение контейнеров в Pod на этом узле.

**Архитектурная роль:**
```
Control Plane (API Server)
        ↓ (PodSpecs)
    kubelet (на каждом узле)
        ↓ (CRI calls)
Container Runtime (containerd/CRI-O)
        ↓
    Контейнеры в Pod
```

**Ключевая особенность:**
- kubelet НЕ управляется Control Plane как Pod
- Это системный процесс (обычно systemd service)
- Работает напрямую на хосте узла

### Основные функции kubelet

#### 1. Регистрация узла

**Самостоятельная регистрация:**
Когда kubelet запускается на новом узле:

1. Собирает информацию о машине:
   - Hostname
   - CPU и память
   - ОС и версия ядра
   - Архитектура
   - Container runtime версия
   - Доступные ресурсы

2. Создаёт/обновляет Node объект в API server:
```yaml
apiVersion: v1
kind: Node
metadata:
  name: node-1
  labels:
    kubernetes.io/hostname: node-1
    kubernetes.io/os: linux
    kubernetes.io/arch: amd64
status:
  capacity:
    cpu: "4"
    memory: "8Gi"
    pods: "110"
  allocatable:
    cpu: "3800m"
    memory: "7.5Gi"
    pods: "110"
  conditions:
  - type: Ready
    status: "True"
  nodeInfo:
    kernelVersion: 5.15.0-generic
    osImage: Ubuntu 22.04
    containerRuntimeVersion: containerd://1.6.24
    kubeletVersion: v1.28.0
```

**Node Status обновления:**
kubelet периодически (по умолчанию каждые 10 секунд) отправляет heartbeat:
- Обновляет условия (conditions) узла
- Отправляет информацию о доступных ресурсах
- Сообщает о проблемах (DiskPressure, MemoryPressure, PIDPressure)

#### 2. Управление Pod

**Получение PodSpecs:**

kubelet получает информацию о Pod для запуска из нескольких источников:

**API Server (основной источник):**
- kubelet устанавливает watch на API server
- Получает Pod, назначенные на этот узел (`spec.nodeName == <node-name>`)
- Реагирует на изменения в реальном времени

**Статические Pod манифесты:**
- Читает YAML файлы из директории (по умолчанию `/etc/kubernetes/manifests/`)
- Автоматически создаёт Pod из найденных манифестов
- Используется для запуска Control Plane компонентов

**HTTP endpoint:**
- Может получать манифесты через HTTP (редко используется)

**Процесс запуска Pod:**

1. **Получение PodSpec** от API server
2. **Создание Pod Sandbox** (изолированное окружение):
   - Создание сетевого namespace
   - Вызов CNI плагина для настройки сети
   - Создание "pause" контейнера для удержания namespace

3. **Подготовка volumes**:
   - Монтирование PersistentVolumes
   - Создание emptyDir
   - Монтирование ConfigMaps и Secrets

4. **Загрузка образов** (если нужно):
   - Проверка локального наличия образа
   - Pull образа из registry при необходимости
   - Соблюдение ImagePullPolicy

5. **Запуск init контейнеров** (если указаны):
   - Последовательный запуск
   - Ожидание успешного завершения каждого

6. **Запуск app контейнеров**:
   - Создание контейнеров через CRI
   - Монтирование volumes в контейнеры
   - Применение resource limits

7. **Начало проверок работоспособности**

**Взаимодействие с Container Runtime:**

kubelet не запускает контейнеры напрямую, а делегирует это Container Runtime через CRI (Container Runtime Interface):

```
kubelet → CRI gRPC API → Container Runtime (containerd/CRI-O) → runc → Контейнер
```

**CRI операции:**
```go
// Примеры CRI вызовов
runtimeService.RunPodSandbox(config)
runtimeService.CreateContainer(podSandboxID, containerConfig, sandboxConfig)
runtimeService.StartContainer(containerID)
runtimeService.StopContainer(containerID)
runtimeService.RemoveContainer(containerID)
```

#### 3. Мониторинг и проверки работоспособности

**Health Checks:**

kubelet выполняет три типа проверок:

**1. Liveness Probe:**
- Определяет, "жив" ли контейнер
- При провале: kubelet перезапускает контейнер
- Используется для обнаружения deadlocks и зависаний

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
    httpHeaders:
    - name: Custom-Header
      value: Awesome
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1
```

**Типы проверок:**
- **HTTP GET**: отправка HTTP запроса
- **TCP Socket**: проверка открытия TCP соединения
- **Exec**: выполнение команды в контейнере

**2. Readiness Probe:**
- Определяет, готов ли контейнер принимать трафик
- При провале: Pod исключается из Service endpoints
- НЕ перезапускает контейнер

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

**3. Startup Probe:**
- Для медленно стартующих приложений
- Блокирует другие проверки до успешного старта
- Предотвращает преждевременные перезапуски

```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**Алгоритм проверок:**

```
Container Start → Startup Probe (если есть) → Success
                                                   ↓
                                        Liveness + Readiness
                                                   ↓
                                          Running State

Если Liveness fails → Restart контейнера
Если Readiness fails → Удалить из Service endpoints
```

**Мониторинг ресурсов:**

kubelet собирает метрики использования ресурсов:
- CPU utilization
- Memory usage
- Disk usage
- Network I/O

Эти метрики предоставляются через:
- `/metrics` endpoint (Prometheus format)
- `/stats/summary` endpoint (для metrics-server)
- cAdvisor (встроенный в kubelet)

#### 4. Eviction (Выселение Pod)

**Условия для eviction:**

kubelet отслеживает ресурсы узла и может "выселять" Pod при их нехватке:

**Hard Eviction Thresholds:**
- Немедленное выселение без grace period
- По умолчанию:
  - `memory.available < 100Mi`
  - `nodefs.available < 10%`
  - `imagefs.available < 15%`

**Soft Eviction Thresholds:**
- Выселение после grace period
- Настраиваемые значения и периоды

**Конфигурация:**
```yaml
# /var/lib/kubelet/config.yaml
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
  imagefs.available: "15%"
  nodefs.inodesFree: "5%"

evictionSoft:
  memory.available: "500Mi"
  nodefs.available: "15%"

evictionSoftGracePeriod:
  memory.available: "1m30s"
  nodefs.available: "2m"
```

**Порядок выселения:**

1. **BestEffort Pod** (без requests/limits) — первыми
2. **Burstable Pod** (requests < limits), превышающие requests — вторыми
3. **Burstable Pod**, в пределах requests — третьими
4. **Guaranteed Pod** (requests = limits) — последними

#### 5. Управление volumes

**Функции:**

**Монтирование:**
- Подготовка volume перед запуском контейнера
- Монтирование в правильный путь
- Применение прав доступа

**Типы volumes:**
- emptyDir: временное хранилище
- hostPath: монтирование директории хоста
- PersistentVolumeClaim: постоянное хранилище
- configMap: конфигурационные данные
- secret: чувствительные данные
- projected: комбинация нескольких источников

**Процесс:**
```
1. Создание директории на узле
2. Монтирование volume (через CSI или встроенный плагин)
3. Применение fsGroup и permissions
4. Монтирование в контейнеры Pod
5. Unmount и cleanup при удалении Pod
```

**CSI интеграция:**

Для современных storage решений kubelet взаимодействует с CSI drivers:
```
kubelet → CSI Node Plugin → Storage System
```

#### 6. Отчётность в API Server

**Обновление статусов:**

**Pod Status:**
kubelet непрерывно отправляет статусы Pod:
```yaml
status:
  phase: Running
  conditions:
  - type: PodScheduled
    status: "True"
  - type: Initialized
    status: "True"
  - type: ContainersReady
    status: "True"
  - type: Ready
    status: "True"
  containerStatuses:
  - name: nginx
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: "2024-01-13T10:00:00Z"
```

**Node Status:**
Периодическое обновление состояния узла:
```yaml
conditions:
- type: Ready
  status: "True"
  lastHeartbeatTime: "2024-01-13T10:05:00Z"
  lastTransitionTime: "2024-01-13T09:00:00Z"
  reason: KubeletReady
  message: kubelet is posting ready status
- type: MemoryPressure
  status: "False"
- type: DiskPressure
  status: "False"
- type: PIDPressure
  status: "False"
```

**События (Events):**
kubelet создаёт события для важных действий:
- Успешное создание Pod
- Провал загрузки образа
- Перезапуск контейнера
- Eviction Pod
- Ошибки монтирования volume

```bash
kubectl get events --field-selector involvedObject.kind=Pod
```

### Конфигурация kubelet

**Способы конфигурации:**

1. **Командная строка** (flags):
```bash
kubelet --kubeconfig=/var/lib/kubelet/kubeconfig \
        --pod-manifest-path=/etc/kubernetes/manifests \
        --container-runtime-endpoint=unix:///run/containerd/containerd.sock
```

2. **Конфигурационный файл** (рекомендуется):
```yaml
# /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration

# Аутентификация и авторизация
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt

authorization:
  mode: Webhook

# Cluster
clusterDomain: cluster.local
clusterDNS:
  - 10.96.0.10

# Container Runtime
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock

# Resource Management
kubeReserved:
  cpu: "500m"
  memory: "1Gi"
  ephemeral-storage: "1Gi"

systemReserved:
  cpu: "500m"
  memory: "1Gi"
  ephemeral-storage: "1Gi"

evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"

# Pod limits
maxPods: 110

# Health checks
nodeStatusUpdateFrequency: 10s
nodeStatusReportFrequency: 5m

# Logging
logging:
  verbosity: 2

# Feature Gates
featureGates:
  RotateKubeletServerCertificate: true

# TLS
tlsCertFile: /var/lib/kubelet/pki/kubelet.crt
tlsPrivateKeyFile: /var/lib/kubelet/pki/kubelet.key
rotateCertificates: true
serverTLSBootstrap: true
```

**Важные параметры:**

**Resource Reservation:**
- `kubeReserved`: ресурсы для kubelet и системных компонентов
- `systemReserved`: ресурсы для ОС
- `evictionHard/Soft`: пороги для eviction

**Limits:**
- `maxPods`: максимум Pod на узле (default: 110)
- `podsPerCore`: Pod на CPU core

**Directories:**
- `podManifestPath`: директория для статических Pod
- `volumePluginDir`: директория для volume плагинов

### Режимы работы

#### Обычный режим (API Server)

Стандартный режим работы в кластере:
- Получает Pod от API server
- Отправляет статусы в API server
- Требует kubeconfig

#### Standalone режим (Статические Pod)

Работа без подключения к API server:
- Читает манифесты из локальной директории
- Не регистрируется в кластере
- Используется для bootstrap Control Plane

**Пример статического Pod:**
```yaml
# /etc/kubernetes/manifests/static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    role: webserver
spec:
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80
```

kubelet автоматически создаст и будет управлять этим Pod.

### Взаимодействие с другими компонентами

**С API Server:**
```
kubelet ←→ API Server
  ↑           ↓
  |    Watch Pod specs
  |    Update statuses
  └─── Certificate rotation
```

**С Container Runtime:**
```
kubelet → CRI gRPC → containerd/CRI-O
```

**С CNI Plugin:**
```
kubelet → CNI Plugin → Сетевая настройка Pod
```

**С CSI Driver:**
```
kubelet → CSI Node Service → Volume operations
```

### Мониторинг kubelet

**Metrics endpoints:**

```bash
# Kubelet metrics (Prometheus format)
curl http://localhost:10250/metrics

# Resource usage summary
curl http://localhost:10250/stats/summary

# Health check
curl http://localhost:10248/healthz
```

**Логи:**
```bash
# Через journald
journalctl -u kubelet -f

# Последние записи
journalctl -u kubelet -n 100

# За период
journalctl -u kubelet --since "1 hour ago"
```

**Типичные проблемы:**

1. **Pod не запускаются:**
   - Проверить логи kubelet
   - Проверить образы и imagePullPolicy
   - Проверить ресурсы узла

2. **Pod постоянно перезапускаются:**
   - Проверить liveness probes
   - Проверить OOMKilled статус
   - Проверить логи приложения

3. **Узел NotReady:**
   - Проверить статус kubelet: `systemctl status kubelet`
   - Проверить сеть между узлом и API server
   - Проверить доступность Container Runtime

### Управление kubelet

**Systemd service:**
```bash
# Статус
systemctl status kubelet

# Запуск/остановка
systemctl start kubelet
systemctl stop kubelet
systemctl restart kubelet

# Enable/disable
systemctl enable kubelet
systemctl disable kubelet

# Reload конфигурации
systemctl daemon-reload
```

**Обновление:**
```bash
# Остановить kubelet
systemctl stop kubelet

# Обновить бинарный файл
apt-get update && apt-get install -y kubelet=1.28.0-00

# Запустить kubelet
systemctl start kubelet

# Проверить версию
kubelet --version
```

### Безопасность

**Аутентификация:**
- Client certificates
- Bootstrap tokens
- Service account tokens

**Авторизация:**
- Webhook mode (проверка через API server)
- AlwaysAllow (только для dev)

**TLS:**
- Сертификаты для kubelet API
- Автоматическая ротация сертификатов
- Mutual TLS с API server

**Node Authorization:**
- Ограничение прав узла
- Доступ только к своим ресурсам

## Источники
- Официальная документация Kubernetes: kubelet (kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- Kubernetes The Hard Way, Kelsey Hightower
- Kubernetes in Action, Marko Lukša
- Production Kubernetes, Josh Rosso
