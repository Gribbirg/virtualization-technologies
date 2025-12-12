# Гайд по демонстрации Практической работы 6

**Автор:** Грибков А.С. ИКБО-16-22
**Дата:** 17.11.2025

---

## Быстрое тестирование

Для автоматизированного тестирования API используйте готовые скрипты:

```bash
cd practical-work-6

./test/run_tests.sh
```

Или смотрите подробное руководство: [test/API_TESTING.md](test/API_TESTING.md)

---

## Подготовка к демонстрации

### Шаг 1: Запуск Minikube

```bash
# Запустить Minikube кластер
minikube start

# Проверить статус
minikube status

# Проверить подключение к кластеру
kubectl cluster-info
```

**Ожидаемый результат:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

## Сборка Docker образов

### Шаг 2: Сборка образов приложения

```bash
# Перейти в директорию проекта
cd practical-work-6

# Собрать образ статического файлового сервера
docker build -t gribkov/static-files:v1 app/fileserver/

# Собрать образ frontend сервера (journal-server)
docker build -t gribkov/journal-server:v1 kbp-sample/example-app/

# Проверить созданные образы
docker images | grep gribkov
```

**Ожидаемый результат:**
```
gribkov/static-files     v1      <image-id>   <time>   <size>
gribkov/journal-server   v1      <image-id>   <time>   <size>
```

### Шаг 3: Загрузка образов в Minikube

```bash
# Загрузить образы в Minikube
minikube image load gribkov/static-files:v1
minikube image load gribkov/journal-server:v1

# Проверить образы в Minikube
minikube image ls | grep gribkov
```

**Ожидаемый результат:**
```
docker.io/gribkov/static-files:v1
docker.io/gribkov/journal-server:v1
```

---

## Развертывание приложения в Kubernetes

### Шаг 4: Создание ConfigMaps и Secrets

```bash
# Создать ConfigMap для frontend конфигурации
kubectl create configmap frontend-config --from-literal=journalEntries=10

# Создать Secret для Redis пароля
kubectl create secret generic redis-passwd --from-literal=passwd=$(openssl rand -base64 32)

# Создать ConfigMap для Redis launch скрипта
kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh

# Проверить созданные ресурсы
kubectl get configmap
kubectl get secret
```

**Ожидаемый результат:**
```
NAME               DATA   AGE
frontend-config    1      <time>
redis-config       1      <time>

NAME           TYPE     DATA   AGE
redis-passwd   Opaque   1      <time>
```

### Шаг 5: Развертывание Redis StatefulSet

```bash
# Развернуть Redis StatefulSet
kubectl apply -f app/redis/redis.yml

# Развернуть Redis Services
kubectl apply -f app/redis/redis-read.yml
kubectl apply -f app/redis/redis-write.yml

# Проверить статус Redis подов (подождите ~30-60 секунд)
kubectl get pods -l app=redis -w
# Нажмите Ctrl+C когда все поды станут Running
```

**Ожидаемый результат:**
```
NAME      READY   STATUS    RESTARTS   AGE
redis-0   1/1     Running   0          <time>
redis-1   1/1     Running   0          <time>
redis-2   1/1     Running   0          <time>
```

### Шаг 6: Развертывание Frontend

```bash
# Развернуть Frontend Deployment
kubectl apply -f app/frontend/frontend.yaml

# Развернуть Frontend Service
kubectl apply -f app/frontend/traffic-service.yml

# Проверить статус Frontend подов
kubectl get pods -l app=frontend
```

**Ожидаемый результат:**
```
NAME                        READY   STATUS    RESTARTS   AGE
frontend-<hash>-<id>        1/1     Running   0          <time>
frontend-<hash>-<id>        1/1     Running   0          <time>
```

### Шаг 7: Развертывание FileServer

```bash
# Развернуть FileServer Deployment
kubectl apply -f app/fileserver/fileserver.yml

# Развернуть FileServer Service
kubectl apply -f app/fileserver/fileserver-service.yml

# Проверить статус FileServer подов
kubectl get pods -l app=fileserver
```

**Ожидаемый результат:**
```
NAME                          READY   STATUS    RESTARTS   AGE
fileserver-<hash>-<id>        1/1     Running   0          <time>
fileserver-<hash>-<id>        1/1     Running   0          <time>
```

---

## Демонстрация конфигураций в Minikube

### Шаг 8: Показать все ресурсы

```bash
# Показать все поды
kubectl get pods -o wide

# Показать все сервисы
kubectl get services

# Показать все deployments и statefulsets
kubectl get deployments,statefulsets

# Показать PersistentVolumeClaims
kubectl get pvc

# Показать все ресурсы одной командой
kubectl get all,pvc,configmap,secret
```

**Что показать преподавателю:**
- ✅ 2 пода Frontend (Running)
- ✅ 2 пода FileServer (Running)
- ✅ 3 пода Redis (Running) - StatefulSet
- ✅ 4 сервиса (frontend, fileserver, redis, redis-write)
- ✅ 3 PersistentVolumeClaims для Redis
- ✅ 2 ConfigMaps (frontend-config, redis-config)
- ✅ 1 Secret (redis-passwd)

