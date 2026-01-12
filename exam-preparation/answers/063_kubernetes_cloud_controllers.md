# Какие контроллеры кластера Kubernetes зависят от облачных провайдеров. Опишите их.

## Краткий ответ
Контроллеры, зависящие от облачных провайдеров, входят в состав **cloud-controller-manager** и включают: **Node Controller** (управление информацией об узлах из облака), **Route Controller** (настройка сетевых маршрутов), **Service Controller** (управление облачными Load Balancers) и **Volume Controller** (управление облачными дисками, в новых версиях заменён на CSI). Эти контроллеры используют API облачных провайдеров для интеграции Kubernetes с инфраструктурой.

## Развёрнутый ответ

### Cloud Controller Manager

Cloud Controller Manager (CCM) — это компонент Kubernetes, отвечающий за интеграцию с API облачных провайдеров. Он отделяет cloud-specific логику от core компонентов Kubernetes, что позволяет:
- Разрабатывать cloud providers независимо от релизов Kubernetes
- Упростить поддержку различных облачных платформ
- Запускать Kubernetes как on-premise, так и в облаке

### Архитектура CCM

**Разделение ответственности:**
- **kube-controller-manager**: generic контроллеры (ReplicaSet, Deployment, etc.)
- **cloud-controller-manager**: cloud-specific контроллеры

**Режимы работы:**
- CCM опциональный для on-premise кластеров
- Обязательный для managed Kubernetes в облаках (EKS, GKE, AKS)

### 1. Node Controller

**Назначение:**
Node Controller отвечает за управление жизненным циклом узлов и синхронизацию информации между Kubernetes и облачной инфраструктурой.

**Основные функции:**

**Инициализация узлов:**
- Получение информации об узле от облачного провайдера при его появлении
- Установка labels с метаданными облака
- Обогащение объекта Node информацией об инфраструктуре

**Метаданные из облака:**
```yaml
apiVersion: v1
kind: Node
metadata:
  name: node-1
  labels:
    beta.kubernetes.io/instance-type: t3.medium
    topology.kubernetes.io/region: us-east-1
    topology.kubernetes.io/zone: us-east-1a
    node.kubernetes.io/instance-type: t3.medium
spec:
  providerID: aws:///us-east-1a/i-0123456789abcdef0
```

**Проверка существования узла:**
- Периодическая проверка, что VM существует в облаке
- Определение, был ли узел удалён в облачном провайдере
- Удаление Node объекта из Kubernetes, если VM больше не существует

**Обновление статуса узла:**
- Добавление информации об IP-адресах (внутренний и внешний)
- Информация о типе инстанса
- Регион и availability zone
- Hostname

**Примеры для разных облаков:**

*AWS:*
```yaml
providerID: aws:///us-east-1a/i-0123456789abcdef0
labels:
  failure-domain.beta.kubernetes.io/region: us-east-1
  failure-domain.beta.kubernetes.io/zone: us-east-1a
  beta.kubernetes.io/instance-type: m5.large
```

*GCP:*
```yaml
providerID: gce://my-project/us-central1-a/my-instance
labels:
  cloud.google.com/gke-nodepool: default-pool
  topology.kubernetes.io/region: us-central1
  topology.kubernetes.io/zone: us-central1-a
```

*Azure:*
```yaml
providerID: azure:///subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/my-vm
labels:
  kubernetes.azure.com/cluster: my-cluster
  topology.kubernetes.io/region: eastus
  topology.kubernetes.io/zone: eastus-1
```

**Обработка сбоев:**
- Если VM удалена в облаке, но Node существует в Kubernetes
- Контроллер помечает узел как NotReady
- После timeout удаляет Node из кластера
- Pod с этого узла переносятся на другие узлы

### 2. Route Controller

**Назначение:**
Route Controller настраивает маршруты в облачной сети для обеспечения связности между Pod на разных узлах.

**Основные функции:**

**Конфигурация сетевых маршрутов:**
- Создание правил маршрутизации в облачной VPC/VNet
- Обеспечение, что Pod на разных узлах могут взаимодействовать
- Маршрутизация Pod IP-адресов через соответствующие узлы

**Принцип работы:**

1. Kubernetes назначает каждому узлу Pod CIDR (например, 10.244.0.0/24)
2. Route Controller создаёт маршруты в облачной сети:
   - 10.244.0.0/24 → node-1 (10.0.1.10)
   - 10.244.1.0/24 → node-2 (10.0.1.11)
   - 10.244.2.0/24 → node-3 (10.0.1.12)

**Примеры для разных облаков:**

**AWS:**
- Использует Route Tables в VPC
- Создаёт правила маршрутизации для каждого Pod CIDR
- Destination: Pod CIDR, Target: ENI узла

```
Destination         Target
10.244.0.0/24      eni-0123456789abcdef0  (node-1)
10.244.1.0/24      eni-0123456789abcdef1  (node-2)
10.244.2.0/24      eni-0123456789abcdef2  (node-3)
```

**GCP:**
- Использует Routes в VPC
- Автоматическое создание маршрутов при добавлении узлов
- Использует alias IP ranges для Pod

```
Name              Destination     Next Hop
node-1-pod-cidr   10.244.0.0/24   node-1 (10.0.1.10)
node-2-pod-cidr   10.244.1.0/24   node-2 (10.0.1.11)
```

**Azure:**
- Использует User-Defined Routes (UDR) в Azure VNet
- Создаёт маршруты в Route Table

**Важные аспекты:**

*Ограничения:*
- Количество маршрутов в облаке может быть ограничено
- AWS VPC: до 50-100 маршрутов на Route Table
- GCP: до 250 маршрутов на VPC
- Для больших кластеров может потребоваться альтернативная сетевая модель

