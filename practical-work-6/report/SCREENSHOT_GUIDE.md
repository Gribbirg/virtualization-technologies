# Гайд по получению скриншотов для отчета

**Практическая работа 6:** Развертывание приложения в Kubernetes
**Автор:** Грибков А.С. ИКБО-16-22

---

## Содержание

1. [Подготовка](#подготовка)
2. [Скриншоты Deployment](#скриншоты-deployment)
3. [Скриншоты Service](#скриншоты-service)
4. [Скриншоты ConfigMap](#скриншоты-configmap)
5. [Скриншоты Secret](#скриншоты-secret)
6. [Скриншоты Redis StatefulSet](#скриншоты-redis-statefulset)
7. [Скриншоты Ingress](#скриншоты-ingress)
8. [Скриншоты проверки работоспособности](#скриншоты-проверки-работоспособности)

---

## Подготовка

Перед получением скриншотов убедитесь, что:

1. Docker запущен (для macOS с Colima):
```bash
colima status
# Если не запущен, запустите:
colima start
```

2. Minikube запущен:
```bash
minikube start
```

3. Docker образы собраны и загружены в Minikube:
```bash
cd practical-work-6
docker build -t gribkov/static-files:v1 app/fileserver/
docker build -t gribkov/journal-server:v1 kbp-sample/example-app/
minikube image load gribkov/static-files:v1
minikube image load gribkov/journal-server:v1
```

**Важно:** Сборка образов должна производиться **после** запуска Docker, но **до** загрузки в Minikube.

---

## Скриншоты Deployment

### Скриншот 1: Применение Deployment для frontend

**Команда:**
```bash
kubectl apply -f app/frontend/frontend.yaml
```

**Что показать на скриншоте:**
- Вывод команды `kubectl apply -f app/frontend/frontend.yaml`
- Сообщение: `deployment.apps/frontend created`

**Дополнительно можно добавить проверку:**
```bash
kubectl get deployment frontend
```

Должно показать:
```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2           Xs
```

---

## Скриншоты Service

### Скриншот 2: Создание Service для frontend и проверка его состояния

**Команды:**
```bash
kubectl apply -f app/frontend/traffic-service.yml
kubectl get svc frontend
```

**Что показать на скриншоте:**
- Вывод применения Service
- Вывод `kubectl get svc frontend` с информацией:
  - NAME: frontend
  - TYPE: ClusterIP
  - CLUSTER-IP: (внутренний IP)
  - PORT(S): 8080/TCP

---

## Скриншоты ConfigMap

### Скриншот 3: Создание ConfigMap и просмотр его содержимого

**Команды:**
```bash
kubectl create configmap frontend-config --from-literal=journalEntries=10
kubectl get configmap frontend-config -o yaml
```

**Что показать на скриншоте:**
- Сообщение: `configmap/frontend-config created`
- Вывод YAML с содержимым ConfigMap, где видно:
  ```yaml
  data:
    journalEntries: "10"
  ```

---

## Скриншоты Secret

### Скриншот 4: Создание Secret для хранения пароля Redis

**Команды:**
```bash
kubectl create secret generic redis-passwd --from-literal=passwd=$(openssl rand -base64 32)
kubectl get secret redis-passwd
```

**Что показать на скриншоте:**
- Сообщение: `secret/redis-passwd created`
- Вывод `kubectl get secret` с информацией о Secret

**Примечание:** Не показывайте содержимое Secret (не используйте `-o yaml`), это конфиденциальные данные.

---

## Скриншоты Redis StatefulSet

### Скриншот 5: Создание ConfigMap с launch.sh скриптом

**Команды:**
```bash
kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh
kubectl get configmap redis-config
```

**Что показать на скриншоте:**
- Сообщение: `configmap/redis-config created`
- Вывод `kubectl get configmap redis-config`

---

### Скриншот 6: Применение StatefulSet для Redis

**Команды:**
```bash
kubectl apply -f app/redis/redis.yml
kubectl get statefulset redis
```

**Что показать на скриншоте:**
- Вывод `kubectl apply -f app/redis/redis.yml`
- Статус StatefulSet с 3 репликами:
  ```
  NAME    READY   AGE
  redis   3/3     Xs
  ```

---

### Скриншот 7: Список PersistentVolumeClaim для подов Redis

**Команда:**
```bash
kubectl get pvc
```

**Что показать на скриншоте:**
- Список из 3 PVC с именами: `data-redis-0`, `data-redis-1`, `data-redis-2`
- Статус каждого: `Bound`
- Размер: `10Gi`

Пример вывода:
```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES
data-redis-0   Bound    pvc-xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx      10Gi       RWO
data-redis-1   Bound    pvc-yyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy      10Gi       RWO
data-redis-2   Bound    pvc-zzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz      10Gi       RWO
```

---

### Скриншот 8: Список всех Service для Redis в кластере

**Команды:**
```bash
kubectl apply -f app/redis/redis-read.yml
kubectl apply -f app/redis/redis-write.yml
kubectl get svc | grep redis
```

**Что показать на скриншоте:**
- Список Service:
  - `redis` (ClusterIP) - для чтения
  - `redis-write` (ClusterIP: None) - Headless Service для записи

---

## Скриншоты FileServer

### Скриншот 9: Развертывание FileServer и создание Service

**Команды:**
```bash
kubectl apply -f app/fileserver/fileserver.yml
kubectl apply -f app/fileserver/fileserver-service.yml
kubectl get deployment fileserver
kubectl get svc fileserver
```

**Что показать на скриншоте:**
- Вывод применения Deployment и Service
- Статус Deployment с 2 репликами
- Service `fileserver` типа ClusterIP на порту 80

---

## Скриншоты Ingress

### Скриншот 10: Включение Ingress addon в Minikube

**Команда:**
```bash
minikube addons enable ingress
```

**Что показать на скриншоте:**
- Вывод команды с сообщением об успешном включении addon
- Примерно: `✅  ingress is enabled`

---

### Скриншот 11: Применение Ingress и проверка его состояния

**Команды:**
```bash
kubectl apply -f app/frontend/ingress.yaml
kubectl get ingress
```

**Что показать на скриншоте:**
- Вывод `kubectl apply`
- Информация об Ingress с правилами маршрутизации:
  ```
  NAME               CLASS   HOSTS   ADDRESS         PORTS   AGE
  frontend-ingress   nginx   *       192.168.49.2    80      Xs
  ```

---

## Скриншоты проверки работоспособности

### Скриншот 12: Список всех ресурсов в кластере Kubernetes

**Команда:**
```bash
kubectl get all
```

**Что показать на скриншоте:**
- Полный список всех ресурсов:
  - Pods (frontend, redis-0/1/2, fileserver)
  - Services (kubernetes, frontend, redis, redis-write, fileserver)
  - Deployments (frontend, fileserver)
  - StatefulSets (redis)
  - ReplicaSets

Все поды должны быть в состоянии `Running` с `READY 1/1`.

---

### Скриншот 13: Проверка роли Redis Master (redis-0)

**Команда:**
```bash
kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication'
```

**Что показать на скриншоте:**
- Вывод команды с информацией:
  ```
  # Replication
  role:master
  connected_slaves:2
  slave0:ip=...,port=6379,state=online,offset=...
  slave1:ip=...,port=6379,state=online,offset=...
  ```

**Важно:** Должно быть видно `role:master` и `connected_slaves:2`.

---

### Скриншот 14: Проверка роли Redis Slave (redis-1)

**Команда:**
```bash
kubectl exec redis-1 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication'
```

**Что показать на скриншоте:**
- Вывод команды с информацией:
  ```
  # Replication
  role:slave
  master_host:redis-0.redis
  master_port:6379
  master_link_status:up
  ```

**Важно:** Должно быть видно `role:slave` и `master_link_status:up`.

---

### Скриншот 15: GET-запрос к API для получения списка записей журнала

**Подготовка:**
```bash
kubectl port-forward svc/frontend 8080:8080 &
```

**Способ 1: Через curl**
```bash
curl http://localhost:8080/api
```

**Способ 2: Через браузер (рекомендуется для отчета)**
- Открыть в браузере: `http://localhost:8080/api`

**Что показать на скриншоте:**
- JSON ответ с массивом записей журнала
- Пример:
  ```json
  [
    {
      "id": "1",
      "message": "Test entry",
      "timestamp": "2025-11-17T..."
    }
  ]
  ```

---

### Скриншот 16: POST-запрос к API для добавления новой записи

**Команда через curl:**
```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"message": "Test from report"}'
```

**Способ 2: Через Postman или браузерные инструменты разработчика**

**Что показать на скриншоте:**
- Успешный ответ с добавленной записью
- HTTP статус 200/201
- Или можно показать результат повторного GET-запроса с новой записью

---

### Скриншот 17: Доступ к статическому серверу через браузер

**Подготовка:**
```bash
kubectl port-forward svc/fileserver 8081:80 &
```

**Способ 1: Через curl**
```bash
curl http://localhost:8081/
```

**Способ 2: Через браузер (рекомендуется для отчета)**
- Открыть в браузере: `http://localhost:8081/`

**Что показать на скриншоте:**
- HTML страницу с текстом "My Static App"
- Адресная строка браузера с `http://localhost:8081/`

---

## Дополнительные полезные команды для скриншотов

### Проверка подов
```bash
kubectl get pods -o wide
```

Показывает поды с дополнительной информацией (IP адреса, ноды).

### Просмотр логов
```bash
kubectl logs frontend-<pod-id>
kubectl logs redis-0
```

### Описание ресурсов
```bash
kubectl describe deployment frontend
kubectl describe statefulset redis
kubectl describe ingress frontend-ingress
```

### Dashboard (опционально)
```bash
minikube dashboard
```

Можно сделать скриншоты из веб-интерфейса Kubernetes Dashboard.

---

## Советы по оформлению скриншотов

1. **Размер окна терминала:** Используйте достаточно широкое окно, чтобы вывод не переносился некрасиво
2. **Шрифт:** Используйте читаемый размер шрифта (не слишком мелкий)
3. **Цветовая схема:** Лучше использовать светлую тему для отчета (читабельнее при печати)
4. **Обрезка:** Обрезайте скриншоты, оставляя только релевантную информацию
5. **Нумерация:** Скриншоты уже пронумерованы в соответствии с порядком в отчете
6. **Формат:** PNG или JPEG с хорошим качеством

---

## Быстрая последовательность для всех скриншотов

Если нужно быстро получить все скриншоты подряд:

```bash
# 0. Запуск Docker (для macOS с Colima)
colima start

# 1. Подготовка
cd practical-work-6
minikube start

# 2. Сборка и загрузка образов
docker build -t gribkov/static-files:v1 app/fileserver/
docker build -t gribkov/journal-server:v1 kbp-sample/example-app/
minikube image load gribkov/static-files:v1
minikube image load gribkov/journal-server:v1

# 3. ConfigMaps и Secrets
kubectl create configmap frontend-config --from-literal=journalEntries=10
kubectl create secret generic redis-passwd --from-literal=passwd=$(openssl rand -base64 32)
kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh

# 4. Deployments и Services (скриншоты после каждой команды)
kubectl apply -f app/redis/redis.yml
kubectl apply -f app/redis/redis-read.yml
kubectl apply -f app/redis/redis-write.yml
kubectl apply -f app/frontend/frontend.yaml
kubectl apply -f app/frontend/traffic-service.yml
kubectl apply -f app/fileserver/fileserver.yml
kubectl apply -f app/fileserver/fileserver-service.yml

# 5. Ingress
minikube addons enable ingress
kubectl apply -f app/frontend/ingress.yaml

# 6. Проверки
kubectl get all
kubectl get pvc
kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication'
kubectl exec redis-1 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication'

# 7. Port-forward и тестирование API
kubectl port-forward svc/frontend 8080:8080 &
kubectl port-forward svc/fileserver 8081:80 &

# Откройте браузер на http://localhost:8080/api и http://localhost:8081/
```

---

## Автоматизированное тестирование

Для более детального тестирования используйте:

```bash
./test/run_tests.sh
```

Или смотрите: [test/API_TESTING.md](../test/API_TESTING.md)

---

**Удачи в подготовке отчета!**
