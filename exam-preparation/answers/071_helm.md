# Для чего нужен Helm?

## Краткий ответ
**Helm** — это пакетный менеджер для Kubernetes, упрощающий развёртывание и управление приложениями. Helm позволяет: **упаковывать приложения** в charts (пакеты с шаблонами и конфигурацией), **параметризировать развёртывание** через values, **управлять версиями** релизов (install/upgrade/rollback), **распространять приложения** через репозитории charts. Helm решает проблему сложности управления множеством YAML манифестов и делает развёртывание приложений в Kubernetes более простым и воспроизводимым.

## Развёрнутый ответ

### Назначение Helm

**Определение:**
Helm — это пакетный менеджер для Kubernetes, аналогичный apt/yum для Linux или npm для Node.js.

**Основные проблемы, которые решает Helm:**

1. **Управление сложностью:**
   - Типичное приложение требует множество Kubernetes ресурсов (Deployment, Service, ConfigMap, Secret, Ingress, PV, PVC и т.д.)
   - Управление десятками YAML файлов становится сложным
   - Helm объединяет все ресурсы в один пакет

2. **Параметризация:**
   - Одно приложение нужно развернуть в разных окружениях (dev, staging, prod)
   - Каждое окружение требует разных настроек
   - Helm использует шаблоны и values для параметризации

3. **Повторное использование:**
   - Стандартные приложения (nginx, PostgreSQL, Redis) имеют готовые charts
   - Не нужно писать манифесты с нуля
   - Сообщество поддерживает тысячи готовых charts

4. **Версионирование:**
   - Helm отслеживает историю развёртываний
   - Легко откатиться к предыдущей версии
   - Управление жизненным циклом приложения

5. **Dependency Management:**
   - Приложение может зависеть от других приложений
   - Helm автоматически разворачивает зависимости

### Архитектура Helm

**Версии Helm:**

**Helm 2 (deprecated):**
- Клиент (helm CLI) + сервер (Tiller в кластере)
- Tiller имел проблемы с безопасностью
- Больше не поддерживается

**Helm 3 (текущая версия):**
- Только клиент (без Tiller)
- Безопаснее и проще
- Прямое взаимодействие с API server

**Компоненты Helm 3:**

```
Helm CLI → Kubernetes API Server → Ресурсы в кластере
   ↓
Chart Repository (хранилище charts)
```

**Helm CLI:**
- Читает chart
- Рендерит шаблоны с values
- Отправляет манифесты в Kubernetes API
- Сохраняет информацию о релизе как Secret

### Основные концепции

#### 1. Chart

**Определение:**
Chart — это пакет Helm, содержащий все необходимые ресурсы для развёртывания приложения.

**Структура Chart:**
```
mychart/
├── Chart.yaml          # Метаданные chart
├── values.yaml         # Значения по умолчанию
├── charts/             # Зависимые charts
├── templates/          # Шаблоны Kubernetes манифестов
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl    # Вспомогательные шаблоны
│   └── NOTES.txt       # Информация после установки
├── .helmignore         # Файлы для игнорирования
└── README.md           # Документация
```

**Chart.yaml:**
```yaml
apiVersion: v2
name: mychart
description: A Helm chart for my application
type: application
version: 0.1.0          # Версия chart
appVersion: "1.16.0"    # Версия приложения

maintainers:
  - name: John Doe
    email: john@example.com

dependencies:
  - name: postgresql
    version: 12.1.0
    repository: https://charts.bitnami.com/bitnami
```

**values.yaml:**
```yaml
# Значения по умолчанию для шаблонов

replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.16.0"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: "nginx"
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

**Шаблоны (templates/deployment.yaml):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mychart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

**Шаблонизация:**

Helm использует Go templates для генерации манифестов:

**Встроенные объекты:**
- `{{ .Release.Name }}`: имя релиза
- `{{ .Release.Namespace }}`: namespace релиза
- `{{ .Chart.Name }}`: имя chart
- `{{ .Chart.Version }}`: версия chart
- `{{ .Values }}`: values из values.yaml

**Функции:**
- `{{ include "mychart.name" . }}`: вызов named template
- `{{ .Values.image.tag | default "latest" }}`: значение по умолчанию
- `{{ .Values.resources | toYaml | nindent 8 }}`: конвертация в YAML
- `{{ if .Values.ingress.enabled }}...{{ end }}`: условия
- `{{ range .Values.hosts }}...{{ end }}`: циклы

**_helpers.tpl (вспомогательные шаблоны):**
```yaml
{{/* Generate full name */}}
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
```

#### 2. Release

**Определение:**
Release — это экземпляр chart, установленный в кластер.

**Характеристики:**
- Каждая установка chart создаёт новый release
- Один chart можно установить множество раз (разные releases)
- Release имеет уникальное имя в namespace
- История всех версий release сохраняется

**Пример:**
```bash
# Создание release "my-nginx" из chart nginx
helm install my-nginx bitnami/nginx

