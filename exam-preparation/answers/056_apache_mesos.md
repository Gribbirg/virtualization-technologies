# Что такое Apache Mesos? Преимущества и недостатки Apache Mesos

## Краткий ответ
Apache Mesos — это распределенный планировщик ресурсов (resource manager) и кластерная система, абстрагирующая CPU, память, хранилище и другие вычислительные ресурсы, позволяя запускать различные типы workloads (контейнеры, big data задачи, долгоживущие сервисы) на одном кластере. Преимущества: двухуровневая архитектура, поддержка heterogeneous workloads, масштабируемость, fault tolerance. Недостатки: сложность, падение популярности, меньшая экосистема по сравнению с Kubernetes, требовательность к ресурсам.

## Развёрнутый ответ

### Что такое Apache Mesos

**Apache Mesos** — это открытая система управления ресурсами кластера, разработанная в UC Berkeley и переданная Apache Software Foundation. Mesos абстрагирует вычислительные ресурсы (CPU, память, диск) множества машин в единый ресурсный пул, позволяя различным фреймворкам эффективно разделять эти ресурсы.

**История:**
- 2009 — начало разработки в UC Berkeley
- 2013 — стал Apache Top-Level Project
- 2016 — пик популярности, использование Twitter, Apple, Airbnb
- 2019 — снижение развития и поддержки
- Настоящее время — проект в maintenance mode, фокус сообщества сместился на Kubernetes

**Философия:**
Mesos позиционируется как "distributed systems kernel" — ОС для датацентра, абстрагирующая ресурсы как традиционная OS абстрагирует hardware.

### Архитектура Mesos

**Двухуровневая архитектура:**

**Уровень 1: Mesos Masters и Agents**

**Mesos Master:**
- Управляет распределением ресурсов
- Поддерживает состояние кластера
- Координирует фреймворки
- Использует ZooKeeper для выбора лидера и хранения состояния
- Рекомендуется 3 или 5 мастеров для HA

**Mesos Agent (ранее Slave):**
- Работает на каждом узле кластера
- Отчитывается о доступных ресурсах (CPU, RAM, disk, ports)
- Запускает tasks, назначенные фреймворками
- Изолирует tasks через контейнеризацию (Docker, Mesos containerizer)

**Уровень 2: Frameworks**

**Framework** состоит из:
- **Scheduler** — принимает resource offers и запускает tasks
- **Executor** — запускается на agents для выполнения tasks

**Популярные фреймворки:**
- **Marathon** — для долгоживущих приложений (веб-сервисы, микросервисы)
- **Chronos** — для периодических и batch задач (cron-like)
- **Apache Aurora** — service scheduler от Twitter
- **Apache Spark** — big data processing
- **Apache Kafka** — streaming
- **Apache Hadoop** — MapReduce
- **Kubernetes on Mesos** — запуск K8s как фреймворка

### Как работает Mesos

**Resource Offer Model:**

1. **Agent отчитывается о ресурсах:**
   ```
   Agent 1: 4 CPUs, 16 GB RAM available
   Agent 2: 8 CPUs, 32 GB RAM available
   ```

2. **Master делает resource offers фреймворкам:**
   ```
   Master → Marathon: "Agent 1 has 4 CPUs, 16 GB RAM"
   ```

3. **Framework принимает или отклоняет offer:**
   ```
   Marathon → Master: "I'll take 2 CPUs, 8 GB RAM to launch task"
   ```

4. **Master инструктирует Agent запустить task:**
   ```
   Master → Agent 1: "Run Marathon's task with 2 CPUs, 8 GB RAM"
   ```

5. **Executor запускает task на Agent:**
   ```
   Agent запускает Docker контейнер или Mesos containerizer
   ```

**Модель распределения:**
- Mesos предлагает ресурсы фреймворкам
- Фреймворки решают, принять или отклонить
- Позволяет фреймворкам реализовывать свои политики размещения

### Компоненты экосистемы

**Marathon:**
- Наиболее популярный фреймворк для Mesos
- Для долгоживущих приложений
- REST API для управления
- Health checks и auto-restart
- Constraints для размещения

**Пример Marathon app definition:**
```json
{
  "id": "/my-app",
  "cmd": "python -m http.server 8080",
  "cpus": 1,
  "mem": 512,
  "disk": 0,
  "instances": 3,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "python:3",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 0,
          "protocol": "tcp"
        }
      ]
    }
  },
  "healthChecks": [
    {
      "protocol": "HTTP",
      "path": "/",
      "portIndex": 0,
      "gracePeriodSeconds": 300,
      "intervalSeconds": 60,
      "timeoutSeconds": 20,
      "maxConsecutiveFailures": 3
    }
  ]
}
```

**Chronos:**
- Cron-like scheduler
- Для batch jobs и периодических задач
- Зависимости между задачами
- Failure handling и retries

