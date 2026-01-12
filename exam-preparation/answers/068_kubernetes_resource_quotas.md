# Опишите принцип работы квоты ресурсов Kubernetes

## Краткий ответ
Resource Quota в Kubernetes — это механизм ограничения потребления ресурсов в namespace. Квота устанавливает лимиты на: **compute ресурсы** (CPU, память), **storage** (PVC, storage requests), **количество объектов** (Pod, Service, ConfigMaps). При создании ресурса API server проверяет, не превышает ли он квоту. Если превышает — запрос отклоняется. ResourceQuota работает с Admission Controller и обновляется при каждом изменении ресурсов в namespace.

## Развёрнутый ответ

### Концепция Resource Quotas

**Определение:**
Resource Quota (квота ресурсов) — это объект Kubernetes, который ограничивает агрегированное потребление ресурсов в namespace.

**Назначение:**
- Предотвращение monopolization ресурсов кластера одним namespace или командой
- Обеспечение справедливого распределения ресурсов между командами
- Контроль затрат и планирование мощностей
- Защита от случайного или злонамеренного чрезмерного использования

**Область применения:**
- ResourceQuota действует на уровне namespace
- Невозможно установить квоту на весь кластер (только через сумму квот namespace)
- Не действует на kube-system и другие системные namespace (если специально не настроено)

### Типы ограничений

#### 1. Compute Resource Quotas

Ограничения на вычислительные ресурсы (CPU и память).

**Основные типы:**

**requests (запросы):**
- Гарантированные ресурсы для контейнеров
- Используются scheduler для размещения Pod
- Сумма всех requests в namespace не может превышать квоту

**limits (лимиты):**
- Максимальное потребление ресурсов контейнером
- Превышение лимита приводит к throttling (CPU) или OOMKill (память)
- Сумма всех limits в namespace не может превышать квоту

**Пример квоты compute ресурсов:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    requests.cpu: "10"           # Сумма всех CPU requests ≤ 10 cores
    requests.memory: "20Gi"       # Сумма всех memory requests ≤ 20Gi
    limits.cpu: "20"              # Сумма всех CPU limits ≤ 20 cores
    limits.memory: "40Gi"         # Сумма всех memory limits ≤ 40Gi
```

**Как это работает:**

1. Администратор создаёт ResourceQuota в namespace:
```bash
kubectl apply -f compute-quota.yaml -n development
```

2. При создании Pod, API server суммирует:
   - Все существующие requests.cpu в namespace
   - requests.cpu нового Pod
   - Проверяет: сумма ≤ квота?

3. Если сумма превышает квоту:
   - Pod не создаётся
   - Возвращается ошибка: `exceeded quota`

**Пример Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: development
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "500m"      # 0.5 CPU
        memory: "256Mi"
      limits:
        cpu: "1"         # 1 CPU
        memory: "512Mi"
```

**Проверка текущего использования:**
```bash
kubectl describe resourcequota compute-quota -n development
```

Вывод:
```
Name:            compute-quota
Namespace:       development
Resource         Used   Hard
--------         ----   ----
limits.cpu       15     20
limits.memory    30Gi   40Gi
requests.cpu     7.5    10
requests.memory  15Gi   20Gi
```

#### 2. Storage Resource Quotas

Ограничения на использование хранилища.

**Типы ограничений:**

**requests.storage:**
- Сумма всех storage requests в PersistentVolumeClaims
- Ограничивает общий размер запрашиваемого хранилища

**persistentvolumeclaims:**
- Количество PVC объектов в namespace
- Ограничивает число PVC независимо от размера

**Storage Classes:**
- Квоты для конкретных Storage Classes
- `<storage-class-name>.storageclass.storage.k8s.io/requests.storage`
- `<storage-class-name>.storageclass.storage.k8s.io/persistentvolumeclaims`

**Пример storage квоты:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-quota
  namespace: development
spec:
  hard:
    requests.storage: "100Gi"                           # Общий размер storage
    persistentvolumeclaims: "10"                        # Количество PVC
    fast-ssd.storageclass.storage.k8s.io/requests.storage: "50Gi"  # Для конкретного Storage Class
    fast-ssd.storageclass.storage.k8s.io/persistentvolumeclaims: "5"
```

**Как это работает:**

1. Создание PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: development
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
```

2. API server проверяет:
   - `requests.storage`: текущее использование + 10Gi ≤ 100Gi?
   - `persistentvolumeclaims`: текущее количество + 1 ≤ 10?
   - `fast-ssd.../requests.storage`: текущее + 10Gi ≤ 50Gi?
   - `fast-ssd.../persistentvolumeclaims`: текущее + 1 ≤ 5?

3. Если любая проверка не прошла — PVC не создаётся

**Ephemeral storage:**
```yaml
spec:
  hard:
    requests.ephemeral-storage: "50Gi"
    limits.ephemeral-storage: "100Gi"
```

