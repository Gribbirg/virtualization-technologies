# Как называются основные типы сущностей в Docker Swarm?

## Краткий ответ
Основные сущности Docker Swarm: Node (узел) — физический или виртуальный сервер в кластере (Manager или Worker); Service (сервис) — описание желаемого состояния приложения; Task (задача) — атомарная единица работы, один контейнер на узле; Stack (стек) — группа связанных сервисов; Network (сеть) — виртуальная сеть для связи контейнеров; Volume (том) — persistent storage для данных; Secret и Config — управление чувствительными данными и конфигурацией.

## Развёрнутый ответ

## 1. Node (Узел)

**Определение:**
Node — это экземпляр Docker Engine, участвующий в Swarm-кластере. Каждый узел может быть физическим сервером или виртуальной машиной.

**Типы узлов:**

**Manager Node (Управляющий узел):**
- Управляет состоянием кластера
- Выполняет планирование (scheduling) задач
- Принимает команды управления через Docker API
- Участвует в Raft consensus для обеспечения консистентности
- Может также выполнять задачи как Worker (по умолчанию)

**Worker Node (Рабочий узел):**
- Выполняет задачи (tasks), назначенные manager'ами
- Отправляет отчеты о состоянии задач manager'ам
- Не участвует в принятии управленческих решений
- Не может обрабатывать команды управления кластером

**Команды для работы с узлами:**
```bash
# Просмотр узлов
docker node ls

# Детальная информация об узле
docker node inspect <node-id>

# Повышение Worker до Manager
docker node promote <node-id>

# Понижение Manager до Worker
docker node demote <node-id>

# Изменение доступности узла
docker node update --availability drain <node-id>
docker node update --availability active <node-id>
docker node update --availability pause <node-id>

# Добавление labels к узлу
docker node update --label-add env=production <node-id>
```

**Состояния availability:**
- `active` — узел принимает новые задачи
- `pause` — узел не принимает новые задачи, но существующие продолжают работать
- `drain` — узел не принимает новые задачи, существующие перемещаются на другие узлы

**Best practices:**
- Использовать нечетное количество manager'ов (3, 5, 7) для обеспечения кворума
- Не более 7 manager'ов для оптимальной производительности Raft
- Размещать manager'ы в разных availability zones для отказоустойчивости

## 2. Service (Сервис)

**Определение:**
Service — это описание желаемого состояния приложения, включая образ контейнера, количество реплик, порты, сети и другие параметры. Это основная абстракция для развертывания приложений в Swarm.

**Типы сервисов:**

**Replicated Service (Реплицированный):**
- Запускается указанное количество идентичных реплик
- Распределяются по узлам кластера
- Используется для stateless приложений

```bash
docker service create --name web --replicas 3 nginx:alpine
```

**Global Service (Глобальный):**
- Запускается ровно один экземпляр на каждом узле
- Автоматически запускается на новых узлах
- Используется для мониторинга, логирования, агентов безопасности

```bash
docker service create --name agent --mode global monitoring-agent:latest
```

**Основные параметры сервиса:**
```bash
docker service create \
  --name my-app \
  --replicas 3 \
  --publish published=80,target=8080 \
  --network my-network \
  --env DATABASE_URL=postgres://... \
  --mount type=volume,source=app-data,target=/data \
  --limit-cpu 0.5 \
  --limit-memory 512M \
  --reserve-cpu 0.25 \
  --reserve-memory 256M \
  --update-delay 10s \
  --update-parallelism 1 \
  --restart-condition on-failure \
  --restart-max-attempts 3 \
  my-image:v1
```

**Команды управления сервисами:**
```bash
# Создание
docker service create --name web nginx

# Просмотр списка
docker service ls

# Детальная информация
docker service inspect web

# Просмотр задач сервиса
docker service ps web

# Масштабирование
docker service scale web=5

# Обновление
docker service update --image nginx:latest web
docker service update --env-add NEW_VAR=value web

# Удаление
docker service rm web

# Логи
docker service logs web
docker service logs -f --tail 100 web
```

## 3. Task (Задача)

**Определение:**
Task — это атомарная единица работы в Swarm, представляющая один контейнер, работающий на конкретном узле. Задачи создаются сервисом и назначаются узлам планировщиком.

**Жизненный цикл задачи:**
1. **New** — задача создана, но еще не назначена узлу
2. **Pending** — задача назначена узлу, ожидает ресурсов
3. **Assigned** — задача назначена конкретному узлу
4. **Accepted** — worker принял задачу
5. **Preparing** — подготовка к запуску (pull образа)
6. **Starting** — запуск контейнера
7. **Running** — контейнер работает
8. **Complete** — контейнер завершился с кодом 0
9. **Failed** — контейнер завершился с ошибкой
10. **Shutdown** — задача останавливается
11. **Rejected** — worker отклонил задачу
12. **Orphaned** — узел с задачей недоступен