**DC/OS (Datacenter Operating System):**
- Коммерческий продукт на базе Mesos (от Mesosphere, позже D2iQ)
- Web UI, CLI, package management
- Упрощает управление Mesos кластером
- Каталог готовых сервисов (databases, monitoring, CI/CD)

### Основные возможности Mesos

**1. Resource Isolation:**
- Cgroups для CPU, memory
- Disk quotas
- Network isolation
- GPU support

**2. Fault Tolerance:**
- Master HA через ZooKeeper
- Автоматический failover
- Task health checking и restart

**3. Scalability:**
- Поддержка до 10,000+ узлов
- Миллионы tasks
- Эффективное использование ресурсов

**4. Multi-Tenancy:**
- Квоты и роли для разных teams
- Fair sharing или priority-based allocation
- Isolation между фреймворками

**5. API:**
- HTTP API для управления
- Scheduler API для создания фреймворков
- Operator API для администрирования

### Установка и управление

**Установка Mesos:**
```bash
# Ubuntu/Debian
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)

echo "deb http://repos.mesosphere.com/${DISTRO} ${CODENAME} main" | \
  sudo tee /etc/apt/sources.list.d/mesosphere.list
sudo apt-get update
sudo apt-get install mesos

# Запуск Master
sudo systemctl start mesos-master

# Запуск Agent
sudo systemctl start mesos-slave
```

**Через DC/OS:**
- Более простой путь — использовать DC/OS
- Provides web UI, CLI, unified experience
- Но DC/OS также больше не развивается активно

## Преимущества Apache Mesos

### 1. Двухуровневая архитектура

**Гибкость:**
- Фреймворки имеют полный контроль над scheduling
- Можно оптимизировать под специфичные workloads
- Различные фреймворки с разными стратегиями в одном кластере

**Расширяемость:**
- Легко создавать custom фреймворки
- Scheduler API хорошо документирован
- Можно адаптировать под уникальные требования

### 2. Поддержка heterogeneous workloads

**Разнообразие задач:**
- Long-running services (Marathon)
- Batch processing (Spark, Hadoop)
- Periodic jobs (Chronos)
- Streaming (Kafka, Storm)
- Machine Learning (TensorFlow)

**Эффективное мультиплексирование:**
- Запуск аналитики и production сервисов на одних узлах
- Динамическое распределение ресурсов
- Высокая утилизация кластера

### 3. Масштабируемость

**Proven at scale:**
- Twitter — десятки тысяч узлов
- Apple — production workloads
- Airbnb — data processing

**Performance:**
- Миллионы tasks
- Быстрое scheduling
- Эффективный resource allocation

### 4. Resource efficiency

**Fine-grained resource sharing:**
- Фреймворки запрашивают точное количество ресурсов
- Неиспользуемые ресурсы доступны другим
- Bin packing для максимальной утилизации

**Oversubscription:**
- Возможность использовать idle ресурсы
- Revocable resources для non-critical tasks

### 5. Fault tolerance

**High Availability:**
- Multiple masters с ZooKeeper
- Automatic failover
- No single point of failure

**Task resilience:**
- Автоматический restart failed tasks
- Health checking
- Placement constraints для распределения

### 6. Multi-tenancy

**Resource allocation:**
- Roles и quotas для teams/organizations
- Fair sharing policies
- Priority-based allocation

**Isolation:**
- Cgroups для resource isolation
- Network isolation
- Secure communication между компонентами

### 7. Proven in production

**Battle-tested:**
- Годы использования в крупных компаниях
- Стабильность и надежность
- Множество production deployments

### 8. Integration с Big Data ecosystem

**Native support:**
- Apache Spark on Mesos
- Hadoop on Mesos
- Kafka, Storm, Flink

**Data locality:**
- Учет расположения данных при scheduling
- Оптимизация для data-intensive workloads

## Недостатки Apache Mesos

### 1. Сложность

**Крутая кривая обучения:**
- Двухуровневая архитектура требует понимания
- Необходимость изучать фреймворки (Marathon, Chronos)
- ZooKeeper для HA добавляет сложности

**Operational overhead:**
- Управление masters, agents, ZooKeeper
- Настройка фреймворков
- Monitoring и debugging распределенной системы

### 2. Падение популярности

**Community decline:**
- Большинство контрибьюторов ушли
- Меньше новых features
- Фокус индустрии на Kubernetes

**Maintenance mode:**
- Проект не мертв, но развитие медленное
- Меньше community support
- Сложнее найти экспертов

**Mesosphere (D2iQ) переориентация:**
- D2iQ сфокусировалась на Kubernetes
- DC/OS в поддержке, но не активном развитии
- Уменьшение коммерческой поддержки

### 3. Меньшая экосистема

