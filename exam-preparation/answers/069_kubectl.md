# Что такое Kubectl?

## Краткий ответ
**kubectl** — это CLI (command-line interface) инструмент для взаимодействия с кластером Kubernetes. kubectl позволяет управлять ресурсами кластера (создание, чтение, обновление, удаление), просматривать логи, выполнять команды в контейнерах и отлаживать приложения. Работает через REST API сервера Kubernetes, использует конфигурацию из `~/.kube/config` для аутентификации и выбора кластера/контекста.

## Развёрнутый ответ

### Описание kubectl

**Определение:**
kubectl (произносится "cube-control" или "cube-cuttle") — это официальный command-line инструмент для управления Kubernetes кластерами.

**Основное назначение:**
- Развёртывание приложений
- Управление ресурсами кластера
- Просмотр логов
- Отладка приложений
- Администрирование кластера

**Архитектура:**
```
kubectl (CLI) → API Server (REST API) → etcd (хранилище)
                      ↓
                Controllers → Изменение состояния кластера
```

kubectl преобразует команды в HTTP REST запросы к API server.

### Установка kubectl

**Linux:**
```bash
# Скачивание последней версии
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Установка
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Проверка версии
kubectl version --client
```

**macOS:**
```bash
# Через Homebrew
brew install kubectl

# Или скачиванием
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

**Windows:**
```powershell
# Через Chocolatey
choco install kubernetes-cli

# Или через Scoop
scoop install kubectl
```

### Конфигурация kubectl

#### kubeconfig файл

**Расположение:**
- По умолчанию: `~/.kube/config`
- Можно указать через: `--kubeconfig` флаг или `KUBECONFIG` переменную окружения

**Структура kubeconfig:**
```yaml
apiVersion: v1
kind: Config
current-context: my-cluster

clusters:
- cluster:
    certificate-authority-data: <base64-encoded-ca-cert>
    server: https://kubernetes.example.com:6443
  name: my-cluster

contexts:
- context:
    cluster: my-cluster
    user: admin
    namespace: default  # namespace по умолчанию
  name: my-cluster

users:
- name: admin
  user:
    client-certificate-data: <base64-encoded-client-cert>
    client-key-data: <base64-encoded-client-key>
```

**Компоненты конфигурации:**

1. **Clusters**: информация о кластерах
   - URL API server
   - CA сертификат

2. **Users**: учётные данные
   - Сертификаты клиента
   - Токены
   - Credentials для аутентификации

3. **Contexts**: связь cluster + user + namespace
   - Определяет, к какому кластеру, от какого пользователя и в каком namespace работать

4. **Current-context**: активный контекст

#### Управление контекстами

**Просмотр текущего контекста:**
```bash
kubectl config current-context
```

**Список всех контекстов:**
```bash
kubectl config get-contexts
```

Вывод:
```
CURRENT   NAME                CLUSTER             AUTHINFO            NAMESPACE
*         dev-cluster         dev-cluster         dev-admin           development
          prod-cluster        prod-cluster        prod-admin          production
          staging-cluster     staging-cluster     staging-admin       staging
```

**Переключение контекста:**
```bash
kubectl config use-context prod-cluster
```

**Создание нового контекста:**
```bash
kubectl config set-context my-context \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=my-namespace
```

**Установка namespace по умолчанию:**
```bash
kubectl config set-context --current --namespace=production
```

**Просмотр конфигурации:**
```bash
kubectl config view
kubectl config view --minify  # только текущий контекст
```

### Основные категории команд

#### 1. Управление ресурсами (CRUD операции)

**Create (создание):**
```bash
# Из файла
kubectl create -f pod.yaml
kubectl apply -f deployment.yaml  # декларативный подход, предпочтительнее

# Императивно
kubectl create deployment nginx --image=nginx
kubectl create service clusterip my-service --tcp=80:8080
kubectl create configmap my-config --from-literal=key=value
kubectl create secret generic my-secret --from-literal=password=secret123
```

**Read (чтение):**
```bash
# Список ресурсов
kubectl get pods
kubectl get pods -n kube-system
kubectl get pods -A  # --all-namespaces
kubectl get pods -o wide  # дополнительная информация
kubectl get pods -o yaml  # YAML формат
kubectl get pods -o json  # JSON формат

# Детальная информация
kubectl describe pod my-pod
kubectl describe node my-node

# Вывод с labels
kubectl get pods --show-labels
kubectl get pods -l app=nginx  # фильтрация по labels

