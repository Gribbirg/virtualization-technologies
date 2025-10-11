# Структура проекта - Практическая работа 4

## 📁 Организация файлов

```
practical-work-4/
│
├── 📘 README.md                    # Главная документация проекта
│
├── 📂 docs/                        # Вся документация
│   ├── START_HERE.md               # С чего начать (главный файл)
│   ├── VALIDATION_GUIDE.md         # Полный гайд по проверке требований
│   ├── CHEATSHEET.md               # Шпаргалка с командами
│   ├── QUICKSTART.md               # Быстрый старт за 3 шага
│   ├── CHECKLIST.md                # Чеклист выполнения
│   └── PROJECT_STRUCTURE.md        # Этот файл
│
├── 📂 scripts/                     # Все скрипты тестирования
│   ├── full-validation.sh          # ⭐ Главный скрипт - полная проверка
│   ├── test-monitoring.sh          # Тестирование мониторинга
│   ├── quick-test.sh               # Быстрая проверка без запуска
│   └── test-docker.sh              # Дополнительное тестирование
│
├── 📂 src/                         # Исходный код Spring Boot
│   ├── main/java/com/mirea/app/
│   │   ├── entity/                 # Модели: User, Product, Order
│   │   ├── repository/             # JPA репозитории
│   │   ├── controller/             # REST контроллеры
│   │   └── MireaApplication.java   # Главный класс
│   └── main/resources/
│       ├── application.yml         # Конфигурация Spring
│       └── logback-spring.xml      # Настройка логирования с GELF
│
├── 📂 monitoring/                  # Конфигурация систем мониторинга
│   ├── prometheus/
│   │   └── prometheus.yml          # Настройки Prometheus
│   └── grafana/
│       └── provisioning/
│           ├── datasources/        # Источники данных (Prometheus)
│           └── dashboards/         # Готовые дашборды
│
├── 📂 logs/                        # Файловые логи приложения
│
├── 🐳 docker-compose.yml           # Описание 13 сервисов
├── 🐳 Dockerfile                   # Multi-stage образ Spring Boot
└── 🔧 build.gradle.kts             # Зависимости проекта
```

## 🚀 С чего начать?

### 1. Для запуска и проверки:
```bash
./scripts/full-validation.sh
```

### 2. Для изучения проекта:
- **README.md** - основная документация
- **docs/START_HERE.md** - начните отсюда

### 3. Для защиты работы:
- **docs/VALIDATION_GUIDE.md** - как получить скриншоты
- **docs/CHEATSHEET.md** - команды для демонстрации

## 📊 Статистика

- **Документация:** 5 файлов в `docs/` (~47 KB)
- **Скрипты:** 4 файла в `scripts/` (~38 KB)
- **Исходный код:** 15 Java файлов (~1040 строк)
- **Конфигурация:** 8 YAML/XML файлов
- **Сервисов в Docker:** 13

## 🎯 Навигация

| Задача | Файл |
|--------|------|
| Быстро запустить | `scripts/full-validation.sh` |
| Понять структуру | `README.md` |
| Получить скриншоты | `docs/VALIDATION_GUIDE.md` |
| Команды для защиты | `docs/CHEATSHEET.md` |
| Проверить требования | `docs/CHECKLIST.md` |
| Быстрый старт | `docs/QUICKSTART.md` |

## 📝 Примечания

- Все скрипты имеют права на выполнение (chmod +x)
- Документация в Markdown формате
- Код без комментариев (согласно CLAUDE.md)
- README на английском, документация на русском
