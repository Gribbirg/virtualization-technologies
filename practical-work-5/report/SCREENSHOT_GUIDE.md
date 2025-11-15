# Руководство по созданию скриншотов для отчета

Этот документ содержит все команды и инструкции для создания скриншотов, необходимых для практической работы 5.

## Подготовка

Перед началом убедитесь, что у вас установлены:
- Docker
- Minikube
- kubectl

Все команды выполняются из директории `practical-work-5/`.

---

## Скриншот 1: Запуск Minikube кластера

**Команда:**
```bash
minikube start
```

**Что показать на скриншоте:**
- Процесс запуска Minikube
- Сообщение об успешном запуске кластера
- Информация о версии Kubernetes

**Описание для отчета:** "Запуск Minikube кластера"

---

## Скриншот 2: Проверка статуса Minikube

**Команда:**
```bash
minikube status
```

**Что показать на скриншоте:**
- Статус Minikube (running)
- Статус kubelet (running)
- Статус apiserver (running)
- Статус kubeconfig (configured)

**Описание для отчета:** "Проверка статуса Minikube"

---

## Скриншот 3: Настройка Docker окружения для Minikube

**Команда:**
```bash
eval $(minikube docker-env)
echo "Docker environment configured for Minikube"
```

**Что показать на скриншоте:**
- Выполнение команды eval
- Подтверждающее сообщение

**Описание для отчета:** "Настройка Docker окружения для Minikube"

---

## Скриншот 4: Сборка Docker-образа

**Команда:**
```bash
docker build -t gribkov-ikbo-16-22-obraz .
```

**Что показать на скриншоте:**
- Процесс сборки образа
- Все шаги Dockerfile (FROM, EXPOSE, COPY, CMD)
- Сообщение об успешной сборке (Successfully tagged)

**Описание для отчета:** "Сборка Docker-образа"

---

## Скриншот 5: Проверка созданного Docker-образа

**Команда:**
```bash
docker images | grep gribkov
```

или полный список:
```bash
docker images
```

**Что показать на скриншоте:**
- Строку с образом gribkov-ikbo-16-22-obraz
- Repository, Tag, Image ID, Created, Size

**Описание для отчета:** "Проверка созданного Docker-образа"

---

## Скриншот 6: Применение манифеста Deployment

**Команда:**
```bash
kubectl apply -f deployment.yaml
```

**Что показать на скриншоте:**
- Команду kubectl apply
- Сообщение "deployment.apps/gribkov-ikbo-16-22 created"

**Описание для отчета:** "Применение манифеста Deployment"

---

## Скриншот 7: Список Deployments в кластере

**Команда:**
```bash
kubectl get deployments
```

**Что показать на скриншоте:**
- Таблицу с колонками: NAME, READY, UP-TO-DATE, AVAILABLE, AGE
- Строку с deployment gribkov-ikbo-16-22
- Статус READY должен быть 1/1

**Описание для отчета:** "Список Deployments в кластере"

---

## Скриншот 8: Список Pods в кластере

**Команда:**
```bash
kubectl get pods
```

**Что показать на скриншоте:**
- Таблицу с колонками: NAME, READY, STATUS, RESTARTS, AGE
- Pod с именем gribkov-ikbo-16-22-*
- STATUS должен быть "Running"
- READY должен быть 1/1

**Описание для отчета:** "Список Pods в кластере"

---

## Скриншот 9: События кластера Kubernetes

**Команда:**
```bash
kubectl get events --sort-by='.lastTimestamp'
```

или просто:
```bash
kubectl get events
```

**Что показать на скриншоте:**
- Список событий кластера
- События, связанные с созданием Deployment и Pods
- TYPE, REASON, OBJECT, MESSAGE

**Описание для отчета:** "События кластера Kubernetes"

---

## Скриншот 10: Конфигурация kubectl

**Команда:**
```bash
kubectl config view
```

**Что показать на скриншоте:**
- YAML конфигурацию kubectl
- Секции: clusters, contexts, current-context, users
- Информацию о Minikube кластере

**Описание для отчета:** "Конфигурация kubectl"

---

