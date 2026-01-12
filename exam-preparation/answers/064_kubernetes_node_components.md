# Опишите компоненты узла Kubernetes

## Краткий ответ
Компоненты узла (Node) Kubernetes включают: **kubelet** (агент, управляющий Pod на узле), **kube-proxy** (сетевой прокси для реализации Service), **Container Runtime** (ПО для запуска контейнеров, например containerd или CRI-O) и опциональные компоненты, такие как **CNI plugin** (сетевой плагин) и системные Pod (DNS, мониторинг). Эти компоненты работают на каждом рабочем узле и обеспечивают выполнение контейнеризированных приложений.

## Развёрнутый ответ

### Архитектура узла Kubernetes

Узел (Node) — это рабочая машина в Kubernetes (физическая или виртуальная), на которой запускаются контейнеризированные приложения. Каждый узел управляется Control Plane и содержит необходимые службы для запуска Pod.

### Основные компоненты узла

#### 1. kubelet

**Роль и назначение:**
kubelet — это основной агент узла, который регистрирует узел в кластере и обеспечивает выполнение контейнеров в Pod.

**Основные функции:**

**Регистрация узла:**
- Самостоятельная регистрация в API server при запуске
- Отправка информации об узле (CPU, память, ОС, архитектура)
- Периодическое обновление статуса узла

**Управление Pod:**
- Получение PodSpecs от API server через watch механизм
- Обеспечение запуска контейнеров согласно спецификации
- Отслеживание состояния Pod и контейнеров
- Перезапуск контейнеров при сбоях

**Взаимодействие с Container Runtime:**
- Использует CRI (Container Runtime Interface)
- Отправляет команды запуска/остановки контейнеров
- Получает информацию о состоянии контейнеров
- Управляет образами контейнеров (pull, list, remove)

**Проверки работоспособности:**

*Liveness Probe:*
- Определяет, "жив" ли контейнер
- При провале перезапускает контейнер
- Типы проверок: HTTP GET, TCP Socket, Exec команда

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

*Readiness Probe:*
- Определяет, готов ли контейнер принимать трафик
- При провале исключает Pod из Service endpoints
- Не перезапускает контейнер

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

*Startup Probe:*
- Для медленно стартующих приложений
- Блокирует другие проверки до успешного старта
- Предотвращает преждевременный перезапуск

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**Управление volumes:**
- Монтирование volumes в контейнеры
- Работа с различными типами volumes (emptyDir, hostPath, PV)
- Очистка volumes при удалении Pod

**Отчётность:**
- Отправка статусов Pod в API server
- Отправка событий (Events) о действиях на узле
- Обновление метрик использования ресурсов

**Статический Pod:**
kubelet может запускать статические Pod из манифестов в директории:
```bash
/etc/kubernetes/manifests/
```
Используется для запуска компонентов Control Plane.

**Конфигурация kubelet:**
```yaml
# /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
clusterDomain: cluster.local
clusterDNS:
- 10.96.0.10
podCIDR: 10.244.0.0/24
resolvConf: /etc/resolv.conf
rotateCertificates: true
serverTLSBootstrap: true
```

**Garbage Collection:**
- Удаление неиспользуемых образов
- Удаление завершённых контейнеров
- Управление дисковым пространством

**Eviction (выселение Pod):**
При нехватке ресурсов на узле kubelet может выселять Pod:
- Мониторинг использования памяти, диска, inodes
- Thresholds для eviction (hard и soft)
- Приоритизация Pod по QoS классу

```yaml
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
  imagefs.available: "15%"
```

#### 2. kube-proxy

**Роль и назначение:**
kube-proxy — это сетевой прокси, работающий на каждом узле, который реализует часть концепции Kubernetes Service.

**Основные функции:**

**Реализация Service:**
- Обеспечивает доступ к Service внутри кластера
- Балансирует нагрузку между backend Pod
- Поддерживает сетевые правила на узлах

**Режимы работы:**

**1. iptables mode (по умолчанию):**

*Принцип работы:*
- Использует правила iptables для маршрутизации пакетов
- Создаёт цепочки правил для каждого Service
- Выбирает backend Pod случайным образом

*Преимущества:*
- Низкие накладные расходы
- Работает в kernel space
- Надёжный и проверенный временем

*Недостатки:*
- Линейное время обработки при большом количестве Service
- Отсутствие продвинутой балансировки

*Пример правил iptables:*
```bash
# Chain для Service
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m tcp --dport 443 -j KUBE-SVC-XXX

# Chain для выбора Pod
-A KUBE-SVC-XXX -m statistic --mode random --probability 0.33 -j KUBE-SEP-POD1
-A KUBE-SVC-XXX -m statistic --mode random --probability 0.50 -j KUBE-SEP-POD2
-A KUBE-SVC-XXX -j KUBE-SEP-POD3

# DNAT к конкретному Pod
-A KUBE-SEP-POD1 -p tcp -m tcp -j DNAT --to-destination 10.244.1.5:8080
```

**2. IPVS mode:**

*Принцип работы:*
- Использует Linux IPVS (IP Virtual Server)
- Балансировщик нагрузки в kernel space
- Оптимизирован для больших кластеров

*Преимущества:*
- Лучшая производительность при большом количестве Service
- Константное время обработки (O(1))
- Больше алгоритмов балансировки

