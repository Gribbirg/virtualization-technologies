# Getting Started - Quick Guide

## Что уже сделано ✅

На данный момент создана **полная архитектура проекта** со всей необходимой документацией:

### 1. Документация проекта
- ✅ `README.md` - Главная документация проекта
- ✅ `PROJECT_STRUCTURE.md` - Полная структура файлов
- ✅ `docs/ARCHITECTURE.md` - Архитектура системы с диаграммами
- ✅ `docs/PROJECT_OVERVIEW.md` - Обзор проекта, оценка времени
- ✅ `docs/SERVICES_LIST.md` - Детальное описание всех 15 сервисов

### 2. Промпты для реализации (PROMPT.md)
- ✅ `auth-service/docs/PROMPT.md` - Полный гайд по Auth Service
- ✅ `task-service/docs/PROMPT.md` - Полный гайд по Task Service
- ✅ `notification-service/docs/PROMPT.md` - Полный гайд по Notification Service
- ✅ `infrastructure/docs/PROMPT.md` - Полный гайд по инфраструктуре

### 3. Структура директорий
- ✅ Созданы все необходимые поддиректории
- ✅ Определена структура для каждого микросервиса
- ✅ Определена структура для инфраструктуры

## Что нужно сделать дальше 📋

### Этап 1: Инфраструктура (Неделя 1)

**Цель**: Развернуть все инфраструктурные сервисы в Minikube

**Файл с инструкциями**: `infrastructure/docs/PROMPT.md`

**Задачи**:
1. Создать Helm charts для PostgreSQL (3 инстанса)
2. Создать Helm chart для Redis
3. Создать Helm chart для Kafka
4. Создать Helm chart для Graylog stack (Graylog + MongoDB + Elasticsearch)
5. Создать Helm chart для Prometheus
6. Создать Helm chart для Grafana
7. Создать Helm chart для Jaeger
8. Создать Helm chart для KrakenD
9. Создать скрипты развертывания
10. Протестировать инфраструктуру

**Оценка времени**: 20-25 часов

### Этап 2: Auth Service (Неделя 1-2)

**Цель**: Реализовать сервис аутентификации

**Файл с инструкциями**: `auth-service/docs/PROMPT.md`

**Задачи**:
1. Создать проект Spring Boot + Kotlin
2. Реализовать модель User (JPA Entity)
3. Реализовать UserRepository
4. Реализовать AuthService (регистрация, логин, валидация)
5. Реализовать TokenService (JWT + Redis)
6. Реализовать KafkaProducerService
7. Реализовать AuthController (REST API)
8. Настроить логирование (Graylog GELF)
9. Настроить метрики (Prometheus)
10. Написать unit тесты (80%+ coverage)
11. Создать Dockerfile
12. Создать Helm chart
13. Развернуть в Minikube

**Оценка времени**: 13-17 часов

### Этап 3: Task Service (Неделя 2)

**Цель**: Реализовать сервис управления задачами

**Файл с инструкциями**: `task-service/docs/PROMPT.md`

**Задачи**:
1. Создать проект Spring Boot + Kotlin
2. Реализовать модель Task (JPA Entity)
3. Реализовать TaskRepository
4. Реализовать TaskService (CRUD операции)
5. Реализовать AuthClientService (интеграция с Auth Service)
6. Реализовать KafkaProducerService
7. Реализовать TaskController (REST API)
8. Настроить логирование и метрики
9. Написать unit тесты (80%+ coverage)
10. Создать Dockerfile
11. Создать Helm chart
12. Развернуть в Minikube

**Оценка времени**: 11-15 часов

### Этап 4: Notification Service (Неделя 2)

**Цель**: Реализовать сервис уведомлений

**Файл с инструкциями**: `notification-service/docs/PROMPT.md`

**Задачи**:
1. Создать проект Spring Boot + Kotlin
2. Реализовать модель Notification (JPA Entity)
3. Реализовать NotificationRepository
4. Реализовать NotificationService
5. Реализовать KafkaConsumerService (слушать события)
6. Реализовать NotificationController (REST API)
7. Настроить логирование и метрики
8. Написать unit тесты (80%+ coverage)
9. Создать Dockerfile
10. Создать Helm chart
11. Развернуть в Minikube

**Оценка времени**: 8-12 часов

### Этап 5: Интеграция и тестирование (Неделя 3)

**Задачи**:
1. Настроить KrakenD для маршрутизации
2. Протестировать полный flow через API Gateway
3. Проверить работу Kafka (события между сервисами)
4. Проверить логи в Graylog
5. Проверить метрики в Prometheus/Grafana
6. Проверить трейсы в Jaeger
7. Протестировать Persistent Volumes (удалить pod, проверить данные)
8. Протестировать HPA (создать нагрузку, проверить масштабирование)
9. Собрать скриншоты для отчета

**Оценка времени**: 15-20 часов

### Этап 6: Отчет (Неделя 3-4)

**Задачи**:
1. Написать отчет в Markdown
2. Добавить все скриншоты
3. Описать конфигурационные файлы
4. Показать работу системы
5. Конвертировать в DOCX
6. Конвертировать в PDF
7. Подготовить ответы на вопросы

**Оценка времени**: 10-15 часов

## Как начать работу

### Вариант 1: Последовательная реализация (рекомендуется)

