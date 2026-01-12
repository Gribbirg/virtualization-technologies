# Опишите задачи и процессы управления кластером Kubernetes

## Краткий ответ
Управление кластером Kubernetes включает: **управление узлами** (добавление, удаление, обновление), **обновление версий** (Control Plane и узлов), **мониторинг и логирование** (метрики, алертинг), **backup и восстановление** (etcd, persistent data), **управление ресурсами** (квоты, лимиты), **безопасность** (RBAC, Network Policies, secrets) и **масштабирование** (горизонтальное и вертикальное). Эти процессы обеспечивают надёжность, безопасность и производительность кластера.

## Развёрнутый ответ

### 1. Управление жизненным циклом кластера

#### Создание и инициализация кластера

**Задачи:**
- Выбор подходящего решения для развёртывания
- Планирование архитектуры (количество узлов, топология)
- Настройка сети и хранилища
- Конфигурация безопасности

**Процесс с kubeadm:**
```bash
# 1. Инициализация Control Plane
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint="lb.example.com:6443" \
  --upload-certs

# 2. Настройка kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

# 3. Установка CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 4. Добавление worker узлов
kubeadm join lb.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

**High Availability конфигурация:**
- Несколько control plane узлов (нечётное число: 3, 5)
- Load balancer перед API servers
- etcd cluster (отдельный или co-located)
- Резервирование компонентов

#### Обновление кластера

**Стратегия обновления:**
1. Обновление Control Plane
2. Обновление узлов
3. Обновление аддонов и компонентов

**Процесс обновления (kubeadm):**

**Шаг 1: Обновление первого Control Plane узла**
```bash
# Обновление kubeadm
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.28.0-00
apt-mark hold kubeadm

# Проверка плана обновления
sudo kubeadm upgrade plan

# Применение обновления
sudo kubeadm upgrade apply v1.28.0

# Drain узла
kubectl drain <control-plane-node> --ignore-daemonsets

# Обновление kubelet и kubectl
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
apt-mark hold kubelet kubectl

# Перезапуск kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Uncordon узла
kubectl uncordon <control-plane-node>
```

**Шаг 2: Обновление дополнительных Control Plane узлов**
```bash
sudo kubeadm upgrade node
# Далее те же шаги drain, обновление, uncordon
```

**Шаг 3: Обновление Worker узлов**
```bash
# На каждом worker узле
kubectl drain <worker-node> --ignore-daemonsets
apt-mark unhold kubeadm kubelet kubectl
apt-get update && apt-get install -y kubeadm=1.28.0-00 kubelet=1.28.0-00 kubectl=1.28.0-00
apt-mark hold kubeadm kubelet kubectl
sudo kubeadm upgrade node
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon <worker-node>
```

**Best Practices для обновления:**
- Всегда читайте release notes
- Тестируйте обновление в dev/staging
- Обновляйте по одной minor версии за раз
- Делайте backup etcd перед обновлением
- Планируйте maintenance window
- Обновляйте узлы постепенно для минимизации простоя

#### Масштабирование кластера

**Добавление узлов:**
```bash
# Генерация нового токена (на control plane)
kubeadm token create --print-join-command

# Выполнение команды на новом узле
sudo kubeadm join <endpoint> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

**Удаление узлов:**
```bash
# 1. Drain узла (переместить Pod)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 2. Удалить узел из кластера
kubectl delete node <node-name>

# 3. На удаляемом узле
sudo kubeadm reset
```

**Автоматическое масштабирование:**

*Cluster Autoscaler:*
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --cloud-provider=aws
        - --nodes=1:10:k8s-worker-asg
```

### 2. Мониторинг и наблюдаемость

#### Мониторинг компонентов

**Control Plane мониторинг:**
```bash
# Проверка статуса компонентов
kubectl get componentstatuses  # deprecated в 1.19+
kubectl get --raw='/readyz?verbose'

# Проверка узлов
kubectl get nodes
kubectl describe node <node-name>

# Проверка статуса Pod системных компонентов
kubectl get pods -n kube-system
```

**Metrics Server:**
```bash
# Установка
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Использование
kubectl top nodes
kubectl top pods -A
kubectl top pods -n default --sort-by=memory
```

**Prometheus Stack:**
```bash
# Установка через Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Доступ к Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Ключевые метрики для мониторинга:**

*Узлы:*
- CPU utilization
- Memory utilization
- Disk usage и I/O
- Network throughput
- Node condition (Ready, MemoryPressure, DiskPressure)

*Control Plane:*
- API server latency и throughput
- etcd latency и операции
- Scheduler latency
- Controller manager работоспособность

*Приложения:*
- Pod restarts
- Resource utilization
- Request/error rates
- Latency

#### Логирование

**Централизованное логирование:**

*EFK Stack (Elasticsearch, Fluentd, Kibana):*
```bash
# Установка через Helm
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch -n logging --create-namespace
helm install kibana elastic/kibana -n logging
helm install fluentd fluent/fluentd -n logging
```

*Loki Stack:*
```bash
# Более легковесная альтернатива
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack -n logging --create-namespace
```

**Просмотр логов:**
```bash
# Логи Pod
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous  # предыдущий контейнер
kubectl logs -f <pod-name>  # follow

# Логи всех Pod с label
kubectl logs -l app=nginx

# Логи узлов (на узле)
journalctl -u kubelet
journalctl -u containerd
```

#### Алертинг