**По сравнению с Kubernetes:**
- Меньше готовых решений
- Меньше операторов и integrations
- Меньше tooling и UI

**Фреймворки требуют настройки:**
- Marathon, Chronos не так просты, как K8s
- Меньше documentation и examples

### 4. Container orchestration не primary focus

**Mesos — generic resource manager:**
- Контейнеры — один из типов workloads
- Kubernetes специализирован для контейнеров
- Меньше container-specific features

**Marathon vs Kubernetes:**
- Marathon менее feature-rich
- Нет аналогов StatefulSets, DaemonSets, Jobs, CronJobs
- Меньше встроенной функциональности

### 5. Сетевая конфигурация сложна

**CNI support ограничен:**
- Не такая богатая сетевая модель как в K8s
- Необходимость дополнительных инструментов

**Service discovery:**
- Требуется интеграция с Consul, Marathon-lb и т.д.
- Не так seamless как K8s Services

### 6. Ограниченный tooling

**CLI и UI:**
- Базовый Mesos UI
- DC/OS UI лучше, но DC/OS в decline
- Меньше сторонних tools

**Monitoring и logging:**
- Требуются внешние решения
- Нет встроенного Prometheus, Grafana

### 7. Требовательность к ресурсам

**Overhead компонентов:**
- Masters, Agents, ZooKeeper
- Фреймворки (Marathon, Chronos)
- Resource consumption может быть высоким

### 8. Deployment и upgrades сложны

**Сложность установки:**
- Множество компонентов для настройки
- Зависимость от ZooKeeper
- DC/OS упрощает, но сам по себе сложен

**Обновления:**
- Координация обновлений masters, agents, фреймворков
- Potential downtime
- Testing required

### 9. Отсутствие managed offerings

**Нет cloud providers:**
- AWS, GCP, Azure не предлагают managed Mesos
- Необходимость самостоятельного управления
- Больше операционной нагрузки

### 10. Vendor lock-in риски

**DC/OS dependency:**
- Многие использовали DC/OS для упрощения
- D2iQ (Mesosphere) переориентировалась
- Риск для production deployments

### 11. Kubernetes выиграл войну оркестраторов

**Industry standardization:**
- Kubernetes стал де-факто стандартом
- Больше инвестиций в K8s
- Миграция с Mesos на K8s — тренд

**Skills availability:**
- Больше Kubernetes экспертов на рынке
- Меньше Mesos вакансий
- Сложнее нанимать

## Когда (было) использовать Mesos

**Mesos был идеален для:**
- Унификации data analytics и production workloads
- Крупных кластеров (10,000+ узлов)
- Организаций с big data и microservices вместе
- Когда нужна максимальная утилизация ресурсов
- Custom scheduling requirements

**Сейчас рекомендуется:**
- **Для новых проектов:** Kubernetes
- **Для существующих Mesos deployments:** Рассмотреть миграцию на K8s
- **Исключения:** Legacy systems с глубокой интеграцией, где миграция нецелесообразна

## Миграция с Mesos на Kubernetes

**Стратегии:**
- **Big Bang:** Полная замена (рискованно)
- **Phased migration:** Постепенный перенос сервисов
- **Hybrid:** Kubernetes и Mesos side-by-side (temporary)

**Challenges:**
- Marathon apps → Kubernetes Deployments
- Chronos jobs → Kubernetes CronJobs
- Service discovery переконфигурация
- State migration для stateful apps

**Tools:**
- Некоторые инструменты для конвертации Marathon JSON → K8s YAML
- Но ручная работа неизбежна

## Альтернативы Mesos

**Для container orchestration:**
- **Kubernetes** — де-факто стандарт
- **Docker Swarm** — проще, но менее функционально
- **Nomad** — легковесная альтернатива

**Для big data:**
- **YARN (Hadoop)** — для Hadoop ecosystem
- **Kubernetes** — с операторами для Spark, Kafka, etc.
- **Serverless offerings** — AWS EMR, GCP Dataproc, Azure HDInsight

**Для унификации workloads:**
- **Kubernetes** с разнообразными controllers и operators

## История успеха и lessons learned

**Почему Mesos важен:**
- Pioneered распределенные системы concepts
- Двухуровневая архитектура вдохновила другие проекты
- Показал важность resource abstraction

**Почему Kubernetes победил:**
- Проще для container orchestration
- Лучшая экосистема и community
- Cloud providers поддержка
- CNCF backing
- Kubernetes решает 80% use cases "из коробки"

## Источники
- Apache Mesos Official Documentation
- Mesosphere (D2iQ) whitepapers and blog posts
- "Mesos in Action" by Roger Ignazio
- Twitter, Apple, Airbnb tech blogs on Mesos usage
- Post-mortems and migration stories from Mesos to Kubernetes
- Academic papers from UC Berkeley on Mesos design
