#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "=== Быстрая проверка практической работы 4 ==="
echo ""
echo "Рабочая директория: $PROJECT_DIR"
echo ""

BASE_URL="http://localhost:8090"

check_service() {
    local url=$1
    local name=$2
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo "✅ $name доступен"
        return 0
    else
        echo "❌ $name недоступен"
        return 1
    fi
}

echo "1. Проверка синтаксиса docker-compose..."
docker-compose config --quiet && echo "✅ docker-compose.yml валиден" || echo "❌ Ошибка в docker-compose.yml"

echo ""
echo "2. Проверка сборки проекта..."
cd /Users/alexgribkov/study/virtualization-technologies
./gradlew :practical-work-4:build -x test --quiet && echo "✅ Проект собирается успешно" || echo "❌ Ошибка сборки"

echo ""
echo "3. Проверка наличия необходимых файлов..."
cd /Users/alexgribkov/study/virtualization-technologies/practical-work-4

files=(
    "src/main/resources/logback-spring.xml"
    "monitoring/grafana/provisioning/dashboards/spring-boot-dashboard.json"
    "docker-compose.yml"
    "Dockerfile"
    "README.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file существует"
    else
        echo "❌ $file отсутствует"
    fi
done

echo ""
echo "4. Подсчёт сервисов в docker-compose..."
SERVICE_COUNT=$(docker-compose config --services 2>/dev/null | wc -l | tr -d ' ')
echo "Количество сервисов: $SERVICE_COUNT"
if [ "$SERVICE_COUNT" -ge 11 ]; then
    echo "✅ Достаточно сервисов (требуется ≥11)"
else
    echo "⚠️  Мало сервисов (найдено $SERVICE_COUNT, требуется ≥11)"
fi

echo ""
echo "5. Проверка наличия GELF зависимости..."
if grep -q "logback-gelf" build.gradle.kts; then
    echo "✅ GELF зависимость добавлена"
else
    echo "❌ GELF зависимость отсутствует"
fi

echo ""
echo "6. Проверка конфигурации логирования..."
if [ -f "src/main/resources/logback-spring.xml" ]; then
    if grep -q "GelfUdpAppender" src/main/resources/logback-spring.xml; then
        echo "✅ GELF аппендер настроен"
    else
        echo "❌ GELF аппендер не настроен"
    fi
fi

echo ""
echo "7. Проверка моделей данных..."
ENTITIES=(
    "src/main/java/com/mirea/app/entity/User.java"
    "src/main/java/com/mirea/app/entity/Product.java"
    "src/main/java/com/mirea/app/entity/Order.java"
)

entity_count=0
for entity in "${ENTITIES[@]}"; do
    if [ -f "$entity" ]; then
        entity_count=$((entity_count + 1))
    fi
done

echo "Найдено моделей: $entity_count"
if [ "$entity_count" -ge 3 ]; then
    echo "✅ Достаточно моделей данных (требуется ≥3)"
else
    echo "❌ Недостаточно моделей данных"
fi

echo ""
echo "8. Проверка связей между моделями..."
if grep -q "OneToMany" src/main/java/com/mirea/app/entity/User.java; then
    echo "✅ Связь 1:N найдена (User → Orders)"
else
    echo "❌ Связь 1:N не найдена"
fi

if grep -q "ManyToMany" src/main/java/com/mirea/app/entity/Order.java; then
    echo "✅ Связь N:N найдена (Order ↔ Products)"
else
    echo "❌ Связь N:N не найдена"
fi

echo ""
echo "9. Проверка контроллеров..."
CONTROLLERS=(
    "src/main/java/com/mirea/app/controller/UserController.java"
    "src/main/java/com/mirea/app/controller/ProductController.java"
    "src/main/java/com/mirea/app/controller/OrderController.java"
    "src/main/java/com/mirea/app/controller/LogController.java"
)

controller_count=0
for controller in "${CONTROLLERS[@]}"; do
    if [ -f "$controller" ]; then
        controller_count=$((controller_count + 1))
    fi
done

echo "Найдено контроллеров: $controller_count"
if [ "$controller_count" -eq 4 ]; then
    echo "✅ Все контроллеры на месте"
else
    echo "⚠️  Количество контроллеров: $controller_count (ожидалось 4)"
fi

echo ""
echo "10. Проверка эндпоинта экспорта логов..."
if grep -q "/api/logs/export" src/main/java/com/mirea/app/controller/LogController.java; then
    echo "✅ Эндпоинт экспорта логов реализован"
else
    echo "❌ Эндпоинт экспорта логов не найден"
fi

echo ""
echo "=== Проверка завершена ==="
echo ""
echo "Для полного тестирования с запуском контейнеров используйте:"
echo "  ./scripts/test-monitoring.sh"

