# Гайд по получению скриншотов для отчета

**Практическая работа 7:** Управление ресурсами в Kubernetes
**Автор:** Грибков А.С. ИКБО-16-22

---

## Содержание

1. [Подготовка](#подготовка)
2. [Скриншоты запуска сервера метрик](#скриншоты-запуска-сервера-метрик)
3. [Скриншоты создания namespace](#скриншоты-создания-namespace)
4. [Скриншоты управления памятью](#скриншоты-управления-памятью)
5. [Скриншоты управления CPU](#скриншоты-управления-cpu)
6. [Быстрая последовательность команд](#быстрая-последовательность-команд)

---

## Подготовка

Перед получением скриншотов убедитесь, что:

1. Minikube запущен:
```bash
minikube start
```

2. Находитесь в директории практической работы:
```bash
cd practical-work-7
```

**Важно:** Все команды должны выполняться после полного запуска Minikube.

---

## Скриншоты запуска сервера метрик

### Скриншот 1: Включение аддона metrics-server в Minikube

**Команда:**
```bash
minikube addons enable metrics-server
```

**Что показать на скриншоте:**
- Вывод команды с сообщением об успешном включении аддона
- Примерно: `✅ metrics-server was successfully enabled`

**Примечание:** Если аддон уже включен, будет сообщение: `🌟 The 'metrics-server' addon is already enabled`

---

### Скриншот 2: Проверка доступности API метрик

**Команда:**
```bash
kubectl get apiservices | grep metrics
```

**Что показать на скриншоте:**
- Строка с `v1beta1.metrics.k8s.io`
- Статус должен быть `True` или `Available`

**Альтернативная команда для более полной информации:**
```bash
kubectl get apiservices v1beta1.metrics.k8s.io
```

**Ожидаемый вывод:**
```
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        Xs
```

---

## Скриншоты создания namespace

### Скриншот 3: Создание пространства имён

**Команда:**
```bash
kubectl create namespace gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- Сообщение: `namespace/gribkov-as-ikbo-16-22 created`

**Проверка создания (можно добавить на тот же скриншот):**
```bash
kubectl get namespace gribkov-as-ikbo-16-22
```

---

## Скриншоты управления памятью

### Скриншот 4: Создание Pod с ограничениями памяти

**Команды:**
```bash
kubectl apply -f memory-request-limit.yaml
```

**Что показать на скриншоте:**
- Вывод: `pod/memory-demo created`

**Дополнительно можно добавить:**
```bash
kubectl get pod memory-demo --namespace=gribkov-as-ikbo-16-22
```

Должно показать:
```
NAME          READY   STATUS    RESTARTS   AGE
memory-demo   1/1     Running   0          Xs
```

---

### Скриншот 5: Статус Pod memory-demo

**Команда:**
```bash
kubectl get pod memory-demo --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: memory-demo
- READY: 1/1
- STATUS: Running
- RESTARTS: 0

---

### Скриншот 6: Детальная информация о ресурсах Pod

**Команда:**
```bash
kubectl get pod memory-demo --output=yaml --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "resources:"
```

**Что показать на скриншоте:**
- Секция resources с:
  ```yaml
  resources:
    limits:
      memory: 200Mi
    requests:
      memory: 100Mi
  ```

**Альтернативная команда (более читаемый вывод):**
```bash
kubectl describe pod memory-demo --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Limits:"
```

---

### Скриншот 7: Метрики использования памяти Pod memory-demo

**Команда:**
```bash
kubectl top pod memory-demo --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: memory-demo
- CPU(cores): значение
- MEMORY(bytes): должно быть близко к 150Mi

**Примечание:** Подождите 20-30 секунд после создания пода, чтобы metrics-server успел собрать данные. Если команда выдает ошибку "metrics not available yet", подождите еще немного.

---

### Скриншот 8: Создание Pod, превышающего лимит памяти

**Команда:**
```bash
kubectl apply -f memory-request-limit-2.yaml
```

**Что показать на скриншоте:**
- Вывод: `pod/memory-demo-2 created`

---

### Скриншот 9: Статус Pod в состоянии CrashLoopBackOff

**Команда:**
```bash
kubectl get pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: memory-demo-2
- READY: 0/1
- STATUS: OOMKilled или CrashLoopBackOff
- RESTARTS: 1 или больше

**Примечание:** Подождите 30-60 секунд после создания пода, чтобы увидеть статус CrashLoopBackOff. Сначала может быть статус "Running", затем "OOMKilled", затем "CrashLoopBackOff". Выполните команду несколько раз.

---

### Скриншот 10: Детальная информация о завершении контейнера с OOMKilled

**Команда:**
```bash
kubectl get pod memory-demo-2 --output=yaml --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "lastState:"
```

**Что показать на скриншоте:**
- Секция lastState с:
  ```yaml
  terminated:
    exitCode: 137
    reason: OOMKilled
  ```

**Альтернативная команда:**
```bash
kubectl describe pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Last State:"
```

---

### Скриншот 11: Информация о событиях OOMKilling на ноде

**Команда:**
```bash
kubectl describe nodes | grep -i -A 5 "OOMKilling"
```

**Что показать на скриншоте:**
- Строка с: `Warning OOMKilling Memory cgroup out of memory`
- Информация о процессе, который был убит

**Альтернативная команда (если первая не дает результата):**
```bash
kubectl describe pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Events:"
```

---

### Скриншот 12: Создание Pod с недостижимым запросом памяти

**Команда:**
```bash
kubectl apply -f memory-request-limit-3.yaml
```

**Что показать на скриншоте:**
- Вывод: `pod/memory-demo-3 created`

---

### Скриншот 13: Статус Pod в состоянии Pending

**Команда:**
```bash
kubectl get pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: memory-demo-3
- READY: 0/1
- STATUS: Pending
- RESTARTS: 0
- AGE: сколько времени прошло

**Примечание:** Этот статус останется постоянным, так как pod не может быть запланирован.

---

### Скриншот 14: События Pod с ошибкой планирования

**Команда:**
```bash
kubectl describe pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Events:"
```

**Что показать на скриншоте:**
- События с типом Warning
- Reason: FailedScheduling
- Message: `No nodes are available that match all of the following predicates:: Insufficient memory (3).`

**Полная команда для детального просмотра:**
```bash
kubectl describe pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22
```

---

## Скриншоты управления CPU

### Скриншот 15: Создание Pod с ограничениями CPU

**Команды:**
```bash
kubectl apply -f cpu-request-limit.yaml
```

**Что показать на скриншоте:**
- Вывод: `pod/cpu-demo created`

**Проверка (можно на том же скриншоте):**
```bash
kubectl get pod cpu-demo --namespace=gribkov-as-ikbo-16-22
```

---

### Скриншот 16: Статус Pod cpu-demo

**Команда:**
```bash
kubectl get pod cpu-demo --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: cpu-demo
- READY: 1/1
- STATUS: Running
- RESTARTS: 0

---

### Скриншот 17: Детальная информация о ресурсах CPU для Pod

**Команда:**
```bash
kubectl describe pod cpu-demo --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Limits:"
```

**Что показать на скриншоте:**
- Секция с:
  ```
  Limits:
    cpu: 1
  Requests:
    cpu: 500m (или 0.5)
  ```

**Альтернативная команда:**
```bash
kubectl get pod cpu-demo --output=yaml --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "resources:"
```

---

### Скриншот 18: Метрики использования CPU для Pod cpu-demo

**Команда:**
```bash
kubectl top pod cpu-demo --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: cpu-demo
- CPU(cores): должно быть близко к 974m (милли-CPU) или около 1 CPU
- MEMORY(bytes): значение

**Примечание:** Подождите 20-30 секунд после создания пода для сбора метрик.

---

### Скриншот 19: Создание Pod с недостижимым запросом CPU

**Команда:**
```bash
kubectl apply -f cpu-request-limit-2.yaml
```

**Что показать на скриншоте:**
- Вывод: `pod/cpu-demo-2 created`

---

### Скриншот 20: Статус Pod cpu-demo-2 в состоянии Pending

**Команда:**
```bash
kubectl get pod cpu-demo-2 --namespace=gribkov-as-ikbo-16-22
```

**Что показать на скриншоте:**
- NAME: cpu-demo-2
- READY: 0/1
- STATUS: Pending
- RESTARTS: 0

---

### Скриншот 21: События Pod с ошибкой планирования из-за нехватки CPU

**Команда:**
```bash
kubectl describe pod cpu-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Events:"
```

**Что показать на скриншоте:**
- События с типом Warning
- Reason: FailedScheduling
- Message: `No nodes are available that match all of the following predicates:: Insufficient cpu (3).`

---

## Дополнительные полезные команды

### Удаление всех созданных подов

```bash
kubectl delete pod memory-demo --namespace=gribkov-as-ikbo-16-22
kubectl delete pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22
kubectl delete pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22
kubectl delete pod cpu-demo --namespace=gribkov-as-ikbo-16-22
kubectl delete pod cpu-demo-2 --namespace=gribkov-as-ikbo-16-22
```

### Удаление namespace (удалит все ресурсы внутри)

```bash
kubectl delete namespace gribkov-as-ikbo-16-22
```

### Просмотр QoS класса пода

```bash
kubectl get pod <pod-name> --namespace=gribkov-as-ikbo-16-22 -o jsonpath='{.status.qosClass}'
```

Пример:
```bash
kubectl get pod memory-demo --namespace=gribkov-as-ikbo-16-22 -o jsonpath='{.status.qosClass}'
# Вывод: Burstable
```

### Просмотр использования ресурсов всеми подами

```bash
kubectl top pods --namespace=gribkov-as-ikbo-16-22
```

### Просмотр доступных ресурсов на нодах

```bash
kubectl describe nodes | grep -A 5 "Allocated resources:"
```

---

## Быстрая последовательность команд

Если нужно быстро получить все скриншоты подряд:

```bash
# 1. Подготовка
cd practical-work-7
minikube start

# 2. Включение metrics-server (СКРИНШОТ 1)
minikube addons enable metrics-server

# 3. Проверка API метрик (СКРИНШОТ 2)
kubectl get apiservices | grep metrics

# 4. Создание namespace (СКРИНШОТ 3)
kubectl create namespace gribkov-as-ikbo-16-22

# 5. Работа с памятью - Pod с корректными лимитами

# СКРИНШОТ 4: Создание
kubectl apply -f memory-request-limit.yaml

# Подождать 5-10 секунд

# СКРИНШОТ 5: Статус
kubectl get pod memory-demo --namespace=gribkov-as-ikbo-16-22

# СКРИНШОТ 6: Детальная информация о ресурсах
kubectl describe pod memory-demo --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Limits:"

# Подождать 20-30 секунд для сбора метрик

# СКРИНШОТ 7: Метрики
kubectl top pod memory-demo --namespace=gribkov-as-ikbo-16-22

# 6. Работа с памятью - Pod, превышающий лимит

# СКРИНШОТ 8: Создание
kubectl apply -f memory-request-limit-2.yaml

# Подождать 30-60 секунд, выполнить команду несколько раз

# СКРИНШОТ 9: Статус CrashLoopBackOff
kubectl get pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22

# СКРИНШОТ 10: Причина OOMKilled
kubectl describe pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Last State:"

# СКРИНШОТ 11: События на ноде
kubectl describe pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Events:"

# 7. Работа с памятью - Pod с недостижимым запросом

# СКРИНШОТ 12: Создание
kubectl apply -f memory-request-limit-3.yaml

# СКРИНШОТ 13: Статус Pending
kubectl get pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22

# СКРИНШОТ 14: События FailedScheduling
kubectl describe pod memory-demo-3 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Events:"

# 8. Работа с CPU - Pod с корректными лимитами

# СКРИНШОТ 15: Создание
kubectl apply -f cpu-request-limit.yaml

# Подождать 5-10 секунд

# СКРИНШОТ 16: Статус
kubectl get pod cpu-demo --namespace=gribkov-as-ikbo-16-22

# СКРИНШОТ 17: Детальная информация о ресурсах
kubectl describe pod cpu-demo --namespace=gribkov-as-ikbo-16-22 | grep -A 5 "Limits:"

# Подождать 20-30 секунд для сбора метрик

# СКРИНШОТ 18: Метрики CPU
kubectl top pod cpu-demo --namespace=gribkov-as-ikbo-16-22

# 9. Работа с CPU - Pod с недостижимым запросом

# СКРИНШОТ 19: Создание
kubectl apply -f cpu-request-limit-2.yaml

# СКРИНШОТ 20: Статус Pending
kubectl get pod cpu-demo-2 --namespace=gribkov-as-ikbo-16-22

# СКРИНШОТ 21: События FailedScheduling
kubectl describe pod cpu-demo-2 --namespace=gribkov-as-ikbo-16-22 | grep -A 10 "Events:"

# 10. Очистка (после получения всех скриншотов)
kubectl delete namespace gribkov-as-ikbo-16-22
```

---

## Советы по оформлению скриншотов

1. **Размер окна терминала:** Используйте достаточно широкое окно, чтобы вывод не переносился
2. **Шрифт:** Используйте читаемый размер шрифта (не слишком мелкий)
3. **Цветовая схема:** Лучше использовать светлую тему для отчета (читабельнее при печати)
4. **Обрезка:** Обрезайте скриншоты, оставляя только релевантную информацию
5. **Формат:** PNG или JPEG с хорошим качеством
6. **Последовательность:** Нумерация скриншотов соответствует порядку в отчете

---

## Troubleshooting

### Metrics не доступны

Если команда `kubectl top pod` выдает ошибку:
```
Error from server (ServiceUnavailable): the server is currently unable to handle the request
```

Решение:
1. Проверить, что metrics-server запущен:
   ```bash
   kubectl get pods -n kube-system | grep metrics-server
   ```

2. Перезапустить metrics-server:
   ```bash
   kubectl rollout restart deployment metrics-server -n kube-system
   ```

3. Подождать 1-2 минуты и повторить попытку

### Pod остается в состоянии ContainerCreating

Если pod долго находится в статусе ContainerCreating:
```bash
kubectl describe pod <pod-name> --namespace=gribkov-as-ikbo-16-22
```

Проверить раздел Events на наличие ошибок.

### Не видно статуса OOMKilled

Если pod сразу перезапускается и не видно OOMKilled:
- Выполните команду `kubectl get pod` несколько раз подряд быстро
- Используйте флаг `-w` для наблюдения:
  ```bash
  kubectl get pod memory-demo-2 --namespace=gribkov-as-ikbo-16-22 -w
  ```

---

**Удачи в подготовке отчета!**
