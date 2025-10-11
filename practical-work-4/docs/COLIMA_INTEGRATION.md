# Интеграция с Colima

## 🚀 Автоматический запуск и очистка Colima

Скрипт `full-validation.sh` теперь **автоматически управляет Colima**!

## 📋 Переменные окружения

| Переменная | Значение по умолчанию | Описание |
|------------|----------------------|----------|
| `START_COLIMA` | `true` | Автоматически запускать Colima, если Docker не доступен |
| `STOP_COLIMA` | `false` | Останавливать Colima после завершения тестов |
| `CLEANUP_ON_EXIT` | `true` | Удалять контейнеры и volumes при выходе |

## 🎯 Примеры использования

### 1. Запуск по умолчанию (рекомендуется)
```bash
./scripts/full-validation.sh
```
**Что произойдёт:**
- ✅ Автоматически запустит Colima (если Docker не запущен)
- ✅ Запустит все 13 контейнеров
- ✅ Выполнит все тесты
- ✅ Удалит контейнеры после тестов
- ⚠️ Colima останется запущенным

### 2. Полная автоматизация
```bash
STOP_COLIMA=true ./scripts/full-validation.sh
```
**Что произойдёт:**
- ✅ Запустит Colima
- ✅ Выполнит все тесты
- ✅ Удалит контейнеры
- ✅ **Остановит Colima**

### 3. Без автозапуска Colima
```bash
START_COLIMA=false ./scripts/full-validation.sh
```
**Что произойдёт:**
- ⚠️ Если Docker не запущен - выполнит только статические проверки
- ℹ️ Покажет инструкцию по запуску Colima вручную

### 4. Оставить контейнеры запущенными
```bash
CLEANUP_ON_EXIT=false ./scripts/full-validation.sh
```
**Что произойдёт:**
- ✅ Запустит Colima
- ✅ Запустит контейнеры
- ✅ Выполнит тесты
- ⚠️ **Контейнеры останутся запущенными** (для просмотра в браузере)

### 5. Комбинация параметров
```bash
START_COLIMA=true STOP_COLIMA=false CLEANUP_ON_EXIT=false ./scripts/full-validation.sh
```
**Идеально для демонстрации:**
- ✅ Всё запустится автоматически
- ✅ Всё останется запущенным для демонстрации

## 🔄 Процесс работы скрипта

```
1. Проверка статических требований
   └─ ✅ 35-36 тестов

2. Проверка Docker daemon
   ├─ Если запущен → продолжить
   └─ Если нет → запустить Colima (если START_COLIMA=true)

3. Запуск контейнеров
   └─ docker-compose up -d --build

4. Тестирование
   ├─ CRUD операции
   ├─ Экспорт логов
   ├─ Проверка метрик
   └─ Проверка мониторинга

5. Очистка (если CLEANUP_ON_EXIT=true)
   ├─ docker-compose down -v
   └─ colima stop (если STOP_COLIMA=true)
```

## 📊 Параметры запуска Colima

Colima запускается с параметрами:
```bash
colima start --memory 8 --cpu 4
```

- **Memory:** 8 GB (достаточно для всех 13 контейнеров)
- **CPU:** 4 ядра (оптимально для производительности)

## 🆘 Решение проблем

### Colima не запускается
```bash
# Проверить статус
colima status

# Удалить и пересоздать
colima delete
colima start --memory 8 --cpu 4
```

### Docker daemon недоступен после запуска Colima
```bash
# Подождать 30-60 секунд
sleep 60

# Проверить
docker info

# Перезапустить Colima
colima restart
```

### Ошибка скачивания образов (403 Forbidden)
Скрипт автоматически делает **3 попытки** с паузой 10 секунд.

Если не помогло:
```bash
# Подождите 1-2 минуты и повторите
sleep 120
./scripts/full-validation.sh

# Или очистите кэш Docker
docker system prune -a

# Или перезапустите Colima
colima restart
```

### Не хватает памяти
```bash
# Запустить с меньшими ресурсами
colima start --memory 6 --cpu 2

# Или остановить ненужные контейнеры
docker stop $(docker ps -q)
```

### Контейнеры не запускаются
```bash
# Проверить логи
docker-compose logs

# Логи конкретного сервиса
docker-compose logs spring-app

# Пересоздать всё с нуля
docker-compose down -v
colima restart
./scripts/full-validation.sh
```

## 💡 Рекомендации

### Для разработки
```bash
# Запустить один раз, оставить работающим
CLEANUP_ON_EXIT=false ./scripts/full-validation.sh
```

### Для CI/CD
```bash
# Полная автоматизация с очисткой
START_COLIMA=true STOP_COLIMA=true CLEANUP_ON_EXIT=true ./scripts/full-validation.sh
```

### Для демонстрации на защите
```bash
# Запустить всё, оставить для показа
STOP_COLIMA=false CLEANUP_ON_EXIT=false ./scripts/full-validation.sh
```

## 📝 Логи

Логи запуска Colima сохраняются в: `/tmp/colima-start.log`

```bash
# Просмотр логов
cat /tmp/colima-start.log

# Мониторинг в реальном времени
tail -f /tmp/colima-start.log
```

## ✅ Проверка работы

После запуска скрипта проверьте:

```bash
# Статус Colima
colima status

# Статус Docker
docker info

# Запущенные контейнеры
docker-compose ps

# Использование ресурсов
docker stats
```