*Альтернативы:*
- CNI plugins (Calico, Cilium, Weave) часто не используют cloud routes
- Overlay networks (VXLAN, IPinIP)
- AWS VPC CNI использует ENI вместо маршрутов

**Синхронизация:**
- Route Controller отслеживает изменения узлов
- Добавляет маршруты для новых узлов
- Удаляет маршруты для удалённых узлов
- Обновляет маршруты при изменении Pod CIDR

### 3. Service Controller

**Назначение:**
Service Controller управляет облачными Load Balancers для Kubernetes Services типа LoadBalancer.

**Основные функции:**

**Создание Load Balancer:**
Когда создаётся Service типа LoadBalancer:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

Service Controller:
1. Вызывает API облачного провайдера для создания Load Balancer
2. Конфигурирует балансировщик для перенаправления трафика на узлы
3. Получает внешний IP-адрес
4. Обновляет Service с IP-адресом балансировщика

**Конфигурация балансировщика:**
- Backend pool: узлы кластера на NodePort
- Health checks: проверки доступности узлов
- Forwarding rules: правила перенаправления трафика

**Примеры для разных облаков:**

**AWS (ELB/ALB/NLB):**

*Classic Load Balancer (устаревший):*
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "classic"
```

*Network Load Balancer:*
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"  # internal LB
```

*Application Load Balancer (через AWS Load Balancer Controller):*
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
```

Создаваемые ресурсы:
- ELB/NLB в AWS
- Target Group с узлами кластера
- Security Group для балансировщика
- Health checks на NodePort

**GCP (Cloud Load Balancing):**

*External Load Balancer:*
```yaml
metadata:
  annotations:
    cloud.google.com/load-balancer-type: "External"
```

*Internal Load Balancer:*
```yaml
metadata:
  annotations:
    cloud.google.com/load-balancer-type: "Internal"
```

Создаваемые ресурсы:
- Forwarding Rule (внешний IP)
- Backend Service (группа узлов)
- Health Check
- Firewall Rules

**Azure (Azure Load Balancer):**

*Public Load Balancer:*
```yaml
spec:
  type: LoadBalancer
```

*Internal Load Balancer:*
```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

Создаваемые ресурсы:
- Azure Load Balancer
- Frontend IP Configuration
- Backend Address Pool
- Load Balancing Rules
- Health Probes

**Управление жизненным циклом:**

*Создание:*
- Асинхронное создание балансировщика
- Service получает статус Pending
- После создания статус меняется на Active с внешним IP

*Обновление:*
- Изменение портов → обновление правил балансировщика
- Изменение селектора → обновление backend pool
- Добавление/удаление узлов → обновление targets

*Удаление:*
- При удалении Service автоматически удаляется Load Balancer
- Освобождение внешнего IP (если не зарезервирован)

**Дополнительные возможности:**

*Session Affinity:*
```yaml
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

*Preserving Source IP:*
```yaml
spec:
  externalTrafficPolicy: Local  # сохраняет source IP клиента
```

*Load Balancer Source Ranges:*
```yaml
spec:
  loadBalancerSourceRanges:
  - 10.0.0.0/8
  - 192.168.0.0/16
```

### 4. Volume Controller (Legacy)

**Назначение:**
Volume Controller управлял облачными persistent volumes (в старых версиях Kubernetes). В современных версиях заменён на CSI (Container Storage Interface).

**Функции (в legacy версиях):**

**Attach/Detach операции:**
- Подключение облачного диска к узлу при запуске Pod
- Отключение диска при удалении Pod
- Перемещение диска между узлами при rescheduling

**Примеры для разных облаков:**

**AWS EBS:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-ebs-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef0
    fsType: ext4
```

Операции:
- AttachVolume: подключение EBS к EC2 инстансу
- DetachVolume: отключение EBS от инстанса
- Управление через AWS API

**GCP Persistent Disk:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-gce-pd
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  gcePersistentDisk:
    pdName: my-disk
    fsType: ext4
```

**Azure Disk:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-azure-disk
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  azureDisk:
    diskName: my-disk
    diskURI: /subscriptions/.../disks/my-disk
```

**Миграция на CSI:**

В современных версиях Kubernetes (1.23+):
- In-tree volume plugins deprecated
- CSI (Container Storage Interface) стал стандартом
- Cloud providers предоставляют CSI drivers:
  - AWS EBS CSI Driver
  - GCP PD CSI Driver
  - Azure Disk CSI Driver

**Преимущества CSI:**
- Независимость от Kubernetes release cycle
- Более гибкая архитектура
- Поддержка дополнительных возможностей (snapshots, expansion)
- Единый интерфейс для всех storage providers

### Развёртывание Cloud Controller Manager

**Запуск в кластере:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloud-controller-manager
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: cloud-controller-manager
  template:
    metadata:
      labels:
        k8s-app: cloud-controller-manager
    spec:
      hostNetwork: true
      containers:
      - name: cloud-controller-manager
        image: registry.k8s.io/cloud-controller-manager:v1.28.0
        command:
        - /usr/local/bin/cloud-controller-manager
        - --cloud-provider=aws  # или gcp, azure, etc.
        - --leader-elect=true
```

**Конфигурация:**
- Указание облачного провайдера
- Credentials для доступа к API облака
- Leader election для высокой доступности
- Настройки контроллеров (можно отключать ненужные)

## Источники
- Официальная документация Kubernetes: Cloud Controller Manager (kubernetes.io/docs/concepts/architecture/cloud-controller/)
- AWS Load Balancer Controller Documentation
- GKE Networking Documentation
- Azure Kubernetes Service Documentation
- Kubernetes Cloud Provider Interface
