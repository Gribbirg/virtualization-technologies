# Практическая работа 7: Управление ресурсами в Kubernetes

## Описание

Данная практическая работа посвящена изучению механизмов управления ресурсами (CPU и память) в Kubernetes через настройку requests и limits для контейнеров.

## Цели работы

- Изучить концепции requests и limits для CPU и памяти
- Понять работу QoS-классов (Guaranteed, Burstable, Best Effort)
- Научиться диагностировать проблемы с нехваткой ресурсов
- Понять механизмы вытеснения подов при нехватке ресурсов

## Структура проекта

```
practical-work-7/
├── README.md                      # Данный файл
├── memory-request-limit.yaml     # Pod с корректными лимитами памяти
├── memory-request-limit-2.yaml   # Pod, превышающий лимит (OOMKilled)
├── memory-request-limit-3.yaml   # Pod с запросом > ресурсов ноды
├── cpu-request-limit.yaml        # Pod с корректными лимитами CPU
├── cpu-request-limit-2.yaml      # Pod с запросом CPU > ресурсов ноды
├── scripts/
│   ├── setup.sh                  # Настройка окружения
│   ├── test-memory.sh            # Тестирование ограничений памяти
│   ├── test-cpu.sh               # Тестирование ограничений CPU
│   ├── cleanup.sh                # Очистка ресурсов
│   └── run-all.sh                # Запуск всех тестов
├── task/
│   └── практика_7.pdf            # Задание на практическую работу
└── report/
    └── ПВКСП_Отчет7_ГрибковАС_ИКБО-16-22.md  # Отчет
```

## Предварительные требования

- Установленный и запущенный minikube
- kubectl настроенный для работы с minikube
- Минимум 2 CPU и 4GB RAM для minikube

## Быстрый старт

### Автоматический запуск всех тестов

```bash
# Запустить все тесты последовательно
./scripts/run-all.sh
```

Этот скрипт автоматически выполнит:
1. Настройку окружения (включение metrics-server, создание namespace)
2. Тесты ограничений памяти
3. Тесты ограничений CPU
4. Очистку всех созданных ресурсов

### Пошаговое выполнение

#### 1. Настройка окружения

```bash
# Запустить minikube (если еще не запущен)
minikube start

# Настроить окружение
./scripts/setup.sh
```

Скрипт выполнит:
- Проверку статуса minikube
- Включение аддона metrics-server
- Создание namespace `gribkov-as-ikbo-16-22`

#### 2. Проверка работы metrics-server

```bash
# Проверить, что API метрик доступен
kubectl get apiservices | grep metrics

# Должна быть строка:
# v1beta1.metrics.k8s.io
```

#### 3. Тестирование ограничений памяти

```bash
# Запустить тесты памяти
./scripts/test-memory.sh
```

Скрипт протестирует:
- **Тест 1**: Pod с корректными лимитами (100Mi request, 200Mi limit, использует 150Mi)
- **Тест 2**: Pod, превышающий лимит (50Mi request, 100Mi limit, пытается использовать 250Mi) - будет убит с OOMKilled
- **Тест 3**: Pod с запросом 1000Gi - останется в статусе Pending

#### 4. Тестирование ограничений CPU

```bash
# Запустить тесты CPU
./scripts/test-cpu.sh
```

Скрипт протестирует:
- **Тест 1**: Pod с корректными лимитами (0.5 request, 1 limit, пытается использовать 2 CPU)
- **Тест 2**: Pod с запросом 100 CPU - останется в статусе Pending

#### 5. Очистка ресурсов

```bash
# Удалить все созданные ресурсы
./scripts/cleanup.sh
```

## Ручное выполнение команд

### Проверка отдельного пода с ограничениями памяти

```bash
# Создать pod
kubectl apply -f memory-request-limit.yaml

# Проверить статус
kubectl get pod memory-demo -n gribkov-as-ikbo-16-22

# Посмотреть детали
kubectl describe pod memory-demo -n gribkov-as-ikbo-16-22

# Получить метрики
kubectl top pod memory-demo -n gribkov-as-ikbo-16-22

# Удалить pod
kubectl delete pod memory-demo -n gribkov-as-ikbo-16-22
```

### Проверка пода, превышающего лимит памяти (OOMKilled)

```bash
# Создать pod
kubectl apply -f memory-request-limit-2.yaml

# Наблюдать за статусом (будет CrashLoopBackOff)
kubectl get pod memory-demo-2 -n gribkov-as-ikbo-16-22 -w

# Посмотреть события
kubectl describe pod memory-demo-2 -n gribkov-as-ikbo-16-22

# Проверить причину завершения
kubectl get pod memory-demo-2 -n gribkov-as-ikbo-16-22 -o yaml | grep -A 5 "lastState:"

# Удалить pod
kubectl delete pod memory-demo-2 -n gribkov-as-ikbo-16-22
```

### Проверка пода с недостаточными ресурсами

