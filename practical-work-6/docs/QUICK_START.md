# Quick Start - Практическая работа 6

**Быстрая шпаргалка для запуска**

---

## 🚀 Быстрый запуск (5 минут)

### 1. Запустить Minikube

```bash
minikube start
```

### 2. Собрать и загрузить образы

```bash
cd practical-work-6

# Собрать образы
docker build -t gribkov/static-files:v1 app/fileserver/
docker build -t gribkov/journal-server:v1 kbp-sample/example-app/

# Загрузить в Minikube
minikube image load gribkov/static-files:v1
minikube image load gribkov/journal-server:v1
```

### 3. Создать ConfigMaps и Secrets

```bash
kubectl create configmap frontend-config --from-literal=journalEntries=10
kubectl create secret generic redis-passwd --from-literal=passwd=$(openssl rand -base64 32)
kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh
```

### 4. Развернуть приложение

```bash
# Redis
kubectl apply -f app/redis/redis.yml
kubectl apply -f app/redis/redis-read.yml
kubectl apply -f app/redis/redis-write.yml

# Frontend
kubectl apply -f app/frontend/frontend.yaml
kubectl apply -f app/frontend/traffic-service.yml

# FileServer
kubectl apply -f app/fileserver/fileserver.yml
kubectl apply -f app/fileserver/fileserver-service.yml
```

### 5. Проверить статус

```bash
# Подождать ~30-60 секунд, затем проверить
kubectl get pods
```

Все поды должны быть в статусе `Running`.

---

## 📋 Демонстрация (копировать команды)

### Показать все ресурсы

```bash
kubectl get all,pvc,configmap,secret
```

### Проверить Redis репликацию

```bash
kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication' 2>/dev/null | grep -E "role|connected_slaves"
```

### Проверить логи Frontend

```bash
kubectl logs deployment/frontend --tail=20
```

### Тестировать Frontend API

**Терминал 1:**
```bash
kubectl port-forward svc/frontend 8085:8080
```

**Терминал 2 (или браузер):**
```bash
curl http://localhost:8085/api/
```

Или открыть в браузере: http://localhost:8085/api/

### Тестировать FileServer

**Остановить предыдущий port-forward (Ctrl+C), затем:**
```bash
kubectl port-forward svc/fileserver 8086:80
```

**Открыть в браузере:** http://localhost:8086/

---

## 🧹 Очистка

```bash
kubectl delete -f app/frontend/ -f app/fileserver/ -f app/redis/
kubectl delete configmap frontend-config redis-config
kubectl delete secret redis-passwd
kubectl delete pvc -l app=redis
```

---

## ✅ Чеклист для демонстрации

Перед показом преподавателю убедиться:

- [ ] `kubectl get pods` - все в Running
- [ ] `kubectl get svc` - 4 сервиса видны
- [ ] `kubectl get pvc` - 3 PVC для Redis
- [ ] Redis репликация: `connected_slaves:2`
- [ ] Frontend логи: "api server up and running"
- [ ] Frontend API отвечает через port-forward
- [ ] FileServer отдает страницу через port-forward

---

## 🔥 Команды для демонстрации (копировать по порядку)

```bash
kubectl get pods -o wide

kubectl get svc

kubectl get statefulset,deployment

kubectl get pvc

kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication' 2>/dev/null | grep -E "role|connected_slaves"

kubectl logs deployment/frontend --tail=30

kubectl logs deployment/fileserver --tail=20

kubectl port-forward svc/frontend 8085:8080

kubectl port-forward svc/fileserver 8086:80
```

**Примечание:**
- После команды `kubectl port-forward svc/frontend 8085:8080` открыть в браузере: http://localhost:8085/api/
- После команды `kubectl port-forward svc/fileserver 8086:80` открыть в браузере: http://localhost:8086/

---

## 💡 Подсказки

- Если под в Pending - проверить `kubectl describe pod <pod-name>`
- Если ImagePullBackOff - убедиться что образы загружены: `minikube image ls | grep gribkov`
- Для следования за логами в реальном времени: `kubectl logs -f <pod-name>`
- Для интерактивного входа в под: `kubectl exec -it <pod-name> -- sh`

---

**Автор:** Грибков А.С. IKBO-16-22