#### 3. Object Count Quotas

Ограничения на количество объектов Kubernetes.

**Типы объектов:**

**Основные ресурсы:**
- `pods`: общее количество Pod
- `services`: количество Service
- `configmaps`: количество ConfigMaps
- `secrets`: количество Secrets
- `persistentvolumeclaims`: количество PVC
- `replicationcontrollers`: количество ReplicationControllers

**Extended resources:**
- `count/deployments.apps`: количество Deployments
- `count/replicasets.apps`: количество ReplicaSets
- `count/statefulsets.apps`: количество StatefulSets
- `count/jobs.batch`: количество Jobs
- `count/cronjobs.batch`: количество CronJobs

**Services:**
- `services.loadbalancers`: количество LoadBalancer Service
- `services.nodeports`: количество NodePort Service

**Пример object count квоты:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
  namespace: development
spec:
  hard:
    pods: "50"                              # Максимум 50 Pod
    services: "10"                           # Максимум 10 Service
    configmaps: "20"                         # Максимум 20 ConfigMaps
    secrets: "30"                            # Максимум 30 Secrets
    persistentvolumeclaims: "10"             # Максимум 10 PVC
    replicationcontrollers: "5"
    count/deployments.apps: "10"             # Максимум 10 Deployments
    count/replicasets.apps: "20"
    count/statefulsets.apps: "5"
    count/jobs.batch: "20"
    count/cronjobs.batch: "5"
    services.loadbalancers: "2"              # Максимум 2 LoadBalancer
    services.nodeports: "5"                  # Максимум 5 NodePort
```

### Принцип работы ResourceQuota

#### Архитектура

**Компоненты:**

1. **ResourceQuota Controller**
   - Работает в kube-controller-manager
   - Отслеживает использование ресурсов
   - Обновляет статус ResourceQuota объектов

2. **Admission Controller (ResourceQuota)**
   - Проверяет запросы на создание/обновление ресурсов
   - Сравнивает с квотами
   - Отклоняет запросы, превышающие квоты

**Процесс обработки запроса:**

```
User/Controller → API Server → Authentication → Authorization → Admission Controllers
                                                                        ↓
                                                                ResourceQuota Admission Controller
                                                                        ↓
                                                        Проверка: используемые ресурсы + новые ≤ квота?
                                                                        ↓
                                                            ┌───────────┴──────────┐
                                                           Да                      Нет
                                                            ↓                       ↓
                                                    Разрешить создание        Отклонить запрос
                                                            ↓                       ↓
                                                    Записать в etcd        Вернуть ошибку
                                                            ↓
                                            ResourceQuota Controller обновляет статус
```

#### Алгоритм проверки

**Для compute ресурсов:**

1. Получить все Pod в namespace (из cache)
2. Суммировать requests/limits всех контейнеров
3. Добавить requests/limits нового Pod
4. Сравнить с hard limits в ResourceQuota
5. Если превышает — отклонить (HTTP 403 Forbidden)

**Для object count:**

1. Подсчитать текущее количество объектов типа X
2. Добавить 1 (новый объект)
3. Сравнить с квотой
4. Если превышает — отклонить

**Для storage:**

1. Суммировать requests.storage всех PVC
2. Добавить storage нового PVC
3. Сравнить с квотой
4. Проверить Storage Class specific квоту
5. Если превышает — отклонить

### Взаимодействие с LimitRange

**ResourceQuota vs LimitRange:**

**ResourceQuota:**
- Ограничивает **агрегированное** потребление в namespace
- "Сколько всего можно использовать"
- Применяется к сумме всех ресурсов

**LimitRange:**
- Ограничивает **отдельные** Pod/Container
- "Сколько может использовать один Pod"
- Устанавливает min/max/default для ресурсов

**Совместное использование:**

```yaml
# ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
---
# LimitRange
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: dev
spec:
  limits:
  - max:                    # Максимум на контейнер
      cpu: "2"
      memory: "4Gi"
    min:                    # Минимум на контейнер
      cpu: "100m"
      memory: "128Mi"
    default:                # По умолчанию limits
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:         # По умолчанию requests
      cpu: "200m"
      memory: "256Mi"
    type: Container
```

**Важность LimitRange с ResourceQuota:**

Если ResourceQuota установлена для requests/limits, но Pod не указывает ресурсы:
- **Без LimitRange**: Pod будет отклонён (невозможно посчитать квоту)
- **С LimitRange**: используются default значения из LimitRange

**Пример проблемы:**
```yaml
# ResourceQuota установлена
# LimitRange НЕ установлена

# Этот Pod будет отклонён
apiVersion: v1
kind: Pod
metadata:
  name: no-resources
spec:
  containers:
  - name: app
    image: nginx
    # resources НЕ указаны!