**Prometheus Alertmanager:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes
    rules:
    - alert: NodeNotReady
      expr: kube_node_status_condition{condition="Ready",status="true"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ $labels.node }} is not ready"

    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"

    - alert: HighMemoryUsage
      expr: (sum(container_memory_usage_bytes) by (node) / sum(kube_node_status_allocatable{resource="memory"}) by (node)) > 0.9
      for: 5m
      labels:
        severity: warning
```

### 3. Backup и восстановление

#### Backup etcd

**Важность:**
- etcd содержит всё состояние кластера
- Регулярные backup критически важны
- Автоматизация backup обязательна

**Процесс backup:**
```bash
# Установка etcdctl
ETCD_VER=v3.5.9
curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd.tar.gz
tar xzvf /tmp/etcd.tar.gz -C /tmp
sudo mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/

# Создание snapshot
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Проверка snapshot
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table
```

**Автоматизация backup:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
spec:
  schedule: "0 */6 * * *"  # каждые 6 часов
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: etcd-backup
            image: k8s.gcr.io/etcd:3.5.9
            command:
            - /bin/sh
            - -c
            - |
              etcdctl snapshot save /backup/etcd-$(date +%Y%m%d-%H%M%S).db \
                --endpoints=https://127.0.0.1:2379 \
                --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                --cert=/etc/kubernetes/pki/etcd/server.crt \
                --key=/etc/kubernetes/pki/etcd/server.key
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/kubernetes/pki/etcd
              readOnly: true
            - name: backup
              mountPath: /backup
          volumes:
          - name: etcd-certs
            hostPath:
              path: /etc/kubernetes/pki/etcd
          - name: backup
            persistentVolumeClaim:
              claimName: etcd-backup-pvc
          restartPolicy: OnFailure
```

**Восстановление из backup:**
```bash
# 1. Остановить API server
sudo systemctl stop kube-apiserver

# 2. Восстановить данные
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore \
  --initial-cluster=etcd-0=https://10.0.0.1:2380 \
  --initial-advertise-peer-urls=https://10.0.0.1:2380

# 3. Заменить data directory
sudo mv /var/lib/etcd /var/lib/etcd.old
sudo mv /var/lib/etcd-restore /var/lib/etcd

# 4. Запустить etcd и API server
sudo systemctl start etcd
sudo systemctl start kube-apiserver
```

#### Backup приложений

**Velero (formerly Ark):**
```bash
# Установка CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xvf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# Установка в кластер (AWS example)
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket velero-backups \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1 \
  --secret-file ./credentials-velero

# Создание backup
velero backup create my-backup --include-namespaces default,production

# Scheduled backup
velero schedule create daily-backup --schedule="@daily" --include-namespaces default

# Восстановление
velero restore create --from-backup my-backup
```

### 4. Управление ресурсами

#### Resource Quotas

**Определение квот namespace:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    limits.cpu: "200"
    limits.memory: 400Gi
    persistentvolumeclaims: "50"
    requests.storage: "500Gi"
```

**Проверка использования:**
```bash
kubectl describe resourcequota -n production
kubectl get resourcequota -n production -o yaml
```

#### LimitRange

**Установка лимитов по умолчанию:**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:  # default limits
      cpu: 500m
      memory: 512Mi
    defaultRequest:  # default requests
      cpu: 100m
      memory: 128Mi
    max:  # максимум на контейнер
      cpu: "2"
      memory: 2Gi
    min:  # минимум на контейнер
      cpu: 50m
      memory: 64Mi
    type: Container
  - max:  # максимум на Pod
      cpu: "4"
      memory: 4Gi
    type: Pod
```

### 5. Безопасность

#### RBAC (Role-Based Access Control)

**Создание Role:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

**RoleBinding:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**ClusterRole для кластерных ресурсов:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
```

#### Network Policies

**Изоляция трафика:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

#### Управление Secrets

**Создание секретов:**
```bash
# Из literal
kubectl create secret generic db-password --from-literal=password=supersecret

# Из файла
kubectl create secret generic tls-cert --from-file=tls.crt --from-file=tls.key

# TLS secret
kubectl create secret tls my-tls-secret --cert=path/to/tls.crt --key=path/to/tls.key
```

**Encryption at rest:**
```yaml
# /etc/kubernetes/enc/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64 encoded secret>
      - identity: {}
```

### 6. Отладка и troubleshooting

**Диагностика узлов:**
```bash
# Статус узлов
kubectl get nodes
kubectl describe node <node-name>

# События
kubectl get events --sort-by='.lastTimestamp'

# Ресурсы
kubectl top nodes
```

**Диагностика Pod:**
```bash
# Статус и события
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>

# Логи
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -c <container-name>

# Выполнение команд
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec <pod-name> -- cat /etc/resolv.conf

# Копирование файлов
kubectl cp <pod-name>:/path/to/file ./local-file
```

**Проверка сети:**
```bash
# DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
```

### 7. Управление конфигурацией

**GitOps подход:**
- Использование ArgoCD или Flux
- Декларативное управление через Git
- Автоматическая синхронизация

**Helm для управления релизами:**
```bash
# Установка приложения
helm install my-app ./my-chart -n production

# Обновление
helm upgrade my-app ./my-chart -n production

# Откат
helm rollback my-app 1 -n production

# История
helm history my-app -n production
```

## Источники
- Официальная документация Kubernetes: Administration (kubernetes.io/docs/tasks/administer-cluster/)
- Kubernetes Best Practices, Brendan Burns
- Production Kubernetes, Josh Rosso
- Managing Kubernetes, Brendan Burns, Craig Tracey
