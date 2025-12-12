# API Testing Guide

**Автор:** Грибков А.С. ИКБО-16-22
**Дата:** 17.11.2025

---

## Предварительные требования

Перед тестированием API убедитесь, что:

1. Minikube кластер запущен
2. Все поды развернуты и работают
3. Port-forward активен для сервиса frontend

```bash
kubectl port-forward svc/frontend 8080:8080 &
```

---

## Базовые тесты API

### 1. Проверка доступности API

```bash
curl -v http://localhost:8080/api
```

**Ожидаемый результат:**
```
HTTP/1.1 200 OK
Content-Type: application/json
[]
```

---

### 2. Получить список всех записей (GET)

```bash
curl -X GET http://localhost:8080/api
```

**Ожидаемый результат:**
```json
[]
```
Пустой массив, если записей нет, или массив объектов с записями.

---

### 3. Добавить новую запись (POST)

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Первая тестовая запись"}'
```

**Ожидаемый результат:**
```json
{"text":"Первая тестовая запись","id":"<generated-id>","timestamp":"<timestamp>"}
```

---

### 4. Добавить несколько записей

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Запись 1: Проверка Redis"}'

curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Запись 2: Тестирование репликации"}'

curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Запись 3: Проверка персистентности"}'
```

---

### 5. Проверить, что записи сохранены

```bash
curl -X GET http://localhost:8080/api | jq
```

**Ожидаемый результат:**
```json
[
  {
    "text": "Запись 1: Проверка Redis",
    "id": "1",
    "timestamp": "2025-11-17T20:00:00.000Z"
  },
  {
    "text": "Запись 2: Тестирование репликации",
    "id": "2",
    "timestamp": "2025-11-17T20:00:01.000Z"
  },
  {
    "text": "Запись 3: Проверка персистентности",
    "id": "3",
    "timestamp": "2025-11-17T20:00:02.000Z"
  }
]
```

---

## Тесты с различными данными

### 6. Запись с кириллицей

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Тест русского текста: ИКБО-16-22"}'
```

---

### 7. Запись с специальными символами

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Символы: @#$%^&*()_+-=[]{}|;:,.<>?/"}'
```

---

### 8. Длинная запись

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."}'
```

---

## Продвинутое тестирование

### 9. Массовая загрузка записей

```bash
for i in {1..10}; do
  curl -X POST http://localhost:8080/api \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"Массовая запись #$i\"}"
  echo ""
done
```

---

### 10. Тест производительности (время отклика)

```bash
time curl -X GET http://localhost:8080/api
```

---

### 11. Форматированный вывод с помощью jq

```bash
curl -s http://localhost:8080/api | jq '.'
```

**Форматированный вывод с подсчетом:**
```bash
curl -s http://localhost:8080/api | jq 'length'
```

---

### 12. Фильтрация записей с помощью jq

Получить только текст всех записей:
```bash
curl -s http://localhost:8080/api | jq '.[].text'
```

Получить первую запись:
```bash
curl -s http://localhost:8080/api | jq '.[0]'
```

Получить последнюю запись:
```bash
curl -s http://localhost:8080/api | jq '.[-1]'
```

---

## Тестирование через Ingress

Если у вас настроен Ingress и запущен `minikube tunnel`:

### 13. GET через Ingress

```bash
curl -X GET http://127.0.0.1/api
```

---

### 14. POST через Ingress

```bash
curl -X POST http://127.0.0.1/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Запись через Ingress"}'
```

---

## Проверка статического сервера

### 15. Получить главную страницу

```bash
curl http://localhost:8086/
```

**Ожидаемый результат:**
```html
<html>
    <body>
        <h1>My Static App</h1>
    </body>
</html>
```

---

### 16. Проверка через Ingress (если настроен)

```bash
curl http://127.0.0.1/
```

---

## Проверка Redis репликации

### 17. Добавить записи и проверить на Slave

Добавить записи через API:
```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"text":"Тест репликации"}'
```

Проверить на Master (redis-0):
```bash
kubectl exec redis-0 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) KEYS "*"' 2>/dev/null
```

Проверить на Slave (redis-1):
```bash
kubectl exec redis-1 -- sh -c 'redis-cli -a $(cat /etc/redis-passwd/passwd) KEYS "*"' 2>/dev/null
```

---

## Тесты обработки ошибок

### 18. POST без тела запроса

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json"
```

---

### 19. POST с неверным JSON

```bash
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{invalid json}'
```

---

### 20. Несуществующий endpoint

```bash
curl -X GET http://localhost:8080/api/nonexistent
```

---

## Скрипт для комплексного тестирования

Создайте файл `run_tests.sh`:

```bash
#!/bin/bash

echo "=== Тест 1: Проверка доступности API ==="
curl -s http://localhost:8080/api

echo -e "\n\n=== Тест 2: Добавление записей ==="
for i in {1..5}; do
  echo "Добавление записи $i..."
  curl -s -X POST http://localhost:8080/api \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"Тестовая запись #$i\"}"
  echo ""
done

echo -e "\n=== Тест 3: Получение всех записей ==="
curl -s http://localhost:8085/api | jq

echo -e "\n=== Тест 4: Количество записей ==="
COUNT=$(curl -s http://localhost:8085/api | jq 'length')
echo "Всего записей: $COUNT"

echo -e "\n=== Тест 5: Проверка статического сервера ==="
curl -s http://localhost:8086/

echo -e "\n\nТестирование завершено!"
```

Запустите:
```bash
chmod +x test/run_tests.sh
./test/run_tests.sh
```

---

## Примечания

1. **jq не установлен?** Установите его:
   ```bash
   brew install jq  # macOS
   sudo apt install jq  # Ubuntu
   ```

2. **Port-forward не работает?** Убедитесь, что он запущен:
   ```bash
   kubectl port-forward svc/frontend 8085:8080 &
   kubectl port-forward svc/fileserver 8086:80 &
   ```

3. **Ingress не отвечает?** Проверьте статус и запустите tunnel:
   ```bash
   kubectl get ingress
   minikube tunnel
   ```

---

**Автор:** Грибков А.С. ИКБО-16-22
