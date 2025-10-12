# Инструкции по получению скриншотов для отчета

Данный документ содержит пошаговые инструкции по получению всех необходимых скриншотов для отчета по практической работе 4.

## Предварительная подготовка

### 1. Запуск системы

```bash
cd /Users/alexgribkov/study/virtualization-technologies/practical-work-4
docker-compose up -d --build
```

### 2. Ожидание запуска всех сервисов

Подождите 2-3 минуты для полного запуска всех контейнеров, особенно GrayLog требует времени для инициализации.

```bash
# Проверка статуса
docker-compose ps
```

### 3. Проверка готовности сервисов

```bash
# Spring Boot
curl http://localhost:8090/actuator/health

# Prometheus
curl http://localhost:9090/-/healthy

# Grafana
curl http://localhost:3000/api/health
```

---

## Список необходимых скриншотов

### Скриншот 1: Структура проекта с моделями данных

**Местоположение в отчете:** Раздел "Разработка моделей данных Spring Boot приложения"

**Что показать:**
- Структура директорий проекта в IDE или файловом менеджере
- Папка `src/main/java/com/mirea/app/entity/` с файлами User.java, Product.java, Order.java

**Как получить:**
1. Откройте проект в IntelliJ IDEA или VS Code
2. Раскройте дерево директорий до `src/main/java/com/mirea/app/`
3. Убедитесь, что видна папка `entity` с тремя файлами моделей
4. Сделайте скриншот области Project Explorer

**Альтернативный способ (терминал):**
```bash
tree src/main/java/com/mirea/app/entity/
```

---

### Скриншот 2: Исходный код UserController

**Местоположение в отчете:** Раздел "Реализация CRUD контроллеров"

**Что показать:**
- Открытый файл UserController.java с видимыми аннотациями
- CRUD методы: createUser, getAllUsers, updateUser, deleteUser

**Как получить:**
1. Откройте файл `src/main/java/com/mirea/app/controller/UserController.java` в редакторе
2. Прокрутите до метода createUser с аннотацией @PostMapping
3. Убедитесь, что в кадре видны несколько CRUD методов
4. Сделайте скриншот редактора кода

---

### Скриншот 3: Пример CSV файла с экспортированными логами

**Местоположение в отчете:** Раздел "Реализация эндпоинта экспорта логов"

**Что показать:**
- Содержимое CSV файла с логами операций
- Колонки: Timestamp, Level, Logger, Message
- Несколько строк с записями о создании/обновлении/удалении

**Как получить:**
```bash
# Экспорт логов
curl http://localhost:8090/api/logs/mock-export -o database_operations.csv

# Просмотр содержимого
cat database_operations.csv
```

**Или откройте файл в Excel/LibreOffice Calc:**
1. Откройте файл `database_operations.csv`
2. Убедитесь, что видны заголовки и несколько строк данных
3. Сделайте скриншот таблицы

---

### Скриншот 4: Процесс сборки Docker образа

**Местоположение в отчете:** Раздел "Создание многоэтапного Dockerfile"

**Что показать:**
- Вывод команды docker-compose build с процессом сборки
- Этапы: FROM gradle, RUN gradle build, FROM eclipse-temurin

**Как получить:**
```bash
# Пересборка с выводом логов
docker-compose build --no-cache spring-app
```

**Альтернативно - показать Dockerfile:**
1. Откройте файл `Dockerfile` в редакторе
2. Убедитесь, что видны оба этапа FROM
3. Сделайте скриншот всего файла

---

### Скриншот 5: Структура docker-compose.yml

**Местоположение в отчете:** Раздел "Настройка docker-compose конфигурации"

**Что показать:**
- Файл docker-compose.yml открытый в редакторе
- Видимые сервисы: postgres, spring-app, prometheus, grafana
- Секции: services, volumes, networks

**Как получить:**
1. Откройте файл `docker-compose.yml` в редакторе
2. Прокрутите к началу файла со списком сервисов
3. Сделайте скриншот, показывающий структуру файла

---

### Скриншот 6: Вывод команды docker-compose ps

**Местоположение в отчете:** Раздел "Запуск системы мониторинга"

**Что показать:**
- Список всех запущенных контейнеров (13 штук)
- Статус "Up" для всех контейнеров
- Опубликованные порты