```bash
# Создать pod с запросом 1000Gi памяти
kubectl apply -f memory-request-limit-3.yaml

# Проверить статус (будет Pending)
kubectl get pod memory-demo-3 -n gribkov-as-ikbo-16-22

# Посмотреть причину
kubectl describe pod memory-demo-3 -n gribkov-as-ikbo-16-22 | grep -A 10 "Events:"

# Удалить pod
kubectl delete pod memory-demo-3 -n gribkov-as-ikbo-16-22
```

### Проверка CPU лимитов

```bash
# Создать pod с CPU лимитами
kubectl apply -f cpu-request-limit.yaml

# Подождать запуска
kubectl wait --for=condition=ready pod/cpu-demo -n gribkov-as-ikbo-16-22 --timeout=60s

# Проверить метрики (CPU будет ограничен ~1 CPU)
kubectl top pod cpu-demo -n gribkov-as-ikbo-16-22

# Удалить pod
kubectl delete pod cpu-demo -n gribkov-as-ikbo-16-22
```

## Описание конфигураций

### memory-request-limit.yaml
- **Request**: 100Mi - минимум памяти для запуска
- **Limit**: 200Mi - максимум памяти
- **Использование**: 150Mi (в пределах лимита)
- **Результат**: Pod успешно работает

### memory-request-limit-2.yaml
- **Request**: 50Mi
- **Limit**: 100Mi
- **Попытка использования**: 250Mi (превышает лимит)
- **Результат**: Container убивается с OOMKilled и перезапускается (CrashLoopBackOff)

### memory-request-limit-3.yaml
- **Request**: 1000Gi (больше чем на ноде)
- **Limit**: 1000Gi
- **Результат**: Pod остается в статусе Pending, не может быть запланирован

### cpu-request-limit.yaml
- **Request**: 0.5 CPU (500 milli-CPU)
- **Limit**: 1 CPU
- **Попытка использования**: 2 CPU
- **Результат**: CPU ограничивается до ~1 CPU

### cpu-request-limit-2.yaml
- **Request**: 100 CPU (больше чем на ноде)
- **Limit**: 100 CPU
- **Результат**: Pod остается в статусе Pending

## QoS классы

Каждому поду автоматически присваивается QoS класс:

### Guaranteed
- Для каждого контейнера заданы request и limit для CPU и memory
- Значения request и limit совпадают
- Примеры: memory-request-limit-3.yaml, cpu-request-limit-2.yaml

### Burstable
- Хотя бы один контейнер имеет request или limit
- Request < Limit
- Примеры: memory-request-limit.yaml, memory-request-limit-2.yaml, cpu-request-limit.yaml

### Best Effort
- Ни один контейнер не имеет ограничений по ресурсам
- Первый кандидат на вытеснение при нехватке ресурсов

## Полезные команды

```bash
# Проверить QoS класс пода
kubectl get pod <pod-name> -n gribkov-as-ikbo-16-22 -o jsonpath='{.status.qosClass}'

# Посмотреть использование ресурсов всеми подами
kubectl top pods -n gribkov-as-ikbo-16-22

# Посмотреть доступные ресурсы на нодах
kubectl describe nodes

# Посмотреть события на ноде (поиск OOMKilled)
kubectl describe nodes | grep -i "memory"

# Удалить namespace со всеми ресурсами
kubectl delete namespace gribkov-as-ikbo-16-22
```

## Контрольные вопросы

1. **Назовите 3 QoS-класса**
   - Guaranteed, Burstable, Best Effort

2. **Назовите основные ресурсы системы и единицы их измерения в Kubernetes**
   - CPU - в ядрах (cores) или milli-CPU (m)
   - Memory - в байтах (Ki, Mi, Gi)

3. **Для чего нужен HPA?**
   - Horizontal Pod Autoscaler автоматически масштабирует количество подов на основе метрик использования ресурсов

4. **Для чего необходимо устанавливать ограничения в Kubernetes?**
   - Предотвращение потребления одним подом всех ресурсов ноды
   - Корректное планирование подов на нодах
   - Обеспечение справедливого распределения ресурсов
   - Защита от утечек памяти и runaway процессов

5. **Что будет с узлом при превышении ограничений?**
   - При превышении memory limit - контейнер убивается (OOMKilled)
   - При превышении CPU limit - процесс throttling'уется (ограничивается)
   - При нехватке ресурсов на ноде - kubelet начинает вытеснять поды по QoS классам

## Troubleshooting

### Pod в статусе Pending
```bash
# Проверить события
kubectl describe pod <pod-name> -n gribkov-as-ikbo-16-22
# Искать "Insufficient memory" или "Insufficient cpu"
```

### Pod в статусе CrashLoopBackOff
```bash
# Проверить логи
kubectl logs <pod-name> -n gribkov-as-ikbo-16-22

# Проверить причину завершения
kubectl get pod <pod-name> -n gribkov-as-ikbo-16-22 -o yaml | grep -A 10 "lastState:"
# Искать "OOMKilled"
```

### Метрики не доступны
```bash
# Проверить статус metrics-server
kubectl get pods -n kube-system | grep metrics-server

# Перезапустить metrics-server
kubectl rollout restart deployment metrics-server -n kube-system
```

## Автор

Грибков Александр Сергеевич, ИКБО-16-22
