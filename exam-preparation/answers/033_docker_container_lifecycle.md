# Жизненный цикл контейнера Docker

## Краткий ответ

Жизненный цикл контейнера Docker включает следующие состояния: Created (создан, но не запущен), Running (активно работает), Paused (приостановлен, процессы заморожены), Stopped/Exited (остановлен, процессы завершены), Restarting (перезапускается), Dead (неудачная попытка удаления), Removed (полностью удален). Переходы между состояниями осуществляются командами docker run, start, stop, pause, unpause, restart, kill, rm.

## Развёрнутый ответ

### Диаграмма состояний

```
                    docker create
                         ↓
    ┌───────────────[CREATED]───────────────┐
    │                   ↓                    │
    │            docker start                │
    │                   ↓                    │
    │              [RUNNING]                 │
    │                ↓  ↑  ↓                 │
    │    docker     │  │  │   docker         │
    │    pause      │  │  │   stop/kill      │
    │               ↓  │  ↓                  │
    │           [PAUSED] │ [STOPPED/EXITED]  │
    │               │    │      ↓            │
    │    docker     │    │   docker restart  │
    │    unpause    │    │      ↓            │
    │               └────┴─────[RESTARTING]  │
    │                                         │
    │                docker rm                │
    └───────────────────→[REMOVED]           │
                              ↑               │
                    ┌─────[DEAD]─────────────┘
                    │  (failed removal)
                    │
              docker rm -f
```

### Состояния контейнера

#### 1. Created (Создан)

**Описание**: Контейнер создан, но процессы еще не запущены.

**Как попасть в это состояние**:
```bash
docker create nginx
docker create --name mycontainer -p 8080:80 nginx
```

**Характеристики**:
- Файловая система подготовлена
- Конфигурация контейнера готова
- Сетевые настройки применены
- Volumes смонтированы
- Процессы не запущены
- Ресурсы не выделены активно

**Метаданные**:
- Container ID присвоен
- Имя контейнера установлено
- Конфигурация сохранена

**Когда используется**:
- Когда нужно создать контейнер, но запустить позже
- Для проверки конфигурации перед запуском
- В CI/CD пайплайнах для подготовки окружения

#### 2. Running (Работает)

**Описание**: Контейнер активно работает, процессы выполняются.

**Как попасть в это состояние**:
```bash
docker run nginx
docker start container_name
docker restart container_name
docker unpause container_name
```

**Характеристики**:
- Основной процесс (PID 1) выполняется
- Выделены CPU и memory ресурсы
- Сетевое взаимодействие активно
- Логи пишутся
- Health checks выполняются (если настроены)

**Что происходит**:
- cgroups ограничивают использование ресурсов
- namespaces обеспечивают изоляцию
- Процессы работают в isolated environment
- STDOUT/STDERR перехватываются Docker

**Мониторинг**:
```bash
docker ps                      # список работающих контейнеров
docker stats container_name    # использование ресурсов в реальном времени
docker top container_name      # процессы внутри контейнера
docker logs -f container_name  # логи в реальном времени
```

**Взаимодействие**:
```bash
docker exec -it container_name bash  # выполнение команд внутри
docker attach container_name         # подключение к STDIN/STDOUT
```

#### 3. Paused (Приостановлен)

**Описание**: Все процессы контейнера заморожены с использованием cgroup freezer.

**Как попасть в это состояние**:
```bash
docker pause container_name
```

**Характеристики**:
- Процессы приостановлены, но не завершены
- Память остается выделенной
- Состояние процессов сохранено
- Никаких системных вызовов не выполняется
- Сетевые соединения сохраняются

**Технические детали**:
- Использует cgroup freezer subsystem
- Процессы в состоянии TASK_UNINTERRUPTIBLE
- Не получают CPU time
- Контейнер не отвечает на сигналы

**Когда используется**:
- Для временной остановки без завершения процессов
- При необходимости освободить CPU
- Для отладки (freeze state для анализа)
- Перед checkpoint/restore операциями

**Возобновление**:
```bash
docker unpause container_name
```

#### 4. Stopped/Exited (Остановлен)

**Описание**: Все процессы контейнера завершены, но контейнер не удален.

**Как попасть в это состояние**:
```bash
docker stop container_name         # graceful shutdown (SIGTERM → SIGKILL)
docker kill container_name         # immediate kill (SIGKILL)
# Или процесс внутри завершился сам
```

**Характеристики**:
- Процессы полностью завершены
- Ресурсы освобождены (CPU, memory)
- Writable layer сохранен
- Logs доступны
- Exit code сохранен
- Конфигурация сохранена

**Exit codes**:
- `0`: успешное завершение
- `1`: application error
- `126`: command cannot be executed
- `127`: command not found
- `137`: SIGKILL (docker kill or OOM)
- `143`: SIGTERM (docker stop)

**Операции**:
```bash
docker ps -a                       # показать остановленные контейнеры
docker logs container_name         # просмотр логов
docker inspect container_name      # детальная информация
docker start container_name        # перезапуск
docker commit container_name img   # создание образа из контейнера
```

**Graceful Shutdown (docker stop)**:
1. Отправка SIGTERM главному процессу (PID 1)
2. Ожидание grace period (по умолчанию 10 секунд)
3. Если не завершился — отправка SIGKILL
4. Cleanup операции

#### 5. Restarting (Перезапускается)

**Описание**: Временное состояние при перезапуске контейнера.