**Как получить:**
```bash
docker-compose ps
```

Сделайте скриншот терминала с выводом команды.

---

### Скриншот 7: Выполнение CRUD запросов в терминале

**Местоположение в отчете:** Раздел "Проверка CRUD операций"

**Что показать:**
- Терминал с выполненными curl командами
- Ответы сервера в формате JSON с созданными объектами

**Как получить:**
```bash
# Создание пользователя
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ivanov",
    "email": "ivanov@mirea.ru",
    "firstName": "Иван",
    "lastName": "Иванов"
  }'

# Создание продукта
curl -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ноутбук ASUS",
    "description": "Игровой ноутбук",
    "price": 85000.00,
    "stock": 5
  }'

# Получение всех пользователей
curl http://localhost:8090/api/users
```

Сделайте скриншот терминала, показывающий команды и ответы.

---

### Скриншот 8: Adminer с таблицами базы данных и данными

**Местоположение в отчете:** Раздел "Проверка CRUD операций"

**Что показать:**
- Веб-интерфейс Adminer
- Список таблиц: users, products, orders, order_products
- Содержимое одной из таблиц с данными

**Как получить:**
1. Откройте браузер: http://localhost:8080
2. Введите данные подключения:
   - Система: PostgreSQL
   - Сервер: postgres
   - Пользователь: mirea_user
   - Пароль: mirea_password
   - База данных: mirea_db
3. Нажмите "Войти"
4. Сделайте скриншот списка таблиц
5. Откройте таблицу "users" и сделайте скриншот с данными

---

### Скриншот 9: Prometheus Targets со статусом UP

**Местоположение в отчете:** Раздел "Настройка Prometheus для сбора метрик"

**Что показать:**
- Страница Prometheus Targets
- Все targets (spring-boot, postgres-exporter, prometheus) со статусом UP
- Endpoint URLs и Last Scrape

**Как получить:**
1. Откройте браузер: http://localhost:9090
2. Перейдите: Status → Targets
3. Дождитесь, пока все targets станут UP (зеленые)
4. Сделайте скриншот страницы

---

### Скриншот 10: Grafana datasource с подключением к Prometheus

**Местоположение в отчете:** Раздел "Настройка Grafana для визуализации метрик"

**Что показать:**
- Страница Configuration → Data Sources в Grafana
- Prometheus в списке источников данных
- Зеленая галочка или статус "Working"

**Как получить:**
1. Откройте браузер: http://localhost:3000
2. Войдите: admin / admin (пропустите смену пароля)
3. Перейдите: Configuration (⚙️) → Data Sources
4. Найдите Prometheus в списке
5. Сделайте скриншот страницы со списком datasources

---

### Скриншот 11: Grafana dashboard с графиками метрик

**Местоположение в отчете:** Раздел "Настройка Grafana для визуализации метрик"

**Что показать:**
- Открытый дашборд "MIREA Spring Boot Monitoring"
- Несколько панелей с графиками (JVM Memory, HTTP Requests, etc.)
- Данные на графиках

**Как получить:**
1. В Grafana перейдите: Dashboards → Browse
2. Найдите и откройте "MIREA Spring Boot Monitoring"
3. Подождите загрузки данных на графиках
4. Если данных нет - выполните несколько CRUD запросов
5. Сделайте скриншот дашборда с видимыми графиками

**Если нужно сгенерировать нагрузку:**
```bash
for i in {1..20}; do
  curl http://localhost:8090/api/users > /dev/null 2>&1
  sleep 1
done
```

---

### Скриншот 12: GrayLog Search с логами приложения

**Местоположение в отчете:** Раздел "Настройка GrayLog для сбора логов"

**Что показать:**
- Страница Search в GrayLog
- Логи с application:mirea-spring-app
- Несколько записей о CRUD операциях

**Как получить:**
1. Откройте браузер: http://localhost:9000
2. Войдите: admin / admin
3. Дождитесь полной загрузки (2-3 минуты при первом запуске)
4. Перейдите: Search
5. В поле поиска введите: `application:mirea-spring-app`
6. Нажмите поиск
7. Сделайте скриншот списка логов

