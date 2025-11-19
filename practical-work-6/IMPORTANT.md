# ВАЖНО - Прочитайте перед запуском!

## Проблемы и решения

### ❌ Ошибка: "failed to download openapi: EOF"

**Причина:** API сервер Kubernetes не отвечает или завис.

**Решение:**
```bash
minikube delete
colima restart
minikube start --driver=docker --cpus=2 --memory=2048
```

### ❌ minikube status показывает "apiserver: Stopped"

**Причина:** API сервер не запустился из-за нехватки ресурсов или конфликта.

**Решение:**
```bash
minikube delete
colima delete -f
colima start --cpu 2 --memory 4 --disk 20
minikube start --driver=docker --cpus=2 --memory=2048
```

**ВАЖНО:** Используйте `--memory=2048`, НЕ 3072 или 4096!

### ⚠️ Docker/Colima зависает или команды выполняются очень медленно

**Решение:**
```bash
pkill -f colima
colima delete -f
colima start --cpu 2 --memory 4 --disk 20
```

## Правильная последовательность запуска

### Первый запуск:

```bash
# 1. Настройка окружения
./setup-environment.sh

# 2. Сборка образов
./build-images.sh

# 3. Развертывание приложения
./test.sh
```

### Если что-то пошло не так:

```bash
# Полная переустановка окружения
./setup-environment.sh

# Затем повторите развертывание
./test.sh
```

### Повторный запуск (окружение уже настроено):

```bash
# Просто запустите кластер
minikube start

# И разверните приложение
./test.sh
```

## Требования к ресурсам

### Для Colima (Docker VM):
- CPU: 2 ядра
- Memory: 4 GB
- Disk: 20 GB

### Для Minikube (Kubernetes кластер):
- CPU: 2 ядра
- Memory: 2048 MB (НЕ БОЛЬШЕ!)

**Почему именно 2048 MB?**
- При 3072 MB или 4096 MB на macOS с Colima API сервер может не запуститься
- 2048 MB достаточно для работы всех компонентов приложения

## Скрипты в проекте

- `setup-environment.sh` - Настройка Colima и Minikube (запускать первый раз)
- `build-images.sh` - Сборка Docker образов
- `test.sh` - Развертывание приложения в Kubernetes
- `cleanup.sh` - Удаление всех ресурсов из кластера

## Проверка работоспособности

После успешного запуска проверьте:

```bash
# Статус кластера
kubectl cluster-info

# Все ресурсы
kubectl get all

# Pods должны быть в статусе Running
kubectl get pods

# Ingress должен иметь ADDRESS
kubectl get ingress
```

## Доступ к приложению

```bash
# Получить IP адрес Minikube
minikube ip

# Или открыть напрямую
minikube service frontend
```

Приложение будет доступно по адресу:
- Статические файлы: `http://<MINIKUBE_IP>/`
- API: `http://<MINIKUBE_IP>/api`

## Полезные команды для отладки

```bash
# Логи пода
kubectl logs -f <pod-name>

# Описание пода (события и ошибки)
kubectl describe pod <pod-name>

# Войти в контейнер
kubectl exec -it <pod-name> -- /bin/sh

# Проверка репликации Redis
kubectl exec redis-0 -- redis-cli -a $(kubectl get secret redis-passwd -o jsonpath='{.data.passwd}' | base64 -d) INFO replication

# Перезапуск Minikube без удаления
minikube stop
minikube start
```

## Если ничего не помогает

```bash
# Полная очистка и переустановка
minikube delete
colima delete -f
rm -rf ~/.minikube
rm -rf ~/.colima

# Затем запустите setup-environment.sh заново
./setup-environment.sh
```
