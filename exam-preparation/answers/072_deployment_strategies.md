# Виды стратегий обновления приложения

## Краткий ответ
Основные стратегии обновления приложений в Kubernetes: **Rolling Update** (постепенная замена Pod, нулевой downtime, по умолчанию), **Recreate** (удаление всех старых Pod перед созданием новых, с downtime), **Blue-Green** (развёртывание новой версии параллельно, переключение трафика), **Canary** (постепенное переключение части трафика на новую версию для тестирования) и **A/B Testing** (направление трафика на разные версии по критериям). Выбор зависит от требований к downtime, рискам и необходимости тестирования.

## Развёрнутый ответ

### 1. Rolling Update (Плавающее обновление)

**Описание:**
Rolling Update — это стратегия обновления по умолчанию в Kubernetes Deployment. Новые Pod создаются постепенно, параллельно старые Pod удаляются.

**Принцип работы:**

1. Создаётся несколько новых Pod с новой версией
2. Ожидается их готовность (readiness probe)
3. Удаляются старые Pod
4. Процесс повторяется до полной замены

**Конфигурация в Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2         # Максимум дополнительных Pod (25% по умолчанию)
      maxUnavailable: 1   # Максимум недоступных Pod (25% по умолчанию)
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: app
        image: myapp:v2
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Параметры:**

**maxSurge:**
- Максимальное количество Pod сверх `replicas` во время обновления
- Можно указать число (`2`) или процент (`25%`)
- Определяет скорость обновления
- Значение 0 означает, что сначала удаляются старые Pod

**maxUnavailable:**
- Максимальное количество Pod, которые могут быть недоступны
- Можно указать число (`1`) или процент (`25%`)
- Влияет на доступность во время обновления
- Значение 0 означает, что сначала создаются новые Pod

**Примеры конфигураций:**

*Быстрое обновление (больше параллелизма):*
```yaml
rollingUpdate:
  maxSurge: 50%
  maxUnavailable: 50%
```

*Осторожное обновление (меньше риска):*
```yaml
rollingUpdate:
  maxSurge: 1
  maxUnavailable: 0
```

*Минимальное влияние на ресурсы:*
```yaml
rollingUpdate:
  maxSurge: 0
  maxUnavailable: 1
```

**Процесс обновления:**

```bash
# Запуск обновления
kubectl set image deployment/myapp app=myapp:v2

# Или через apply
kubectl apply -f deployment-v2.yaml

# Проверка статуса
kubectl rollout status deployment/myapp

# Пауза обновления
kubectl rollout pause deployment/myapp

# Возобновление
kubectl rollout resume deployment/myapp

# История ревизий
kubectl rollout history deployment/myapp

# Откат к предыдущей версии
kubectl rollout undo deployment/myapp

# Откат к конкретной ревизии
kubectl rollout undo deployment/myapp --to-revision=3
```

**Визуализация процесса:**
```
Начало (10 Pod v1):
[v1][v1][v1][v1][v1][v1][v1][v1][v1][v1]

Шаг 1 (maxSurge=2):
[v1][v1][v1][v1][v1][v1][v1][v1][v1][v1][v2][v2]

Шаг 2 (maxUnavailable=1):
[v1][v1][v1][v1][v1][v1][v1][v1][v2][v2][v2]

Шаг 3:
[v1][v1][v1][v1][v1][v1][v2][v2][v2][v2][v2]

...продолжение...

Конец (10 Pod v2):
[v2][v2][v2][v2][v2][v2][v2][v2][v2][v2]
```

**Преимущества:**
- Нулевой или минимальный downtime
- Постепенное обновление снижает риск
- Встроенная поддержка в Kubernetes
- Автоматический откат при ошибках (с дополнительными настройками)

**Недостатки:**
- Две версии работают одновременно (могут быть проблемы совместимости)
- Дополнительные ресурсы нужны для новых Pod
- Медленнее, чем Recreate

