# Task 2: Spring Boot + PostgreSQL Web Application

Spring Boot веб-приложение с PostgreSQL базой данных, реализованное с помощью multi-stage Docker сборки.

## Features

- **Spring Boot REST API** с тремя эндпоинтами
- **PostgreSQL** интеграция через JPA/Hibernate
- **Multi-stage Dockerfile** для оптимальной сборки
- **Gradle** build system с TOML version catalog
- **Docker Compose** для оркестрации сервисов

## API Endpoints

1. **POST** `/api/items` - добавление элемента
   ```json
   {
     "name": "Название",
     "description": "Описание"
   }
   ```

2. **GET** `/api/items` - получение списка всех элементов

3. **GET** `/api/mirea-logo` - получение герба РТУ МИРЭА (PNG изображение)

## Build and Run

### Automated Testing (Recommended)
Запустите автоматический тест с Colima, Docker Compose и проверкой всех эндпоинтов:
```bash
./test-docker.sh
```

Скрипт автоматически:
- Запустит Colima Docker runtime
- Соберет multi-stage Docker образ
- Запустит PostgreSQL и Spring Boot через Docker Compose
- Протестирует все API эндпоинты
- Очистит ресурсы и остановит Colima

### Manual Build and Run

#### Using Docker Compose:
```bash
docker-compose up --build
```

#### Using Gradle directly (для разработки):
```bash
# Из корневого каталога virtualization-technologies
./gradlew :practical-work-3:task-2-spring-boot-app:bootRun
```

## Architecture

### Multi-stage Dockerfile
- **Stage 1**: Gradle build with Gradle 7.6 + JDK 17
  - Скачивание герба МИРЭА через wget
  - Компиляция JAR файла
- **Stage 2**: Runtime с OpenJDK 17 JRE
  - Минимальный размер образа
  - Переменные окружения для PostgreSQL

### Database Configuration
PostgreSQL настройки через переменные окружения:
- `DB_HOST` - хост базы данных (default: localhost)
- `DB_PORT` - порт базы данных (default: 5432)
- `DB_NAME` - имя базы данных (default: mirea_db)
- `DB_USERNAME` - пользователь (default: mirea_user)
- `DB_PASSWORD` - пароль (default: mirea_password)

## Gradle Multi-project Structure

Проект является частью multi-project Gradle структуры с centralized version catalog (TOML):
- Root проект: `virtualization-technologies`
- Submodule: `practical-work-3:task-2-spring-boot-app`
- Version catalog: `gradle/libs.versions.toml`

## Testing

Автоматические тесты проверяют:
- ✅ Успешную сборку multi-stage Docker образа
- ✅ Подключение к PostgreSQL
- ✅ Работу CRUD операций с элементами
- ✅ Корректную отдачу герба МИРЭА
- ✅ Все требования задания 2