**Характеристики:**
- Неизменяемость — задачу нельзя изменить, только пересоздать
- Привязка к узлу — после назначения задача не перемещается (кроме сбоя узла)
- Уникальный идентификатор — каждая задача имеет уникальный ID
- Связь с сервисом — задача всегда принадлежит сервису

**Просмотр задач:**
```bash
# Задачи конкретного сервиса
docker service ps web

# Все задачи на узле
docker node ps <node-id>

# Включая завершенные задачи
docker service ps --no-trunc web
```

## 4. Stack (Стек)

**Определение:**
Stack — это группа взаимосвязанных сервисов, определенных в docker-compose.yml файле и развернутых как единое целое. Стек упрощает управление сложными многокомпонентными приложениями.

**Пример docker-compose.yml для стека:**
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    networks:
      - frontend

  api:
    image: my-api:v1
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
    networks:
      - frontend
      - backend
    secrets:
      - db_password

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    deploy:
      placement:
        constraints:
          - node.role == manager
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - db_password

networks:
  frontend:
  backend:

volumes:
  db-data:

secrets:
  db_password:
    external: true
```

**Команды управления стеками:**
```bash
# Развертывание стека
docker stack deploy -c docker-compose.yml my-stack

# Просмотр стеков
docker stack ls

# Сервисы в стеке
docker stack services my-stack

# Задачи в стеке
docker stack ps my-stack

# Удаление стека
docker stack rm my-stack
```

**Преимущества стеков:**
- Декларативное описание всего приложения
- Версионирование инфраструктуры (Infrastructure as Code)
- Атомарное развертывание и удаление
- Namespace изоляция (все ресурсы с префиксом имени стека)

## 5. Network (Сеть)

**Определение:**
Network — это виртуальная сеть для связи контейнеров. В Swarm особую роль играют overlay-сети, позволяющие контейнерам на разных узлах общаться друг с другом.

**Типы сетей в Swarm:**

**Overlay Network:**
- Многоузловая сеть для связи контейнеров на разных hosts
- Используется для межсервисного взаимодействия
- Поддерживает шифрование трафика
- Автоматическое обнаружение сервисов (DNS)

```bash
docker network create \
  --driver overlay \
  --subnet 10.0.9.0/24 \
  --attachable \
  --opt encrypted \
  my-network
```

**Ingress Network:**
- Специальная overlay-сеть для routing mesh
- Автоматически создается при инициализации Swarm
- Обеспечивает доступ к published портам на любом узле

**Bridge Network:**
- Используется для single-host networking
- Не подходит для multi-host сценариев

**Команды работы с сетями:**
```bash
# Создание overlay сети
docker network create --driver overlay my-overlay

# Просмотр сетей
docker network ls

# Детальная информация
docker network inspect my-overlay

# Подключение сервиса к сети
docker service update --network-add my-overlay my-service

# Удаление сети
docker network rm my-overlay
```

**Service Discovery:**
- DNS-based discovery — каждый сервис доступен по имени
- VIP (Virtual IP) — каждому сервису назначается виртуальный IP
- Load balancing — встроенная балансировка между репликами

## 6. Volume (Том)

**Определение:**
Volume — это механизм для хранения persistent данных, которые переживают перезапуск контейнеров. В Swarm volumes позволяют задачам получать доступ к постоянному хранилищу.

**Типы volumes:**

**Named Volumes:**
```bash
docker volume create my-data

docker service create \
  --mount type=volume,source=my-data,target=/data \
  my-service
```

**Bind Mounts:**
```bash
docker service create \
  --mount type=bind,source=/host/path,target=/container/path \
  my-service
```

**Tmpfs Mounts:**
```bash
docker service create \
  --mount type=tmpfs,target=/tmp,tmpfs-size=100m \
  my-service
```

**Volume Drivers:**
- `local` — локальное хранилище на узле
- `nfs` — Network File System для shared storage
- Сторонние драйверы: REX-Ray, Convoy, Flocker

**Ограничения в Swarm:**
- Volumes обычно привязаны к конкретному узлу
- Для shared storage нужны специальные драйверы (NFS, GlusterFS)
- Миграция задач с volumes между узлами проблематична

**Команды:**
```bash
# Создание volume
docker volume create my-volume

# Просмотр volumes
docker volume ls

# Детальная информация
docker volume inspect my-volume

# Удаление
docker volume rm my-volume

