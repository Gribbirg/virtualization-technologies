# Какие сервисы предоставляет Kubernetes?

## Краткий ответ
Kubernetes предоставляет объект **Service** для организации сетевого доступа к Pod. Основные типы сервисов: **ClusterIP** (доступ внутри кластера), **NodePort** (доступ через порт на узле), **LoadBalancer** (внешний балансировщик нагрузки) и **ExternalName** (DNS CNAME для внешних сервисов). Service обеспечивает стабильную точку входа к группе динамически изменяющихся Pod через селекторы меток.

## Развёрнутый ответ

### Концепция Service в Kubernetes

Service — это абстракция, определяющая логический набор Pod и политику доступа к ним. Service решает проблему обнаружения и балансировки нагрузки между Pod, которые могут создаваться и уничтожаться динамически.

### Основные проблемы, решаемые Service

1. **Динамические IP-адреса**: Pod получают новые IP при перезапуске
2. **Обнаружение сервисов**: необходимость найти нужные Pod в кластере
3. **Балансировка нагрузки**: распределение трафика между репликами
4. **Абстракция доступа**: единая точка входа для группы Pod

### Типы Service

#### 1. ClusterIP (по умолчанию)

**Описание:**
- Создаёт виртуальный IP-адрес, доступный только внутри кластера
- Балансирует трафик между Pod через этот IP
- Используется для внутрикластерного взаимодействия

**Пример:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

**Применение:**
- Коммуникация между микросервисами внутри кластера
- База данных, доступная только для приложений в кластере
- Внутренние API

#### 2. NodePort

**Описание:**
- Расширяет ClusterIP, дополнительно открывая порт на каждом узле кластера
- Доступ к сервису извне через `<NodeIP>:<NodePort>`
- Порт из диапазона 30000-32767 (по умолчанию)

**Пример:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30080
```

**Применение:**
- Тестирование и разработка
- Доступ к сервису извне без внешнего балансировщика
- Простые production окружения

#### 3. LoadBalancer

**Описание:**
- Расширяет NodePort, создавая внешний балансировщик нагрузки
- Автоматически получает внешний IP-адрес от облачного провайдера
- Направляет трафик на NodePort сервиса

**Пример:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-loadbalancer-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

**Применение:**
- Production окружения в облачных провайдерах (AWS, GCP, Azure)
- Публичные API и веб-приложения
- Автоматическая балансировка внешнего трафика

#### 4. ExternalName

**Описание:**
- Создаёт CNAME запись для внешнего DNS имени
- Не использует селекторы и не создаёт endpoints
- Позволяет Pod обращаться к внешним сервисам через DNS кластера

**Пример:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-external-service
spec:
  type: ExternalName
  externalName: api.example.com
```

**Применение:**
- Интеграция с внешними базами данных
- Обращение к внешним API
- Миграция сервисов (постепенный переход external → internal)

### Дополнительные возможности Service

#### Headless Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-headless-service
spec:
  clusterIP: None  # Делает Service headless
  selector:
    app: my-app
  ports:
  - port: 80
```
- Не создаёт ClusterIP
- DNS возвращает IP-адреса всех Pod напрямую
- Используется для StatefulSet и прямого обращения к конкретным Pod

#### Multi-Port Services
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-multiport-service
spec:
  selector:
    app: my-app
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  - name: https
    protocol: TCP
    port: 443
    targetPort: 8443
```

#### Session Affinity
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-sticky-service
spec:
  selector:
    app: my-app
  sessionAffinity: ClientIP
  ports:
  - port: 80
```
- Направляет запросы от одного клиента на один Pod
- Полезно для stateful приложений

### Механизм работы Service

1. **Селекторы меток**: Service находит Pod по labels
2. **Endpoints**: автоматически создаваемый объект со списком IP Pod
3. **kube-proxy**: компонент на каждом узле, реализующий сетевые правила
4. **DNS**: каждый Service получает DNS имя вида `<service-name>.<namespace>.svc.cluster.local`

### Ingress vs Service

Ingress — это не тип Service, а отдельный ресурс для управления внешним HTTP/HTTPS доступом:
- Работает на уровне L7 (HTTP/HTTPS)
- Обеспечивает маршрутизацию на основе URL
- Поддерживает SSL/TLS терминацию
- Более гибкий для веб-приложений

## Источники
- Официальная документация Kubernetes: Service (kubernetes.io/docs/concepts/services-networking/service/)
- Kubernetes Networking: Service, Ingress, Network Policy
- Kubernetes Patterns: Reusable Elements for Designing Cloud-Native Applications