## Скриншот 11: Создание Service типа NodePort

**Команда:**
```bash
kubectl expose deployment gribkov-ikbo-16-22 --type=NodePort --port=8080
```

**Что показать на скриншоте:**
- Команду kubectl expose
- Сообщение "service/gribkov-ikbo-16-22 exposed"

**Описание для отчета:** "Создание Service типа NodePort"

---

## Скриншот 12: Список Services в кластере

**Команда:**
```bash
kubectl get services
```

или с подробностями:
```bash
kubectl get services -o wide
```

**Что показать на скриншоте:**
- Таблицу с сервисами
- Service gribkov-ikbo-16-22 с TYPE=NodePort
- PORT(S) колонку, показывающую 8080:3XXXX/TCP
- Также должен быть service kubernetes (ClusterIP)

**Описание для отчета:** "Список Services в кластере"

---

## Скриншот 13: Открытие сервиса через Minikube

**Команда:**
```bash
minikube service gribkov-ikbo-16-22
```

**Что показать на скриншоте:**
- Выполнение команды
- URL сервиса (http://192.168.xx.xx:3XXXX)
- Сообщение об открытии в браузере по умолчанию

**Описание для отчета:** "Открытие сервиса через Minikube"

---

## Скриншот 14: Тестирование работы веб-приложения

**Вариант 1 - через curl:**
```bash
curl $(minikube service gribkov-ikbo-16-22 --url)
```

**Вариант 2 - в браузере:**
Откройте URL из предыдущей команды в браузере

**Что показать на скриншоте:**
- Ответ "Hello World!" от сервера
- Для curl: команду и вывод в терминале
- Для браузера: страницу с текстом "Hello World!"

**Описание для отчета:** "Тестирование работы веб-приложения"

---

## Скриншот 15: Список дополнений Minikube

**Команда:**
```bash
minikube addons list
```

**Что показать на скриншоте:**
- Полный список addons
- Статус каждого addon (enabled/disabled)
- Особое внимание на ingress (должен быть disabled на данном этапе)

**Описание для отчета:** "Список дополнений Minikube"

---

## Скриншот 16: Включение дополнения ingress

**Команда:**
```bash
minikube addons enable ingress
```

**Что показать на скриншоте:**
- Команду enable ingress
- Процесс включения
- Сообщение об успешном включении

**Описание для отчета:** "Включение дополнения ingress"

---

## Скриншот 17: Pods и Services в namespace kube-system

**Команда:**
```bash
kubectl get pod,svc -n kube-system
```

или для ingress-nginx (в зависимости от версии):
```bash
kubectl get pod,svc -n ingress-nginx
```

**Что показать на скриншоте:**
- Список Pods и Services в системном namespace
- Pods ingress-nginx-controller
- Их статус (Running)

**Описание для отчета:** "Pods и Services в namespace kube-system"

---

## Скриншот 18: Отключение дополнения ingress

**Команда:**
```bash
minikube addons disable ingress
```

**Что показать на скриншоте:**
- Команду disable ingress
- Сообщение об успешном отключении

**Описание для отчета:** "Отключение дополнения ingress"

---

## Скриншот 19: Запуск Kubernetes Dashboard

**Команда:**
```bash
minikube dashboard
```

**Что показать на скриншоте:**
- Команду запуска Dashboard
- URL Dashboard
- Сообщение об открытии в браузере

**Описание для отчета:** "Запуск Kubernetes Dashboard"

---

## Скриншот 20: Раздел Deployments в Kubernetes Dashboard

**Шаги:**
1. Откройте Dashboard (команда выше)
2. В левом меню выберите "Workloads" → "Deployments"
3. Найдите deployment gribkov-ikbo-16-22

**Что показать на скриншоте:**
- Веб-интерфейс Dashboard
- Список Deployments
- Deployment gribkov-ikbo-16-22 с его параметрами:
  - Name, Namespace, Labels
  - Pods (1/1 running)
  - Age

**Описание для отчета:** "Раздел Deployments в Kubernetes Dashboard"

---

## Скриншот 21: Детальная информация о Deployment

**Шаги:**
1. В Dashboard кликните на deployment gribkov-ikbo-16-22
2. Просмотрите детальную информацию

**Что показать на скриншоте:**
- Детальную страницу Deployment
- Параметры:
  - Replica count (1)
  - Pod status
  - Container image (gribkov-ikbo-16-22-obraz)
  - Labels и Selectors (app=gribkov-ikbo-16-22)
  - Strategy (RollingUpdate)
  - Events
  - Pod Template
  - Conditions

**Описание для отчета:** "Детальная информация о Deployment"

---

## Скриншот 22: Удаление Service

**Команда:**
```bash
kubectl delete service gribkov-ikbo-16-22
```

**Что показать на скриншоте:**
- Команду delete service
- Сообщение "service/gribkov-ikbo-16-22 deleted"

**Описание для отчета:** "Удаление Service"

---

## Скриншот 23: Удаление Deployment

**Команда:**
```bash
kubectl delete deployment gribkov-ikbo-16-22
```

**Что показать на скриншоте:**
- Команду delete deployment
- Сообщение "deployment.apps/gribkov-ikbo-16-22 deleted"

**Описание для отчета:** "Удаление Deployment"

---

## Скриншот 24: Остановка кластера Minikube

**Команда:**
```bash
minikube stop
```

**Что показать на скриншоте:**
- Команду minikube stop
- Процесс остановки кластера
- Сообщение об успешной остановке

**Описание для отчета:** "Остановка кластера Minikube"

---

## Полный сценарий выполнения

Вот полный список команд в правильном порядке для выполнения всей работы:

```bash
# 1. Запуск Minikube
minikube start
minikube status

# 2. Подготовка Docker-образа
eval $(minikube docker-env)
docker build -t gribkov-ikbo-16-22-obraz .
docker images | grep gribkov

# 3. Создание Deployment
kubectl apply -f deployment.yaml

# 4. Просмотр информации о кластере
kubectl get deployments
kubectl get pods
kubectl get events
kubectl config view

# 5. Создание Service
kubectl expose deployment gribkov-ikbo-16-22 --type=NodePort --port=8080
kubectl get services

# 6. Тестирование
minikube service gribkov-ikbo-16-22
curl $(minikube service gribkov-ikbo-16-22 --url)

# 7. Работа с addons
minikube addons list
minikube addons enable ingress
kubectl get pod,svc -n kube-system
minikube addons disable ingress

# 8. Dashboard
minikube dashboard
# (откройте в браузере и сделайте скриншоты)

# 9. Cleanup
kubectl delete service gribkov-ikbo-16-22
kubectl delete deployment gribkov-ikbo-16-22
minikube stop
```

---

## Советы по созданию скриншотов

1. **Размер окна терминала**: Используйте достаточно широкое окно терминала, чтобы команды и вывод не переносились на следующую строку

2. **Контрастность**: Убедитесь, что текст хорошо читается на фоне

3. **Полнота информации**: Захватывайте не только результат команды, но и саму команду

4. **Качество**: Используйте достаточное разрешение для читаемости текста

5. **Консистентность**: Используйте одну и ту же тему терминала для всех скриншотов

6. **Dashboard**: Для Dashboard используйте полноэкранный режим браузера или достаточно большое окно

7. **Нумерация**: Сохраняйте скриншоты с осмысленными именами (например, `01-minikube-start.png`, `02-minikube-status.png` и т.д.)

---

## Замечания

- Некоторые номера портов (например, NodePort) будут динамически назначаться и могут отличаться при каждом запуске
- IP-адреса также могут отличаться в зависимости от конфигурации Minikube
- Время выполнения команд может варьироваться
- Убедитесь, что у вас достаточно свободных ресурсов (CPU, RAM) для работы Minikube

---

## Проверка перед отправкой отчета

- [ ] Все 24 скриншота созданы
- [ ] Скриншоты четкие и читаемые
- [ ] На каждом скриншоте видна выполняемая команда
- [ ] Скриншоты вставлены в правильные места в Word документе
- [ ] Подписи к скриншотам соответствуют содержимому
- [ ] Нумерация рисунков корректна
- [ ] Форматирование документа соответствует требованиям