# Вывод с селекторами
kubectl get pods --field-selector status.phase=Running
```

**Update (обновление):**
```bash
# Применение изменений
kubectl apply -f updated-deployment.yaml

# Редактирование в текстовом редакторе
kubectl edit deployment my-deployment

# Patch (частичное обновление)
kubectl patch deployment my-deployment -p '{"spec":{"replicas":3}}'

# Set команды
kubectl set image deployment/nginx nginx=nginx:1.16.1
kubectl set resources deployment nginx --limits=cpu=200m,memory=512Mi
```

**Delete (удаление):**
```bash
# Удаление по файлу
kubectl delete -f pod.yaml

# Удаление по имени
kubectl delete pod my-pod
kubectl delete deployment my-deployment

# Удаление по label
kubectl delete pods -l app=nginx

# Удаление всех ресурсов типа
kubectl delete pods --all -n development

# Force delete (для зависших Pod)
kubectl delete pod my-pod --force --grace-period=0
```

#### 2. Работа с приложениями

**Развёртывание:**
```bash
# Создание Deployment
kubectl create deployment nginx --image=nginx:1.16.1 --replicas=3

# Expose как Service
kubectl expose deployment nginx --port=80 --target-port=8080 --type=LoadBalancer

# Запуск одноразового Pod
kubectl run debug --image=busybox --rm -it --restart=Never -- sh
```

**Масштабирование:**
```bash
# Ручное масштабирование
kubectl scale deployment nginx --replicas=5

# Автомасштабирование
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80
```

**Обновление образов:**
```bash
# Обновление образа
kubectl set image deployment/nginx nginx=nginx:1.17.1

# Проверка статуса rollout
kubectl rollout status deployment/nginx

# История ревизий
kubectl rollout history deployment/nginx

# Откат к предыдущей версии
kubectl rollout undo deployment/nginx

# Откат к конкретной ревизии
kubectl rollout undo deployment/nginx --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/nginx
kubectl rollout resume deployment/nginx
```

#### 3. Отладка и troubleshooting

**Логи:**
```bash
# Просмотр логов Pod
kubectl logs my-pod

# Логи конкретного контейнера в Pod
kubectl logs my-pod -c my-container

# Follow логи (как tail -f)
kubectl logs -f my-pod

# Логи предыдущего контейнера (после рестарта)
kubectl logs my-pod --previous

# Логи всех Pod с label
kubectl logs -l app=nginx --all-containers=true

# Последние N строк
kubectl logs my-pod --tail=50

# С timestamp
kubectl logs my-pod --timestamps
```

**Exec (выполнение команд):**
```bash
# Интерактивная оболочка
kubectl exec -it my-pod -- /bin/bash
kubectl exec -it my-pod -- sh

# Выполнение команды
kubectl exec my-pod -- ls /app
kubectl exec my-pod -- cat /etc/resolv.conf

# В конкретном контейнере
kubectl exec -it my-pod -c my-container -- bash
```

**Port forwarding:**
```bash
# Проброс порта Pod на localhost
kubectl port-forward pod/my-pod 8080:80
# localhost:8080 → Pod:80

# Проброс Service
kubectl port-forward service/my-service 8080:80

# Проброс Deployment
kubectl port-forward deployment/my-deployment 8080:80

# Слушать на всех интерфейсах
kubectl port-forward --address 0.0.0.0 pod/my-pod 8080:80
```

**Копирование файлов:**
```bash
# Из Pod на локальную машину
kubectl cp my-pod:/path/to/file /local/path

# С локальной машины в Pod
kubectl cp /local/file my-pod:/path/in/pod

# С указанием контейнера
kubectl cp my-pod:/path/to/file /local/path -c my-container
```

**Attach к контейнеру:**
```bash
kubectl attach my-pod -i
```

**Proxy:**
```bash
# Запуск локального прокси к API server
kubectl proxy --port=8080
# Доступ к API: http://localhost:8080/api/v1
```

#### 4. Информация о кластере

**Узлы:**
```bash
# Список узлов
kubectl get nodes
kubectl get nodes -o wide

# Детали узла
kubectl describe node my-node

# Использование ресурсов
kubectl top nodes
```

**Namespaces:**
```bash
# Список namespaces
kubectl get namespaces
kubectl get ns  # короткая форма

# Создание namespace
kubectl create namespace development
```

**События:**
```bash
# События в namespace
kubectl get events

# События в определённом namespace
kubectl get events -n kube-system

