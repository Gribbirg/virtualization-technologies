# Опишите плоскость управления компонентами кластера Kubernetes

## Краткий ответ
Плоскость управления (Control Plane) Kubernetes состоит из компонентов, принимающих глобальные решения о кластере. Основные компоненты: **kube-apiserver** (единая точка входа для всех операций), **etcd** (хранилище состояния кластера), **kube-scheduler** (назначение Pod на узлы), **kube-controller-manager** (запуск контроллеров для поддержания желаемого состояния) и **cloud-controller-manager** (интеграция с облачными провайдерами). Все компоненты взаимодействуют через API server.

## Развёрнутый ответ

### Архитектура Control Plane

Control Plane (плоскость управления) — это "мозг" кластера Kubernetes, отвечающий за:
- Принятие решений о размещении workloads
- Обнаружение и реагирование на события кластера
- Поддержание желаемого состояния системы
- Предоставление API для взаимодействия с кластером

### Детальное описание компонентов

#### 1. kube-apiserver

**Роль и назначение:**
- Центральный компонент Control Plane
- Единственная точка входа для всех операций с кластером
- Frontend для etcd
- Предоставляет RESTful API

**Основные функции:**

*Аутентификация и авторизация:*
- Проверка подлинности пользователей и сервисных аккаунтов
- Авторизация запросов через RBAC, ABAC, Webhook
- Admission Controllers для валидации и модификации запросов

*Обработка запросов:*
```
Client Request → Authentication → Authorization → Admission Control → Validation → Persistence (etcd)
```

*API операции:*
- CREATE, READ, UPDATE, DELETE для всех ресурсов
- WATCH для отслеживания изменений в реальном времени
- LIST с фильтрацией и пагинацией

**Admission Controllers:**
- **Validating**: проверка корректности запросов
- **Mutating**: модификация запросов перед сохранением
- Примеры: NamespaceLifecycle, LimitRanger, ResourceQuota, PodSecurityPolicy

**Характеристики:**
- Stateless компонент (все состояние в etcd)
- Горизонтально масштабируемый
- Поддержка TLS для безопасной коммуникации
- Встроенная поддержка aggregation layer для расширения API

**Пример взаимодействия:**
```bash
# Все kubectl команды идут через API server
kubectl get pods → HTTP GET /api/v1/namespaces/default/pods
kubectl create -f pod.yaml → HTTP POST /api/v1/namespaces/default/pods
kubectl delete pod my-pod → HTTP DELETE /api/v1/namespaces/default/pods/my-pod
```

#### 2. etcd

**Роль и назначение:**
- Распределённое key-value хранилище
- Единственный источник правды (Single Source of Truth)
- Хранит всё состояние кластера

**Что хранится в etcd:**
- Конфигурация всех объектов Kubernetes (Pod, Service, Deployment и т.д.)
- Состояние всех ресурсов
- Метаданные кластера
- Secrets (в зашифрованном виде при настройке encryption at rest)
- ConfigMaps
- Network policies
- RBAC правила

**Архитектурные особенности:**

*Консенсус Raft:*
- Обеспечивает строгую консистентность
- Требует кворум (N/2 + 1) для работы
- Рекомендуется нечётное количество экземпляров (3, 5, 7)

*MVCC (Multi-Version Concurrency Control):*
- Каждое изменение создаёт новую версию
- Поддержка истории изменений
- Эффективная реализация watch

*Watch механизм:*
- Компоненты подписываются на изменения
- Получают уведомления в реальном времени
- Основа для реактивной архитектуры Kubernetes

**Операции:**
```bash
# Пример структуры данных в etcd
/registry/pods/default/my-pod
/registry/services/default/my-service
/registry/deployments/default/my-deployment
```

**Безопасность:**
- TLS для коммуникации между узлами
- Encryption at rest для чувствительных данных
- Регулярные backup (критически важно!)

**Производительность:**
- Оптимизирована для чтения
- Compaction для управления размером данных
- Defragmentation для оптимизации пространства

#### 3. kube-scheduler

**Роль и назначение:**
- Принимает решения о размещении Pod на узлах
- Отслеживает новые Pod без назначенного узла
- Не запускает Pod, а только назначает узел

**Процесс планирования:**

**Фаза 1: Фильтрация (Predicate)**

Отбор узлов, удовлетворяющих требованиям:

*Resource Requirements:*
- Достаточно ли CPU и памяти
- Проверка requests, а не limits
- Учёт allocatable ресурсов узла

*Node Selectors и Affinity:*
```yaml
nodeSelector:
  disktype: ssd

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: zone
          operator: In
          values:
          - zone-1
          - zone-2
```

*Taints и Tolerations:*
```yaml
# Taint на узле
kubectl taint nodes node1 key=value:NoSchedule

# Toleration в Pod
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
```

*Pod Affinity/Anti-Affinity:*
- Размещение Pod рядом или вдали от других Pod
- На основе labels других Pod

*Volume Requirements:*
- Доступность нужных PersistentVolumes
- Topology constraints для volumes

**Фаза 2: Оценка (Priority/Scoring)**

Ранжирование подходящих узлов (0-100 баллов):

*Факторы оценки:*
- **LeastRequestedPriority**: предпочтение узлам с меньшей загрузкой
- **BalancedResourceAllocation**: баланс CPU и памяти
- **SelectorSpreadPriority**: распределение Pod с одинаковыми селекторами
- **ImageLocalityPriority**: предпочтение узлам с уже загруженными образами
- **NodeAffinityPriority**: учёт предпочтений affinity
- **InterPodAffinityPriority**: учёт pod affinity/anti-affinity