# Создание второго release из того же chart
helm install my-nginx-2 bitnami/nginx
```

#### 3. Repository

**Определение:**
Repository — это хранилище Helm charts, откуда можно скачивать и устанавливать charts.

**Популярные репозитории:**
- **Artifact Hub**: https://artifacthub.io (центральный каталог)
- **Bitnami**: https://charts.bitnami.com/bitnami (популярные приложения)
- **Jetstack**: https://charts.jetstack.io (cert-manager)
- **Prometheus Community**: https://prometheus-community.github.io/helm-charts

**Работа с репозиториями:**
```bash
# Добавление репозитория
helm repo add bitnami https://charts.bitnami.com/bitnami

# Обновление списка charts
helm repo update

# Поиск charts
helm search repo nginx

# Список репозиториев
helm repo list

# Удаление репозитория
helm repo remove bitnami
```

### Основные команды Helm

#### Установка

**Установка Helm CLI:**
```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS
brew install helm

# Windows
choco install kubernetes-helm
```

#### Работа с Charts

**Поиск charts:**
```bash
# Поиск в добавленных репозиториях
helm search repo postgresql

# Поиск в Artifact Hub
helm search hub wordpress
```

**Просмотр информации о chart:**
```bash
# Информация о chart
helm show chart bitnami/nginx

# Значения по умолчанию
helm show values bitnami/nginx

# Всё вместе
helm show all bitnami/nginx

# README
helm show readme bitnami/nginx
```

**Загрузка chart:**
```bash
# Скачать chart локально
helm pull bitnami/nginx

# Распаковать
helm pull bitnami/nginx --untar
```

#### Управление Releases

**Установка:**
```bash
# Простая установка
helm install my-release bitnami/nginx

# С кастомными values
helm install my-release bitnami/nginx --set replicaCount=3

# Из values файла
helm install my-release bitnami/nginx -f custom-values.yaml

# С множественными values файлами (приоритет последнему)
helm install my-release bitnami/nginx -f base-values.yaml -f prod-values.yaml

# В конкретном namespace
helm install my-release bitnami/nginx -n production --create-namespace

# Сгенерировать имя автоматически
helm install bitnami/nginx --generate-name

# Dry-run (проверка без установки)
helm install my-release bitnami/nginx --dry-run --debug
```

**Список releases:**
```bash
# Все releases в текущем namespace
helm list

# Все releases во всех namespaces
helm list -A

# В конкретном namespace
helm list -n production

# Включая uninstalled
helm list --uninstalled

# Все (включая failed)
helm list --all
```

**Информация о release:**
```bash
# Статус release
helm status my-release

# Используемые values
helm get values my-release

# Все values (включая defaults)
helm get values my-release --all

# Сгенерированные манифесты
helm get manifest my-release

# NOTES
helm get notes my-release

# История
helm history my-release
```

**Обновление:**
```bash
# Обновление release
helm upgrade my-release bitnami/nginx

# С новыми values
helm upgrade my-release bitnami/nginx --set replicaCount=5

# Из values файла
helm upgrade my-release bitnami/nginx -f updated-values.yaml

# Установка, если не существует
helm upgrade --install my-release bitnami/nginx

# Reuse values (сохранить предыдущие values)
helm upgrade my-release bitnami/nginx --reuse-values

# Atomic (откат при ошибке)
helm upgrade my-release bitnami/nginx --atomic

# Wait (ждать ready состояния)
helm upgrade my-release bitnami/nginx --wait --timeout 5m
```

**Откат:**
```bash
# Откат к предыдущей версии
helm rollback my-release

# Откат к конкретной ревизии
helm rollback my-release 3

# Dry-run rollback
helm rollback my-release --dry-run
```

**Удаление:**
```bash
# Удаление release
helm uninstall my-release

# Удаление с сохранением истории
helm uninstall my-release --keep-history

# Purge (полное удаление, для Helm 2)
helm delete --purge my-release
```

#### Создание собственных Charts

**Создание нового chart:**
```bash
# Создание структуры chart
helm create mychart

# Проверка синтаксиса
helm lint mychart/

# Рендеринг шаблонов
helm template mychart/