```

Ошибка:
```
Error: failed quota: compute-quota: must specify limits.cpu,limits.memory,requests.cpu,requests.memory
```

**Решение:**
1. Указать resources в Pod
2. Или создать LimitRange с defaults

### Scope и Priority Class

#### Quota Scopes

Позволяют применять квоты только к определённым Pod.

**Доступные scopes:**

- **Terminating**: Pod с `activeDeadlineSeconds` (Jobs, CronJobs)
- **NotTerminating**: Pod без `activeDeadlineSeconds`
- **BestEffort**: Pod без requests/limits
- **NotBestEffort**: Pod с requests или limits
- **PriorityClass**: Pod с определённым PriorityClass

**Пример с scope:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: besteffort-quota
  namespace: dev
spec:
  hard:
    pods: "5"  # Максимум 5 BestEffort Pod
  scopes:
  - BestEffort
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: notbesteffort-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    limits.cpu: "20"
  scopes:
  - NotBestEffort
```

#### PriorityClass Quota

Квоты для Pod с определённым приоритетом.

**Создание PriorityClass:**
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority class"
```

**Quota для PriorityClass:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: high-priority-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "40Gi"
    pods: "20"
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values:
      - high-priority
```

### Мониторинг и управление квотами

#### Просмотр квот

**Список квот:**
```bash
kubectl get resourcequotas -n development
kubectl get quota -n development  # короткая форма
```

**Детальная информация:**
```bash
kubectl describe resourcequota compute-quota -n development
```

Вывод:
```
Name:            compute-quota
Namespace:       development
Resource         Used   Hard
--------         ----   ----
limits.cpu       15     20     # 15 из 20 используется (75%)
limits.memory    30Gi   40Gi   # 30Gi из 40Gi (75%)
requests.cpu     7.5    10     # 7.5 из 10 (75%)
requests.memory  15Gi   20Gi   # 15Gi из 20Gi (75%)
```

**YAML формат:**
```bash
kubectl get resourcequota compute-quota -n development -o yaml
```

#### Обновление квот

```bash
# Редактирование существующей квоты
kubectl edit resourcequota compute-quota -n development

# Применение изменений из файла
kubectl apply -f updated-quota.yaml
```

**Удаление квоты:**
```bash
kubectl delete resourcequota compute-quota -n development
```

#### Troubleshooting

**Проблема: Pod не создаётся**

1. Проверить события:
```bash
kubectl get events -n development --sort-by='.lastTimestamp'
```

2. Искать ошибки типа:
```
Warning  FailedCreate  Error creating: pods "my-pod" is forbidden: exceeded quota: compute-quota
```

3. Проверить квоту:
```bash
kubectl describe quota -n development
```

4. Решения:
   - Увеличить квоту
   - Удалить неиспользуемые Pod
   - Уменьшить requests нового Pod

**Проблема: Pod без resources не создаётся**

Решение: создать LimitRange с defaults:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: development
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
```

### Best Practices

**1. Всегда используйте ResourceQuota в shared namespace:**
- Предотвращает случайное DDoS кластера
- Обеспечивает справедливость

**2. Используйте LimitRange вместе с ResourceQuota:**
- Устанавливает defaults для Pod без resources
- Предотвращает создание очень больших Pod

**3. Мониторьте использование квот:**
- Настройте алерты при приближении к лимиту (>80%)
- Регулярно пересматривайте квоты

**4. Документируйте квоты:**
- Объясните командам их квоты
- Предоставьте инструкции по запросу увеличения

**5. Используйте разные квоты для разных окружений:**
- Production: строгие квоты
- Development: более гибкие
- Testing: временные квоты

**6. Настройте RBAC для квот:**
- Только администраторы могут изменять квоты
- Пользователи могут только просматривать

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: quota-reader
rules:
- apiGroups: [""]
  resources: ["resourcequotas"]
  verbs: ["get", "list"]
```

### Примеры практического применения

**Multi-tenant кластер:**
```yaml
# Team A
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "50"
    requests.memory: "100Gi"
    persistentvolumeclaims: "20"
    services.loadbalancers: "3"
---
# Team B
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-b-quota
  namespace: team-b
spec:
  hard:
    requests.cpu: "30"
    requests.memory: "60Gi"
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
```

**Development vs Production:**
```yaml
# Development (более гибко)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: development
spec:
  hard:
    pods: "100"
    requests.cpu: "20"
    requests.memory: "40Gi"
---
# Production (строже)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    pods: "50"
    requests.cpu: "100"
    requests.memory: "200Gi"
    persistentvolumeclaims: "50"
```

## Источники
- Официальная документация Kubernetes: Resource Quotas (kubernetes.io/docs/concepts/policy/resource-quotas/)
- Kubernetes Best Practices, Brendan Burns
- Managing Kubernetes Resources, O'Reilly
- Kubernetes in Action, Marko Lukša