**Фаза 3: Назначение (Binding)**
- Выбор узла с наивысшим баллом
- Обновление Pod spec с указанием nodeName
- Запись в etcd через API server

**Расширяемость:**
- Scheduler Extenders для кастомной логики
- Scheduling Framework для plugins
- Возможность использования нескольких scheduler

**Пример кастомного scheduler:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  schedulerName: my-custom-scheduler
  containers:
  - name: app
    image: nginx
```

#### 4. kube-controller-manager

**Роль и назначение:**
- Запускает контроллеры кластера
- Реализует control loops (циклы управления)
- Обеспечивает достижение желаемого состояния

**Принцип работы контроллера:**
```
while true:
    desired_state = get_desired_state()
    current_state = get_current_state()
    if desired_state != current_state:
        make_changes_to_reach_desired_state()
    sleep()
```

**Основные контроллеры:**

**Node Controller:**
- Отслеживает состояние узлов
- Обнаруживает упавшие узлы
- Удаляет Pod с недоступных узлов
- Обновляет статусы узлов

Таймауты:
- Node Monitor Period: 5s (проверка состояния)
- Node Monitor Grace Period: 40s (время до пометки NotReady)
- Pod Eviction Timeout: 5m (время до удаления Pod)

**Replication Controller / ReplicaSet Controller:**
- Поддерживает заданное количество реплик Pod
- Создаёт новые Pod при нехватке
- Удаляет лишние Pod
- Базовый механизм для Deployment

**Deployment Controller:**
- Управляет ReplicaSets
- Реализует стратегии обновления
- Rolling updates и rollbacks
- Pause/Resume развёртываний

**StatefulSet Controller:**
- Управляет stateful приложениями
- Упорядоченное развёртывание и масштабирование
- Стабильные сетевые идентификаторы
- Постоянные volumes для каждого Pod

**DaemonSet Controller:**
- Обеспечивает запуск Pod на всех (или выбранных) узлах
- Автоматическое добавление Pod на новые узлы
- Используется для системных демонов (мониторинг, логирование, сетевые плагины)

**Job Controller:**
- Управляет одноразовыми задачами
- Обеспечивает успешное завершение
- Поддержка параллельного выполнения

**CronJob Controller:**
- Задачи по расписанию
- Создаёт Jobs по расписанию
- Управление историей выполненных Jobs

**Service Controller:**
- Создаёт и обновляет Endpoints для Services
- Управляет LoadBalancer (совместно с cloud-controller-manager)

**Namespace Controller:**
- Управляет жизненным циклом namespaces
- Удаляет все ресурсы при удалении namespace

**ServiceAccount Controller:**
- Создаёт default ServiceAccounts для новых namespaces
- Управляет токенами ServiceAccounts

**Endpoint Controller:**
- Создаёт объекты Endpoints
- Связывает Services с Pod
- Обновляет список endpoints при изменении Pod

**ResourceQuota Controller:**
- Отслеживает использование ресурсов в namespaces
- Блокирует создание ресурсов при превышении квот

**PersistentVolume Controller:**
- Управляет PV и PVC
- Привязывает PVC к подходящим PV
- Dynamic provisioning через Storage Classes

#### 5. cloud-controller-manager

**Роль и назначение:**
- Интеграция Kubernetes с облачными провайдерами
- Отделение cloud-specific логики от core компонентов
- Упрощение поддержки разных облаков

**Контроллеры:**

**Node Controller:**
- Инициализация узлов с метаданными облака
- Получение информации о регионе/зоне
- Проверка существования узла в облаке
- Удаление узлов из Kubernetes при удалении VM

**Route Controller:**
- Настройка маршрутов в облачной сети
- Обеспечение сетевой связности Pod
- Специфичен для каждого облачного провайдера

**Service Controller:**
- Создание облачных Load Balancers для Service type LoadBalancer
- Обновление конфигурации балансировщиков
- Удаление балансировщиков при удалении Service
- Назначение внешних IP-адресов

**Примеры интеграций:**
- AWS: ELB/ALB/NLB для LoadBalancer Services
- GCP: Cloud Load Balancing
- Azure: Azure Load Balancer
- OpenStack: LBaaS

**Volume Controller (в некоторых реализациях):**
- Управление облачными volumes (EBS, GCE PD, Azure Disk)
- Attach/Detach операции
- Перемещено в CSI (Container Storage Interface) в новых версиях

### Взаимодействие компонентов Control Plane

**Паттерн взаимодействия:**
```
1. kubectl → API Server
2. API Server → etcd (сохранение)
3. Controllers → API Server (watch изменений)
4. Controllers → API Server (обновление состояния)
5. Scheduler → API Server (watch новых Pod)
6. Scheduler → API Server (назначение узла)
```

**Decoupling через API Server:**
- Все компоненты взаимодействуют только с API Server
- Никто не обращается напрямую к etcd, кроме API Server
- Watch механизм для получения обновлений в реальном времени
- Асинхронная и event-driven архитектура

**Высокая доступность:**
- Все компоненты могут работать в multiple экземплярах
- Leader election для контроллеров (только один активный)
- API Server может быть за load balancer
- etcd cluster с 3-5 узлами для консенсуса

## Источники
- Официальная документация Kubernetes: Control Plane Components (kubernetes.io/docs/concepts/overview/components/)
- Kubernetes: The Definitive Guide, Marko Lukša
- Managing Kubernetes, Brendan Burns, Craig Tracey
- Programming Kubernetes, Michael Hausenblas, Stefan Schimanski