### Шаг 9: Показать детальную информацию о компонентах

```bash
# Показать детали Frontend Deployment
kubectl describe deployment frontend

# Показать детали Redis StatefulSet
kubectl describe statefulset redis

# Показать детали одного из подов
kubectl describe pod redis-0

# Показать используемые образы
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

**Что обратить внимание:**
- ✅ Образы `gribkov/journal-server:v1` и `gribkov/static-files:v1`
- ✅ imagePullPolicy: Never (используются локальные образы)
- ✅ Resources requests и limits настроены
- ✅ Volumes и VolumeMounts для secrets и configmaps

---

## Проверка работоспособности Redis репликации

### Шаг 10: Проверить Redis Master-Slave репликацию

```bash
# Проверить статус репликации на Master (redis-0)
kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication' 2>/dev/null | grep -E "role|connected_slaves"

# Проверить статус Slave (redis-1)
kubectl exec redis-1 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication' 2>/dev/null | grep -E "role|master_host"
```

**Ожидаемый результат:**
```
# На redis-0 (Master):
role:master
connected_slaves:2

# На redis-1 (Slave):
role:slave
master_host:redis-0.redis
```

**Что показать преподавателю:**
- ✅ Redis-0 является Master
- ✅ 2 Slave подключены к Master
- ✅ Репликация работает корректно

---

## Демонстрация работоспособности Frontend

### Шаг 11: Проверить логи Frontend

```bash
# Показать логи Frontend
kubectl logs deployment/frontend --tail=50

# Показать логи в реальном времени
kubectl logs -f deployment/frontend
# Нажмите Ctrl+C для остановки
```

**Ожидаемый результат:**
```
api server up and running.
```

### Шаг 12: Протестировать Frontend через port-forward

```bash
# Создать port-forward для доступа к Frontend (в фоновом режиме)
kubectl port-forward svc/frontend 8085:8080 &

# Проверить API endpoint (получить список записей)
curl http://localhost:8085/api

# Добавить запись в журнал
curl -X POST http://localhost:8085/api -H "Content-Type: application/json" -d '{"text":"Test entry from demo"}'

# Получить обновленный список записей
curl http://localhost:8085/api
```

**Или открыть в браузере:**
```
http://localhost:8085/api
```

**Ожидаемый результат:**
```json
[]
```
Или массив JSON объектов, если записи были добавлены.

**Что показать преподавателю:**
- ✅ Frontend отвечает на запросы
- ✅ API возвращает JSON с записями журнала
- ✅ Можно добавлять новые записи через POST запросы
- ✅ Данные сохраняются в Redis

### Шаг 13: Проверить FileServer

```bash
# Создать port-forward для FileServer (в фоновом режиме)
kubectl port-forward svc/fileserver 8086:80 &

# Проверить через curl
curl http://localhost:8086/
```

**В браузере открыть:**
```
http://localhost:8086/
```

**Ожидаемый результат:**
```html
<html>
    <body>
        <h1>My Static App</h1>
    </body>
</html>
```

- ✅ Отображается страница "My Static App"
- ✅ NGINX корректно раздает статические файлы

### Шаг 14: Настроить Ingress и доступ через minikube tunnel

```bash
# Включить Ingress addon в Minikube
minikube addons enable ingress

# Развернуть Ingress
kubectl apply -f app/frontend/ingress.yaml

# Проверить статус Ingress
kubectl get ingress

# Для доступа к Ingress на localhost:80 запустить tunnel (требует sudo)
minikube tunnel
```

**Ожидаемый результат:**
```
NAME               CLASS   HOSTS   ADDRESS        PORTS   AGE
frontend-ingress   nginx   *       192.168.49.2   80      <time>
```

**Доступ через Ingress:**
- После запуска `minikube tunnel` можно открыть:
  - `http://127.0.0.1/` - статические файлы (FileServer)
  - `http://127.0.0.1/api` - API (Frontend)

**Примечание:** `minikube tunnel` требует sudo-прав для портов 80/443. Если не хотите использовать sudo, продолжайте работать через port-forward.

### Шаг 15: Проверить логи всех компонентов

```bash
# Показать логи FileServer
kubectl logs deployment/fileserver --tail=20

# Показать логи Redis
kubectl logs redis-0 --tail=20
kubectl logs redis-1 --tail=20

# Показать события в кластере
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

---

## Дополнительные проверки

### Шаг 15: Показать работу с данными в Redis

```bash
# Подключиться к Redis и выполнить команды
kubectl exec -it redis-0 -- sh

# Внутри пода Redis:
redis-cli -a $(cat /etc/redis-passwd/passwd)

# В redis-cli выполнить:
PING                    # Должен ответить PONG
KEYS *                  # Показать все ключи
GET <key>               # Получить значение ключа (если есть)
INFO replication        # Информация о репликации
exit