**Когда использовать:**
- Stateless приложения
- Требуется высокая доступность
- Production окружения
- Микросервисы

### 2. Recreate (Пересоздание)

**Описание:**
Стратегия Recreate останавливает все старые Pod перед созданием новых. Гарантирует, что только одна версия работает в каждый момент времени.

**Конфигурация:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:v2
```

**Процесс обновления:**

1. Deployment controller устанавливает replicas старого ReplicaSet в 0
2. Все старые Pod удаляются
3. Ожидается завершение удаления
4. Создаётся новый ReplicaSet с новой версией
5. Создаются новые Pod

**Визуализация:**
```
Начало:
[v1][v1][v1][v1][v1]

Удаление старых:
[ ][ ][ ][ ][ ]  ← Downtime

Создание новых:
[v2][v2][v2][v2][v2]
```

**Временная шкала:**
```
t=0s:  Начало обновления
t=5s:  Все старые Pod удалены
       ↓ Downtime период ↓
t=15s: Новые Pod создаются
t=25s: Новые Pod ready
t=30s: Обновление завершено
```

**Преимущества:**
- Простота реализации
- Гарантия, что только одна версия работает
- Не требуется дополнительных ресурсов
- Быстрое обновление
- Подходит для stateful приложений с несовместимыми версиями

**Недостатки:**
- Downtime во время обновления
- Не подходит для production с требованиями высокой доступности
- Все пользователи затронуты одновременно

**Когда использовать:**
- Development/testing окружения
- Приложения с maintenance windows
- Stateful приложения, которые не поддерживают параллельные версии
- База данных с миграциями схемы
- Когда downtime приемлем

**Пример с maintenance window:**
```bash
# Запланированное maintenance окно
# 1. Уведомить пользователей
# 2. В maintenance window:
kubectl set image deployment/myapp app=myapp:v2
# 3. Дождаться завершения
kubectl rollout status deployment/myapp
# 4. Проверить работоспособность
# 5. Уведомить о завершении maintenance
```

### 3. Blue-Green Deployment

**Описание:**
Blue-Green — это стратегия, где новая версия (Green) развёртывается параллельно старой (Blue), затем трафик мгновенно переключается с Blue на Green.

**Принцип работы:**

1. Текущая версия (Blue) обслуживает весь трафик
2. Развёртывается новая версия (Green) с тем же количеством Pod
3. Новая версия тестируется (но не получает production трафик)
4. Переключение Service на новую версию (изменение selector)
5. Старая версия (Blue) остаётся для быстрого отката

**Реализация в Kubernetes:**

**Deployment Blue (текущая версия):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:v1
```

**Deployment Green (новая версия):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:v2
```

**Service (изначально указывает на Blue):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue  # Указывает на Blue
  ports:
  - port: 80
    targetPort: 8080
```

**Процесс переключения:**

```bash
# 1. Развернуть Green версию
kubectl apply -f deployment-green.yaml

# 2. Проверить готовность Green
kubectl rollout status deployment/myapp-green
kubectl get pods -l version=green

# 3. Тестирование Green версии (без production трафика)
kubectl port-forward deployment/myapp-green 8080:8080
# Выполнить тесты

# 4. Переключить Service на Green
kubectl patch service myapp-service -p '{"spec":{"selector":{"version":"green"}}}'

# 5. Проверить, что трафик идёт на Green
kubectl get endpoints myapp-service

# 6. Если всё OK, удалить Blue
# (или оставить для быстрого отката)
kubectl delete deployment myapp-blue

# 7. Для отката (если что-то пошло не так):
kubectl patch service myapp-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

**Визуализация:**
```
Начальное состояние:
Blue (v1):  [Pod][Pod][Pod][Pod][Pod] ← Service (весь трафик)
Green (v2): не существует