# Рендеринг с values
helm template my-release mychart/ -f values.yaml

# Dry-run install для проверки
helm install my-release mychart/ --dry-run --debug
```

**Упаковка chart:**
```bash
# Создание .tgz архива
helm package mychart/

# С подписью
helm package mychart/ --sign --key keyname
```

**Dependency management:**
```bash
# Chart.yaml с зависимостями
dependencies:
  - name: postgresql
    version: 12.1.0
    repository: https://charts.bitnami.com/bitnami

# Скачать зависимости
helm dependency update mychart/

# Список зависимостей
helm dependency list mychart/

# Собрать зависимости в charts/
helm dependency build mychart/
```

### Практические примеры

#### Пример 1: Развёртывание WordPress

```bash
# Добавить репозиторий
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Создать values файл
cat > wordpress-values.yaml <<EOF
wordpressUsername: admin
wordpressPassword: secure-password
wordpressEmail: admin@example.com
service:
  type: LoadBalancer
persistence:
  enabled: true
  size: 10Gi
mariadb:
  auth:
    rootPassword: db-root-password
    password: db-user-password
EOF

# Установить WordPress
helm install my-wordpress bitnami/wordpress \
  -f wordpress-values.yaml \
  -n wordpress --create-namespace

# Проверить статус
helm status my-wordpress -n wordpress

# Получить URL
export SERVICE_IP=$(kubectl get svc --namespace wordpress my-wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
echo "WordPress URL: http://$SERVICE_IP/"
```

#### Пример 2: Мониторинг с Prometheus Stack

```bash
# Добавить репозиторий
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Создать values для кастомизации
cat > prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

grafana:
  adminPassword: admin-password
  ingress:
    enabled: true
    hosts:
      - grafana.example.com

alertmanager:
  enabled: true
EOF

# Установить
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml \
  -n monitoring --create-namespace

# Port-forward к Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

#### Пример 3: Управление окружениями

**Структура values:**
```
values/
├── base-values.yaml       # Общие для всех окружений
├── dev-values.yaml        # Специфичные для dev
├── staging-values.yaml    # Специфичные для staging
└── prod-values.yaml       # Специфичные для prod
```

**base-values.yaml:**
```yaml
image:
  repository: myapp
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
```

**prod-values.yaml:**
```yaml
replicaCount: 5

image:
  tag: "1.0.0"

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

ingress:
  enabled: true
  hosts:
    - host: app.example.com
```

**Развёртывание:**
```bash
# Production
helm upgrade --install myapp ./mychart \
  -f values/base-values.yaml \
  -f values/prod-values.yaml \
  -n production

# Development
helm upgrade --install myapp ./mychart \
  -f values/base-values.yaml \
  -f values/dev-values.yaml \
  -n development
```

### Best Practices

**1. Используйте values для параметризации:**
- Не hardcode значения в шаблонах
- Всё, что может измениться, должно быть в values

**2. Версионируйте charts:**
- Следуйте semantic versioning
- Обновляйте `version` в Chart.yaml при изменениях

**3. Документируйте values:**
- Комментарии в values.yaml
- README с примерами

**4. Используйте зависимости вместо копирования:**
- Не копируйте charts других приложений
- Объявляйте их как dependencies

**5. Тестируйте charts:**
```bash
helm lint mychart/
helm template mychart/ --debug
helm install test-release mychart/ --dry-run
```

**6. Используйте named templates (_helpers.tpl):**
- DRY (Don't Repeat Yourself)
- Переиспользование логики

**7. Храните charts в Git:**
- Version control
- Code review
- CI/CD integration

**8. Используйте Helm Secrets для чувствительных данных:**
```bash
# С плагином helm-secrets
helm secrets install my-release mychart/ -f secrets.yaml
```

**9. Настройте .helmignore:**
```
.git/
.gitignore
.DS_Store
*.swp
*.tmp
```

**10. Используйте hooks для сложных операций:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: post-install-job
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": hook-succeeded
```

### Альтернативы Helm

**Kustomize:**
- Встроен в kubectl
- Overlay approach
- Нет шаблонизации

**Jsonnet:**
- JSON templating language
- Более мощный, но сложнее

**Plain YAML + CI/CD:**
- Простые манифесты
- Параметризация через CI/CD переменные

**Operators:**
- Custom Controllers
- Для сложных stateful приложений

## Источники
- Официальная документация Helm (helm.sh/docs/)
- Learning Helm, Matt Butcher, Matt Farina, Josh Dolitsky
- Helm Best Practices Guide
- Artifact Hub (artifacthub.io)