# Сортировка по времени
kubectl get events --sort-by='.lastTimestamp'

# Watch события
kubectl get events -w
```

**API Resources:**
```bash
# Список всех типов ресурсов
kubectl api-resources

# Короткие имена
kubectl api-resources -o name

# API версии
kubectl api-versions
```

**Cluster Info:**
```bash
# Информация о кластере
kubectl cluster-info

# Dump информации для отладки
kubectl cluster-info dump
```

#### 5. Применение конфигураций

**Декларативный подход (рекомендуется):**
```bash
# Применение одного файла
kubectl apply -f deployment.yaml

# Применение директории
kubectl apply -f ./configs/

# Рекурсивно
kubectl apply -R -f ./configs/

# С dry-run (проверка без применения)
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=server  # с валидацией сервера

# Diff перед применением
kubectl diff -f deployment.yaml
```

**Генерация YAML:**
```bash
# Генерация без создания
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml

# Перенаправление в файл
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml

# Генерация service
kubectl create service clusterip my-service --tcp=80:8080 --dry-run=client -o yaml
```

### Продвинутые возможности

#### Работа с JSONPath

**Выборка конкретных полей:**
```bash
# Получить IP всех Pod
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# Имена всех контейнеров
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP

# Range для итерации
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

#### Плагины kubectl

**krew (менеджер плагинов):**
```bash
# Установка krew
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz"
tar zxvf krew-linux_amd64.tar.gz
./krew-linux_amd64 install krew

# Установка плагинов
kubectl krew install ctx  # kubectx
kubectl krew install ns   # kubens
kubectl krew install tree # визуализация иерархии ресурсов
```

**Популярные плагины:**
- **kubectx/kubens**: быстрое переключение контекстов и namespaces
- **kubectl-tree**: визуализация дерева ресурсов
- **kubectl-who-can**: проверка RBAC прав
- **kubectl-debug**: расширенная отладка

#### Shell автодополнение

**Bash:**
```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
```

**Zsh:**
```bash
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'complete -F __start_kubectl k' >> ~/.zshrc
```

#### Полезные алиасы

```bash
# Добавить в ~/.bashrc или ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
```

### Императивный vs Декларативный подход

**Императивный (не рекомендуется для production):**
```bash
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
kubectl set image deployment/nginx nginx=nginx:1.17
```

Проблемы:
- Нет истории изменений
- Трудно воспроизвести
- Не подходит для GitOps

**Декларативный (рекомендуется):**
```bash
# deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f deployment.yaml  # idempotent, можно применять многократно
```

Преимущества:
- Версионирование в Git
- Воспроизводимость
- Auditability
- GitOps friendly

### Best Practices

**1. Используйте декларативный подход:**
```bash
kubectl apply -f config.yaml
```

**2. Версионируйте конфигурации в Git**

**3. Используйте namespaces:**
```bash
kubectl apply -f deployment.yaml -n production
```

**4. Добавьте labels для организации:**
```yaml
metadata:
  labels:
    app: nginx
    env: production
    team: backend
```

**5. Всегда указывайте resource requests/limits**

**6. Используйте --dry-run для проверки:**
```bash
kubectl apply -f deployment.yaml --dry-run=server
```

**7. Регулярно обновляйте kubectl:**
- Поддерживайте kubectl в пределах ±1 minor версии от кластера
- kubectl 1.27 может работать с кластером 1.26, 1.27, 1.28

### Troubleshooting распространённых проблем

**Проблема: kubectl не может подключиться к кластеру**
```bash
# Проверка конфигурации
kubectl config view
kubectl config current-context

# Проверка доступности API server
kubectl cluster-info

# Тест подключения
curl -k https://<api-server-url>:6443/healthz
```

**Проблема: Permission denied**
```bash
# Проверка RBAC прав
kubectl auth can-i create pods
kubectl auth can-i create pods --as=user@example.com
kubectl auth can-i '*' '*'  # проверка admin прав
```

**Проблема: Pod не запускается**
```bash
# Диагностика
kubectl get pod my-pod
kubectl describe pod my-pod
kubectl logs my-pod
kubectl get events --sort-by='.lastTimestamp'
```

## Источники
- Официальная документация Kubernetes: kubectl (kubernetes.io/docs/reference/kubectl/)
- kubectl Cheat Sheet (kubernetes.io/docs/reference/kubectl/cheatsheet/)
- Kubernetes Command-Line Book, Kelsey Hightower
- kubectl book (kubectl.docs.kubernetes.io)