# Выйти из пода
exit
```

### Шаг 16: Масштабирование (опционально)

```bash
# Увеличить количество реплик Frontend
kubectl scale deployment frontend --replicas=3

# Проверить новое количество подов
kubectl get pods -l app=frontend

# Вернуть к исходному количеству
kubectl scale deployment frontend --replicas=2
```

---

## Очистка ресурсов (после демонстрации)

### Шаг 17: Удаление всех ресурсов

```bash
# Удалить все Deployments и Services
kubectl delete -f app/frontend/
kubectl delete -f app/fileserver/
kubectl delete -f app/redis/

# Удалить ConfigMaps и Secrets
kubectl delete configmap frontend-config redis-config
kubectl delete secret redis-passwd

# Удалить PersistentVolumeClaims
kubectl delete pvc -l app=redis

# Проверить, что все удалено
kubectl get all,pvc,configmap,secret | grep -E "frontend|fileserver|redis"
```

**Ожидаемый результат:**
```
Все ресурсы удалены!
```

---

## Краткий чеклист для демонстрации

### ✅ Перед демонстрацией:

1. ☐ Minikube запущен (`minikube start`)
2. ☐ Docker образы собраны
3. ☐ Образы загружены в Minikube
4. ☐ Все компоненты развернуты
5. ☐ Все поды в статусе Running

### ✅ Во время демонстрации показать:

**Конфигурации в Minikube:**
1. ☐ `kubectl get all -o wide` - все ресурсы
2. ☐ `kubectl get pvc` - PersistentVolumeClaims для Redis
3. ☐ `kubectl get configmap,secret` - конфигурации
4. ☐ `kubectl describe statefulset redis` - детали Redis StatefulSet
5. ☐ `kubectl describe deployment frontend` - детали Frontend Deployment
6. ☐ Используемые образы с фамилией Gribkov

**Работоспособность Frontend:**
7. ☐ `kubectl logs deployment/frontend` - логи показывают "api server up and running"
8. ☐ `kubectl port-forward svc/frontend 8085:8080` + `curl http://localhost:8085/api/`
9. ☐ Демонстрация в браузере
10. ☐ POST запрос для добавления записи
11. ☐ GET запрос показывает сохраненные данные

**Работоспособность FileServer:**
12. ☐ `kubectl logs deployment/fileserver` - NGINX запущен
13. ☐ `kubectl port-forward svc/fileserver 8086:80` + открыть в браузере
14. ☐ Страница "My Static App" отображается

**Redis репликация:**
15. ☐ `kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) INFO replication'`
16. ☐ Показать Master (redis-0) с 2 подключенными Slaves
17. ☐ Проверить один из Slaves

---

## Типичные вопросы преподавателя и ответы

**Q: Почему используется StatefulSet для Redis?**
A: StatefulSet обеспечивает постоянные имена подов (redis-0, redis-1, redis-2) и PersistentVolumes, что критично для stateful приложений с репликацией.

**Q: Как работает ConfigMap и Secret?**
A: ConfigMap хранит конфигурацию (journalEntries, launch.sh), Secret хранит чувствительные данные (пароль Redis). Они монтируются в поды как volumes или переменные окружения.

**Q: Почему не используется Ingress?**
A: В демонстрации используется port-forward для простоты. В production среде следует использовать Ingress для маршрутизации HTTP трафика.

**Q: Что такое imagePullPolicy: Never?**
A: Указывает Kubernetes использовать только локальные образы из Minikube, не пытаясь загружать их из Docker Hub.

**Q: Как данные сохраняются между перезапусками?**
A: Redis использует PersistentVolumeClaims, которые сохраняют данные на диске даже при перезапуске подов.

---

## Troubleshooting

### Проблема: Поды в состоянии Pending

```bash
kubectl describe pod <pod-name>
# Проверить Events на наличие ошибок с ресурсами
```

**Решение:** Уменьшить resources requests в манифестах

### Проблема: ImagePullBackOff

```bash
kubectl describe pod <pod-name>
# Проверить imagePullPolicy и доступность образа
minikube image ls | grep gribkov
```

**Решение:** Убедиться, что imagePullPolicy: Never и образы загружены в Minikube

### Проблема: Redis не стартует

```bash
kubectl logs redis-0
kubectl describe statefulset redis
```

**Решение:** Проверить наличие ConfigMap redis-config и Secret redis-passwd

---

## Полезные команды для быстрой проверки

```bash
# Одна команда для проверки всего
kubectl get pods,svc,statefulset,deployment,pvc

# Проверить состояние всех подов
kubectl get pods --all-namespaces | grep -v Running

# Получить IP адреса всех подов
kubectl get pods -o wide

# Следить за изменениями в реальном времени
watch kubectl get pods
```

---

**Удачи на демонстрации! 🚀**

_Автор: Грибков А.С. ИКБО-16-22_