*Алгоритмы балансировки:*
- **rr** (round-robin): циклический перебор
- **lc** (least connection): минимум соединений
- **dh** (destination hashing): по IP назначения
- **sh** (source hashing): по IP источника
- **sed** (shortest expected delay): минимальная задержка
- **nq** (never queue): без очереди

*Включение IPVS mode:*
```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  scheduler: "rr"
```

**3. userspace mode (устаревший):**
- kube-proxy работает как прокси в userspace
- Высокие накладные расходы
- Не рекомендуется к использованию

**SessionAffinity:**
kube-proxy поддерживает session affinity (sticky sessions):
```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

**externalTrafficPolicy:**
```yaml
spec:
  externalTrafficPolicy: Local  # только на локальные Pod узла
```
- **Cluster** (по умолчанию): распределение по всем Pod
- **Local**: только на Pod текущего узла (сохраняет source IP)

**NodePort реализация:**
kube-proxy открывает порт на всех узлах для NodePort Service:
```yaml
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 30080
```

#### 3. Container Runtime

**Роль и назначение:**
Container Runtime — это ПО, ответственное за запуск контейнеров.

**Container Runtime Interface (CRI):**
- Стандартный интерфейс между kubelet и container runtime
- Определяет gRPC API для управления контейнерами и образами
- Позволяет использовать разные runtime без изменения kubelet

**Поддерживаемые runtime:**

**containerd:**
- Промышленный стандарт
- Высокая производительность
- Легковесный daemon
- CNCF graduated project
- Используется по умолчанию в большинстве дистрибутивов

**CRI-O:**
- Легковесный runtime специально для Kubernetes
- Реализует только CRI, без дополнительного функционала
- Оптимизирован для Kubernetes use cases
- Используется в OpenShift

**Docker Engine (deprecated):**
- Через cri-dockerd adapter
- Support deprecated в Kubernetes 1.20
- Удалён в 1.24+

**Функции Container Runtime:**
- Загрузка образов контейнеров
- Создание и запуск контейнеров
- Остановка и удаление контейнеров
- Мониторинг состояния контейнеров
- Управление сетью контейнеров (через CNI)
- Управление хранилищем контейнеров

### Дополнительные компоненты узла

#### CNI Plugin (Container Network Interface)

**Назначение:**
Обеспечивает сетевую связность между Pod.

**Функции:**
- Назначение IP-адресов Pod
- Настройка сетевых интерфейсов
- Конфигурация маршрутизации
- Применение Network Policies

**Популярные CNI plugins:**

**Calico:**
- BGP routing или VXLAN overlay
- Поддержка Network Policies
- Масштабируемость

**Flannel:**
- Простой overlay network
- VXLAN backend
- Легко настраивается

**Cilium:**
- eBPF-based networking
- Advanced network policies
- Service mesh возможности

**Weave Net:**
- Overlay network
- Automatic mesh network
- DNS discovery

#### DNS (CoreDNS)

**Назначение:**
Кластерный DNS для Service Discovery.

**Функции:**
- Разрешение имён Service
- Создание DNS записей для Pod
- Прямые и обратные DNS запросы

**Запуск:**
CoreDNS обычно запускается как Deployment в kube-system namespace:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
```

**DNS имена:**
- Service: `<service-name>.<namespace>.svc.cluster.local`
- Pod: `<pod-ip>.<namespace>.pod.cluster.local`

#### Системные Pod

На узлах также могут работать системные Pod:

**Мониторинг:**
- node-exporter (Prometheus metrics)
- metrics-server agent

**Логирование:**
- fluentd/fluent-bit
- logstash

**Сетевые компоненты:**
- CNI daemon sets
- kube-proxy (если запускается как Pod)

**Storage:**
- CSI node plugins
- Volume provisioners

### Процесс запуска Pod на узле

**Последовательность действий:**

1. **Scheduler** назначает Pod на узел
2. **kubelet** получает PodSpec через watch от API server
3. **kubelet** вызывает **CRI** для создания sandbox (pause container)
4. **Container Runtime** создаёт сетевой namespace
5. **CNI plugin** настраивает сетевые интерфейсы и IP
6. **kubelet** вызывает **CRI** для запуска init containers (если есть)
7. **kubelet** вызывает **CRI** для запуска app containers
8. **Container Runtime** загружает образы (если нужно) и запускает контейнеры
9. **kubelet** начинает выполнять health checks
10. **kubelet** обновляет статус Pod в API server

### Взаимодействие компонентов

```
API Server
    ↓ (watch PodSpecs)
kubelet
    ↓ (CRI calls)
Container Runtime → CNI Plugin (сеть)
    ↓
Containers в Pod

kube-proxy ← (watch Services) ← API Server
    ↓
iptables/IPVS rules
```

### Мониторинг компонентов узла

**kubelet:**
- Метрики: /metrics endpoint
- Логи: journalctl -u kubelet
- Healthcheck: /healthz endpoint

**kube-proxy:**
- Метрики: /metrics endpoint
- Логи: journalctl -u kube-proxy или Pod logs
- iptables/IPVS rules для отладки

**Container Runtime:**
- containerd: метрики через metrics endpoint
- Логи: journalctl -u containerd
- crictl tool для отладки

## Источники
- Официальная документация Kubernetes: Node Components (kubernetes.io/docs/concepts/overview/components/)
- Kubernetes Networking: A Guide to Container Networking
- Container Runtime Interface (CRI) Specification
- The Illustrated Children's Guide to Kubernetes