**Как попасть в это состояние**:
```bash
docker restart container_name
# Или автоматически по restart policy
```

**Restart Policies**:
```bash
# Никогда не перезапускать
docker run --restart=no nginx

# Перезапускать при сбое (exit code != 0)
docker run --restart=on-failure nginx
docker run --restart=on-failure:3 nginx  # максимум 3 попытки

# Всегда перезапускать (кроме явной остановки)
docker run --restart=always nginx

# Перезапускать всегда, включая после reboot хоста
docker run --restart=unless-stopped nginx
```

**Процесс**:
1. Остановка контейнера (если работал)
2. Cleanup writable layer (опционально)
3. Повторная инициализация
4. Запуск процессов

**Использование**:
- Автоматическое восстановление после сбоев
- Обеспечение высокой доступности
- Обработка temporary failures

#### 6. Dead (Мертвый)

**Описание**: Контейнер не может быть удален из-за ошибок.

**Причины**:
- Проблемы с storage driver
- Устройства все еще смонтированы
- Процессы zombie
- Ошибки файловой системы
- Kernel bugs

**Диагностика**:
```bash
docker ps -a --filter status=dead
docker inspect container_name  # проверка ошибок
```

**Решение**:
```bash
# Принудительное удаление
docker rm -f container_name

# Перезапуск Docker daemon
sudo systemctl restart docker

# Ручная очистка (крайний случай)
sudo rm -rf /var/lib/docker/containers/container_id
```

#### 7. Removed (Удален)

**Описание**: Контейнер полностью удален, освобождены все ресурсы.

**Как попасть в это состояние**:
```bash
docker rm container_name           # удаление остановленного контейнера
docker rm -f container_name        # принудительное удаление
docker run --rm nginx              # auto-remove после остановки
```

**Что удаляется**:
- Writable layer контейнера
- Метаданные контейнера
- Логи (если не используется external logging)
- Network endpoints
- Temporary файлы

**Что остается**:
- Образ (image)
- Named volumes (если не указан -v)
- Сети (если не удалены явно)

**Массовое удаление**:
```bash
# Удалить все остановленные контейнеры
docker container prune

# Удалить все контейнеры (даже работающие)
docker rm -f $(docker ps -aq)

# Удалить контейнеры старше определенного времени
docker container prune --filter "until=24h"
```

### Команды управления жизненным циклом

#### Создание и запуск

```bash
# Создать и сразу запустить
docker run [options] image [command]
docker run -d -p 8080:80 --name web nginx

# Только создать
docker create [options] image [command]
docker create --name myapp myapp:latest

# Запустить созданный контейнер
docker start container_name
docker start -a container_name  # с attach к STDOUT
docker start -i container_name  # interactive mode
```

#### Остановка

```bash
# Graceful stop (SIGTERM, затем SIGKILL)
docker stop container_name
docker stop -t 30 container_name  # изменить grace period

# Immediate kill (SIGKILL)
docker kill container_name
docker kill -s SIGINT container_name  # кастомный сигнал
```

#### Пауза/возобновление

```bash
# Приостановить
docker pause container_name
docker pause $(docker ps -q)  # все контейнеры

# Возобновить
docker unpause container_name
```

#### Перезапуск

```bash
# Перезапустить контейнер
docker restart container_name
docker restart -t 30 container_name  # grace period
```

#### Удаление

```bash
# Удалить остановленный контейнер
docker rm container_name

# Принудительно удалить работающий
docker rm -f container_name

# Удалить с volumes
docker rm -v container_name

# Auto-remove при создании
docker run --rm image
```

### События и логирование

**События контейнера**:
```bash
# Мониторинг событий в реальном времени
docker events

# Фильтр по типу и контейнеру
docker events --filter container=myapp --filter event=start

# События за период
docker events --since 1h
```

**Типы событий**:
- `create`, `start`, `restart`, `stop`, `kill`
- `pause`, `unpause`
- `die`, `destroy`, `remove`
- `oom` (out of memory)
- `health_status` (health check changes)

**Логи**:
```bash
# Просмотр логов
docker logs container_name
docker logs -f container_name       # follow
docker logs --tail 100 container_name
docker logs --since 1h container_name
docker logs -t container_name       # с timestamps
```

### Health Checks

**Определение в Dockerfile**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
```

**Состояния health**:
- `starting`: initialization period
- `healthy`: проверка прошла успешно
- `unhealthy`: проверка провалилась несколько раз

**Просмотр health status**:
```bash
docker inspect --format='{{.State.Health.Status}}' container_name
docker ps --filter health=unhealthy
```

### Best Practices

**Создание**:
- Используйте `--name` для именования контейнеров
- Задавайте `--restart` policy для критичных сервисов
- Используйте `--rm` для временных контейнеров

**Остановка**:
- Предпочитайте `docker stop` вместо `docker kill`
- Настройте приложение для graceful shutdown
- Используйте адекватный grace period

**Cleanup**:
- Регулярно удаляйте остановленные контейнеры
- Используйте `docker system prune` для комплексной очистки
- Настройте log rotation

**Мониторинг**:
- Настройте health checks для критичных сервисов
- Мониторьте ресурсы через `docker stats`
- Используйте централизованное логирование

## Источники

- Docker Documentation: Container Lifecycle
- Docker Engine API: Container States
- Docker Best Practices Guide
- Docker Deep Dive by Nigel Poulton
- Linux cgroups and namespaces documentation