**Если логов нет:**
```bash
# Выполните несколько операций для генерации логов
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.ru","firstName":"Test","lastName":"User"}'
```

---

### Скриншот 13: Zabbix веб-интерфейс

**Местоположение в отчете:** Раздел "Развертывание системы Zabbix"

**Что показать:**
- Главная страница Zabbix или страница Monitoring
- Меню и основной интерфейс

**Как получить:**
1. Откройте браузер: http://localhost:8081
2. Войдите: Admin / zabbix (обратите внимание: Admin с большой буквы)
3. Дождитесь загрузки главной страницы
4. Сделайте скриншот главной страницы или перейдите в Monitoring → Latest data

---

### Скриншот 14: Adminer - список таблиц основной БД без таблиц мониторинга

**Местоположение в отчете:** Раздел "Проверка изоляции баз данных"

**Что показать:**
- Список таблиц базы данных mirea_db
- Только 4 таблицы: users, products, orders, order_products
- Отсутствие таблиц zabbix или graylog

**Как получить:**
1. В Adminer (уже открыт из скриншота 8)
2. Убедитесь, что выбрана база mirea_db
3. Посмотрите список таблиц на главной странице
4. Сделайте скриншот, показывающий только таблицы приложения

---

## Порядок создания скриншотов

Рекомендуется делать скриншоты в следующем порядке:

1. **До запуска системы:**
   - Скриншот 1: Структура проекта
   - Скриншот 2: Исходный код UserController
   - Скриншот 4: Dockerfile или процесс сборки
   - Скриншот 5: docker-compose.yml

2. **После запуска системы:**
   - Скриншот 6: docker-compose ps
   
3. **Выполнение CRUD операций:**
   - Скриншот 7: Выполнение curl запросов
   - Скриншот 8: Adminer с данными
   - Скриншот 3: Экспорт CSV

4. **Проверка систем мониторинга:**
   - Скриншот 9: Prometheus Targets
   - Скриншот 10: Grafana datasource
   - Скриншот 11: Grafana dashboard
   - Скриншот 12: GrayLog Search
   - Скриншот 13: Zabbix
   - Скриншот 14: Adminer - изоляция БД

---

## Советы по созданию скриншотов

### Качество изображений
- Используйте разрешение экрана не менее 1920x1080
- Убедитесь, что текст читаем
- Избегайте скриншотов с размытым текстом

### Содержимое
- Убирайте лишние окна и вкладки браузера
- Оставляйте только релевантную информацию
- Проверяйте, что все важные элементы попали в кадр

### Формат файлов
- Сохраняйте в PNG для лучшего качества текста
- Называйте файлы описательно: `01_project_structure.png`
- Размещайте в директории `screenshots/`

### Если что-то не работает
- Проверьте логи контейнера: `docker-compose logs [service-name]`
- Перезапустите проблемный сервис: `docker-compose restart [service-name]`
- Обратитесь к документации в `README.md` или `docs/VALIDATION_GUIDE.md`

---

## Быстрая проверка всех сервисов

```bash
#!/bin/bash
echo "=== Проверка доступности сервисов ==="

echo -n "Spring Boot: "
curl -s http://localhost:8090/actuator/health | grep -q "UP" && echo "✅ OK" || echo "❌ FAIL"

echo -n "Adminer: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200" && echo "✅ OK" || echo "❌ FAIL"

echo -n "Prometheus: "
curl -s http://localhost:9090/-/healthy | grep -q "Prometheus" && echo "✅ OK" || echo "❌ FAIL"

echo -n "Grafana: "
curl -s http://localhost:3000/api/health | grep -q "ok" && echo "✅ OK" || echo "❌ FAIL"

echo -n "GrayLog: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200" && echo "✅ OK" || echo "❌ FAIL"

echo -n "Zabbix: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200" && echo "✅ OK" || echo "❌ FAIL"

echo "=== Проверка завершена ==="
```

Сохраните этот скрипт как `check-services.sh`, дайте права на выполнение (`chmod +x check-services.sh`) и запустите для проверки готовности всех сервисов.

---

## Остановка системы после получения скриншотов

```bash
# Остановить все контейнеры
docker-compose down

# Остановить и удалить все данные (если нужно начать заново)
docker-compose down -v
```

---

Удачи в создании скриншотов! 📸