После развёртывания Green:
Blue (v1):  [Pod][Pod][Pod][Pod][Pod] ← Service (весь трафик)
Green (v2): [Pod][Pod][Pod][Pod][Pod] (без трафика)

После переключения:
Blue (v1):  [Pod][Pod][Pod][Pod][Pod] (без трафика)
Green (v2): [Pod][Pod][Pod][Pod][Pod] ← Service (весь трафик)

После удаления Blue:
Green (v2): [Pod][Pod][Pod][Pod][Pod] ← Service (весь трафик)
```

**Преимущества:**
- Мгновенное переключение трафика
- Легко откатиться (просто переключить Service обратно)
- Новая версия полностью тестируется перед получением трафика
- Нулевой downtime
- Чёткое разделение версий

**Недостатки:**
- Требуется двойной объём ресурсов во время переключения
- Сложнее с stateful приложениями
- Необходимо управлять двумя Deployments
- Проблемы с shared ресурсами (база данных)

**Когда использовать:**
- Критичные production приложения
- Когда необходимо полное тестирование перед переключением
- Когда возможен мгновенный откат
- Stateless приложения
- Достаточно ресурсов для двойного развёртывания

### 4. Canary Deployment

**Описание:**
Canary — это стратегия постепенного переключения небольшого процента трафика на новую версию для тестирования в production, с последующим увеличением при успехе.

**Принцип работы:**

1. Развёртывается небольшое количество Pod новой версии
2. Небольшой процент трафика направляется на новую версию
3. Мониторинг метрик (ошибки, latency, бизнес-метрики)
4. При успехе — постепенное увеличение процента
5. При проблемах — быстрый откат
6. В конце — полная замена на новую версию

**Реализация с встроенными средствами Kubernetes:**

**Вариант 1: Использование нескольких Deployments**

```yaml
# Старая версия (90% Pod)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      track: stable
  template:
    metadata:
      labels:
        app: myapp
        track: stable
        version: v1
    spec:
      containers:
      - name: app
        image: myapp:v1
---
# Новая версия (10% Pod)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      track: canary
  template:
    metadata:
      labels:
        app: myapp
        track: canary
        version: v2
    spec:
      containers:
      - name: app
        image: myapp:v2
---
# Service выбирает оба Deployment
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp  # Только app, без track
  ports:
  - port: 80
    targetPort: 8080
```

**Процесс постепенного переключения:**

```bash
# Шаг 1: 10% трафика на canary
# stable: 9 Pod, canary: 1 Pod

# Шаг 2: Мониторинг метрик
kubectl logs -l track=canary --tail=100
# Проверка error rate, latency, etc.

# Шаг 3: Увеличение до 25%
# stable: 3 Pod, canary: 1 Pod
kubectl scale deployment myapp-stable --replicas=3

# Шаг 4: Увеличение до 50%
# stable: 5 Pod, canary: 5 Pod
kubectl scale deployment myapp-stable --replicas=5
kubectl scale deployment myapp-canary --replicas=5

# Шаг 5: Полное переключение
# stable: 0 Pod, canary: 10 Pod
kubectl scale deployment myapp-stable --replicas=0
kubectl scale deployment myapp-canary --replicas=10

# Шаг 6: Cleanup
kubectl delete deployment myapp-stable
# Переименовать canary в stable для следующего цикла
```

**Вариант 2: С Istio/Service Mesh**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.example.com
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: myapp
        subset: v2
  - route:
    - destination:
        host: myapp
        subset: v1
      weight: 90
    - destination:
        host: myapp
        subset: v2
      weight: 10
```

**Продвинутый Canary с Flagger:**

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
```

**Визуализация процесса:**
```
Начало:
v1: [Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod] (100% трафика)
v2: не существует

Canary 10%:
v1: [Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod] (90% трафика)
v2: [Pod] (10% трафика)

Canary 50%:
v1: [Pod][Pod][Pod][Pod][Pod] (50% трафика)
v2: [Pod][Pod][Pod][Pod][Pod] (50% трафика)