# Очистка неиспользуемых
docker volume prune
```

## 7. Secret (Секрет)

**Определение:**
Secret — это механизм безопасного хранения и распространения чувствительных данных (пароли, ключи API, сертификаты). Секреты шифруются и доступны только сервисам, которым явно предоставлен доступ.

**Создание секрета:**
```bash
# Из файла
docker secret create db_password ./password.txt

# Из stdin
echo "mypassword" | docker secret create db_password -

# Просмотр секретов
docker secret ls

# Детальная информация (содержимое НЕ показывается)
docker secret inspect db_password
```

**Использование в сервисах:**
```bash
docker service create \
  --name app \
  --secret db_password \
  --secret source=api_key,target=/run/secrets/api \
  my-app:v1
```

**В docker-compose.yml:**
```yaml
services:
  app:
    image: my-app:v1
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    external: true
  api_key:
    file: ./api_key.txt
```

**Характеристики:**
- Шифрование в transit и at rest
- Монтируются в `/run/secrets/<secret-name>` как файлы
- Доступны только контейнерам с явным разрешением
- Неизменяемы — для обновления нужно создать новый секрет
- Максимальный размер — 500 KB

## 8. Config (Конфигурация)

**Определение:**
Config — это механизм хранения несекретной конфигурации (конфигурационные файлы, скрипты). Похож на Secret, но без шифрования и виден при inspect.

**Создание конфига:**
```bash
# Из файла
docker config create nginx_config ./nginx.conf

# Из stdin
cat nginx.conf | docker config create nginx_config -

# Просмотр конфигов
docker config ls

# Детальная информация (содержимое видно)
docker config inspect nginx_config
```

**Использование:**
```bash
docker service create \
  --name web \
  --config source=nginx_config,target=/etc/nginx/nginx.conf \
  nginx:alpine
```

**В docker-compose.yml:**
```yaml
services:
  web:
    image: nginx:alpine
    configs:
      - source: nginx_config
        target: /etc/nginx/nginx.conf

configs:
  nginx_config:
    file: ./nginx.conf
```

**Отличия от Secret:**
- Не шифруются
- Содержимое видно через `docker config inspect`
- Используются для публичной конфигурации
- Тот же механизм распространения (через Raft)

## Дополнительные концепции

### Routing Mesh

**Определение:**
Встроенный механизм балансировки нагрузки, позволяющий обращаться к сервису через published порт на любом узле кластера, даже если на этом узле не запущены задачи сервиса.

**Как работает:**
1. Запрос приходит на порт любого узла
2. Routing mesh перенаправляет запрос на узел с запущенной задачей
3. Встроенный load balancer распределяет между репликами

```bash
docker service create --name web --publish 80:80 --replicas 3 nginx
# Доступ через http://<any-node-ip>:80
```

### Placement Constraints

**Определение:**
Правила размещения задач на узлах с определенными характеристиками.

**Примеры:**
```bash
# Только на manager узлах
docker service create \
  --constraint 'node.role==manager' \
  my-service

# На узлах с определенным label
docker service create \
  --constraint 'node.labels.disk==ssd' \
  database

# Несколько constraints
docker service create \
  --constraint 'node.role==worker' \
  --constraint 'node.labels.env==production' \
  app
```

### Update и Rollback Configuration

**Определение:**
Параметры для управления обновлениями сервисов.

```bash
docker service create \
  --update-delay 10s \
  --update-parallelism 2 \
  --update-failure-action rollback \
  --update-max-failure-ratio 0.1 \
  --rollback-parallelism 1 \
  my-service
```

**Параметры:**
- `update-delay` — задержка между обновлением групп задач
- `update-parallelism` — количество задач, обновляемых одновременно
- `update-failure-action` — действие при неудаче (pause, continue, rollback)
- `update-max-failure-ratio` — допустимый процент неудач

## Взаимосвязь сущностей

```
Cluster (Кластер)
├── Node (Узел)
│   ├── Manager Node
│   └── Worker Node
│       └── Task (Задача) — контейнер, выполняющий работу
│
├── Stack (Стек) — группа связанных сервисов
│   └── Service (Сервис) — описание приложения
│       ├── Task (Задача 1)
│       ├── Task (Задача 2)
│       └── Task (Задача N)
│
├── Network (Сеть) — связь между контейнерами
│   ├── Overlay Network
│   └── Ingress Network
│
├── Volume (Том) — persistent storage
│
├── Secret (Секрет) — чувствительные данные
│
└── Config (Конфигурация) — несекретная конфигурация
```

## Источники
- Docker Swarm Official Documentation
- Docker CLI Reference
- "Docker Deep Dive" by Nigel Poulton
- Docker Swarm Architecture diagrams
- Best practices guides for production Swarm deployments