```bash
# 1. Начните с инфраструктуры
cd infrastructure
# Откройте docs/PROMPT.md и следуйте инструкциям

# 2. После развертывания инфраструктуры - Auth Service
cd ../auth-service
# Откройте docs/PROMPT.md и следуйте инструкциям

# 3. Затем Task Service
cd ../task-service
# Откройте docs/PROMPT.md и следуйте инструкциям

# 4. Затем Notification Service
cd ../notification-service
# Откройте docs/PROMPT.md и следуйте инструкциям

# 5. Интеграция и тестирование
cd ..
# Используйте скрипты из scripts/
```

### Вариант 2: Параллельная разработка (если работаете в команде)

**Разработчик 1**: Инфраструктура + KrakenD  
**Разработчик 2**: Auth Service  
**Разработчик 3**: Task Service + Notification Service  

После завершения - интеграция всех компонентов.

## Ключевые файлы для каждого этапа

### Инфраструктура
- 📖 `infrastructure/docs/PROMPT.md` - **НАЧНИТЕ ЗДЕСЬ**
- 📖 `docs/SERVICES_LIST.md` - Описание всех сервисов
- 📖 `docs/ARCHITECTURE.md` - Архитектура системы

### Auth Service
- 📖 `auth-service/docs/PROMPT.md` - **НАЧНИТЕ ЗДЕСЬ**
- 📄 API контракт - в PROMPT.md
- 📄 Database schema - в PROMPT.md
- 📄 Kafka events - в PROMPT.md

### Task Service
- 📖 `task-service/docs/PROMPT.md` - **НАЧНИТЕ ЗДЕСЬ**
- 📄 API контракт - в PROMPT.md
- 📄 Database schema - в PROMPT.md
- 📄 Kafka events - в PROMPT.md

### Notification Service
- 📖 `notification-service/docs/PROMPT.md` - **НАЧНИТЕ ЗДЕСЬ**
- 📄 API контракт - в PROMPT.md
- 📄 Database schema - в PROMPT.md
- 📄 Kafka consumer - в PROMPT.md

## Важные замечания

### ⚠️ Минимализм
- Реализуйте **только** то, что указано в PROMPT.md
- Не добавляйте лишний функционал
- Цель - выполнить требования задания, не больше

### ⚠️ Тестирование
- Минимум 80% покрытие unit тестами
- Обязательно тестируйте бизнес-логику
- Используйте MockK для Kotlin

### ⚠️ Конфигурация
- Все чувствительные данные - в Kubernetes Secrets
- Используйте environment variables
- Не хардкодите значения

### ⚠️ Логирование
- Логируйте HTTP method, URL, IP address
- Используйте GELF appender для Graylog
- Логируйте все важные операции

### ⚠️ Метрики
- Используйте Spring Boot Actuator
- Экспортируйте метрики для Prometheus
- Добавляйте custom метрики для бизнес-логики

### ⚠️ Health Probes
- Обязательно настройте liveness, readiness, startup probes
- Используйте `/actuator/health/*` endpoints
- Проверьте, что probes работают

## Чеклист перед защитой

### Функциональность
- [ ] Пользователь может зарегистрироваться
- [ ] Пользователь может войти (получить JWT)
- [ ] Пользователь может создать задачу
- [ ] Пользователь может просмотреть задачи
- [ ] Пользователь может обновить задачу
- [ ] Пользователь может удалить задачу
- [ ] Пользователь получает уведомления
- [ ] Все запросы идут через KrakenD

### Инфраструктура
- [ ] Все 3 PostgreSQL работают с Persistent Volumes
- [ ] Redis хранит JWT токены
- [ ] Kafka передает события между сервисами
- [ ] Graylog получает логи от всех сервисов
- [ ] Prometheus собирает метрики
- [ ] Grafana показывает дашборды
- [ ] Jaeger показывает трейсы

### Kubernetes
- [ ] Все поды запущены и healthy
- [ ] HPA настроен и работает (проверить под нагрузкой)
- [ ] Health probes настроены
- [ ] Resource limits установлены
- [ ] Persistent Volumes работают (удалить pod, данные остались)

### Документация
- [ ] Отчет написан
- [ ] Скриншоты собраны
- [ ] Конфигурационные файлы показаны
- [ ] Ответы на вопросы подготовлены

## Оценка времени

| Этап | Минимум | Максимум |
|------|---------|----------|
| Инфраструктура | 20 часов | 25 часов |
| Auth Service | 13 часов | 17 часов |
| Task Service | 11 часов | 15 часов |
| Notification Service | 8 часов | 12 часов |
| Интеграция и тестирование | 15 часов | 20 часов |
| Отчет | 10 часов | 15 часов |
| **ИТОГО** | **77 часов** | **104 часа** |

**Реалистичная оценка**: 2-3 недели полной занятости

## Полезные команды

### Minikube
```bash
# Запуск
minikube start --driver=docker --cpus=4 --memory=8192

# Статус
minikube status

# Остановка
minikube stop

# Удаление
minikube delete
```

### Kubectl
```bash
# Просмотр подов
kubectl get pods -n task-management

# Просмотр сервисов
kubectl get svc -n task-management

# Просмотр PVC
kubectl get pvc -n task-management

# Логи пода
kubectl logs <pod-name> -n task-management

# Описание пода
kubectl describe pod <pod-name> -n task-management
```

### Helm
```bash
# Установка
helm install <name> ./helm/<chart> -n task-management

# Обновление
helm upgrade <name> ./helm/<chart> -n task-management

# Удаление
helm uninstall <name> -n task-management

# Список установленных
helm list -n task-management
```

## Следующий шаг

**Откройте файл**: `infrastructure/docs/PROMPT.md`

Это ваша отправная точка. Следуйте инструкциям шаг за шагом.

Удачи! 🚀