Полное переключение:
v1: удалено
v2: [Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod][Pod] (100% трафика)
```

**Преимущества:**
- Минимальный риск (затронута только часть пользователей)
- Раннее обнаружение проблем в production
- Постепенное масштабирование нагрузки на новую версию
- Легко откатиться (уменьшить процент до 0)
- Real-world тестирование

**Недостатки:**
- Сложнее в реализации
- Требуется хороший мониторинг
- Медленный процесс полного развёртывания
- Сложность с stateful приложениями
- Две версии работают длительное время

**Когда использовать:**
- Критичные production приложения
- Новые major изменения
- Когда есть хороший мониторинг
- A/B тестирование новых фич
- Постепенный переход на новую версию

### 5. A/B Testing

**Описание:**
A/B Testing — это направление трафика на разные версии на основе определённых критериев (user attributes, headers, geography) для тестирования гипотез.

**Отличие от Canary:**
- **Canary**: направляет случайный процент трафика, цель — стабильность
- **A/B Testing**: направляет трафик по правилам, цель — тестирование гипотез

**Реализация с Istio:**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.example.com
  http:
  # Правило 1: Premium пользователи → v2
  - match:
    - headers:
        user-tier:
          exact: premium
    route:
    - destination:
        host: myapp
        subset: v2
  # Правило 2: Пользователи из US → v2
  - match:
    - headers:
        geo-location:
          exact: US
    route:
    - destination:
        host: myapp
        subset: v2
  # Правило 3: Все остальные → v1
  - route:
    - destination:
        host: myapp
        subset: v1
```

**С Ingress-nginx:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ab-testing
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"
    nginx.ingress.kubernetes.io/canary-by-header-value: "true"
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-v2
            port:
              number: 80
```

**Когда использовать:**
- Тестирование новых фич
- Сравнение бизнес-метрик
- Персонализация опыта
- Постепенное внедрение изменений для групп пользователей

### Сравнительная таблица стратегий

| Критерий | Rolling Update | Recreate | Blue-Green | Canary | A/B Testing |
|----------|----------------|----------|------------|--------|-------------|
| Downtime | Нет | Есть | Нет | Нет | Нет |
| Скорость развёртывания | Средняя | Быстрая | Быстрая | Медленная | Медленная |
| Риск | Средний | Высокий | Низкий | Очень низкий | Низкий |
| Требования к ресурсам | Средние | Низкие | Высокие (2x) | Средние | Средние |
| Сложность реализации | Низкая | Очень низкая | Средняя | Высокая | Высокая |
| Откат | Автоматический | Ручной | Мгновенный | Постепенный | Настраиваемый |
| Две версии одновременно | Временно | Нет | Короткое время | Длительно | Длительно |
| Подходит для stateful | Ограниченно | Да | Сложно | Сложно | Сложно |
| Требуется Service Mesh | Нет | Нет | Нет | Желательно | Да |

### Best Practices

**1. Всегда используйте readiness probes:**
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

**2. Настройте PodDisruptionBudget:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

**3. Используйте мониторинг:**
- Prometheus для метрик
- Grafana для дашбордов
- Алерты на аномалии

**4. Автоматизируйте через CI/CD:**
```yaml
# GitLab CI example
deploy-canary:
  stage: deploy
  script:
    - kubectl apply -f deployment-canary.yaml
    - ./wait-and-monitor.sh
    - if [ $? -eq 0 ]; then
        kubectl apply -f deployment-full.yaml
      fi
```

**5. Тестируйте откат:**
- Регулярно практикуйте rollback
- Документируйте процедуры отката

## Источники
- Официальная документация Kubernetes: Deployment Strategies (kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- Kubernetes Patterns, Bilgin Ibryam
- Site Reliability Engineering, Google
- Flagger Documentation (flagger.app)
- Istio Traffic Management
