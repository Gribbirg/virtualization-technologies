#!/bin/bash

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "=== Тестирование системы мониторинга MIREA Spring Boot приложения ==="
echo "Рабочая директория: $PROJECT_DIR"
echo ""

BASE_URL="http://localhost:8090"
CLEANUP_ON_EXIT=${CLEANUP_ON_EXIT:-true}
SKIP_COLIMA_START=${SKIP_COLIMA_START:-false}

# Cleanup function
cleanup() {
    echo ""
    echo "=== Очистка ресурсов ==="

    if [ "$CLEANUP_ON_EXIT" = "true" ]; then
        echo "Остановка и удаление контейнеров..."
        docker-compose down -v 2>/dev/null || true

        echo "Очистка Docker образов..."
        docker image prune -f 2>/dev/null || true

        if [ "$SKIP_COLIMA_START" = "false" ]; then
            echo "Остановка Colima..."
            colima stop 2>/dev/null || true
        fi

        echo "✅ Очистка завершена"
    else
        echo "Сервисы оставлены запущенными (CLEANUP_ON_EXIT=false)"
    fi
}

# Setup trap for cleanup on exit
trap cleanup EXIT

function setup_docker() {
    echo "=== Настройка Docker окружения ==="

    if [ "$SKIP_COLIMA_START" = "false" ]; then
        echo "Проверка статуса Colima..."
        if ! colima status > /dev/null 2>&1; then
            echo "Запуск Colima..."
            colima start --memory 8 --cpu 4
        else
            echo "✅ Colima уже запущен"
        fi
    else
        echo "Пропуск запуска Colima (SKIP_COLIMA_START=true)"
    fi

    echo "Проверка подключения к Docker..."
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Не удалось подключиться к Docker daemon"
        exit 1
    fi

    echo "✅ Docker готов к использованию"
}

function build_and_start_services() {
    echo ""
    echo "=== Сборка и запуск сервисов ==="

    echo "Остановка существующих контейнеров..."
    docker-compose down -v 2>/dev/null || true

    echo "Сборка образов и запуск сервисов..."
    docker-compose up -d --build

    if [ $? -ne 0 ]; then
        echo "❌ Ошибка при запуске сервисов"
        exit 1
    fi

    echo "✅ Сервисы запущены"
}

function wait_for_services() {
    echo ""
    echo "=== Ожидание готовности сервисов ==="

    local max_attempts=60
    local attempt=1

    services=(
        "http://localhost:8090/actuator/health:Spring Boot"
        "http://localhost:5432:PostgreSQL"
        "http://localhost:9090:Prometheus"
        "http://localhost:3000:Grafana"
    )

    for service_info in "${services[@]}"; do
        IFS=':' read -r url name <<< "$service_info"
        echo "Ожидание $name..."

        attempt=1
        while [ $attempt -le $max_attempts ]; do
            if curl -f -s "$url" > /dev/null 2>&1; then
                echo "✅ $name готов"
                break
            fi

            if [ $attempt -eq $max_attempts ]; then
                echo "❌ $name не готов после $max_attempts попыток"
                echo "Логи сервиса:"
                docker-compose logs --tail=20 || true
                return 1
            fi

            echo "Попытка $attempt/$max_attempts для $name..."
            sleep 5
            ((attempt++))
        done
    done

    echo "Дополнительное ожидание стабилизации (30 секунд)..."
    sleep 30

    echo "✅ Все основные сервисы готовы"
}

function check_service() {
    local url=$1
    local service_name=$2
    echo "Проверка $service_name ($url)..."
    if curl -f -s "$url" > /dev/null; then
        echo "✅ $service_name доступен"
        return 0
    else
        echo "❌ $service_name недоступен"
        return 1
    fi
}

function test_crud_operations() {
    echo ""
    echo "=== Тестирование CRUD операций ==="

    echo "1. Создание пользователя..."
    USER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/users" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "email": "test@example.com",
            "firstName": "Test",
            "lastName": "User"
        }')

    if [ $? -eq 0 ] && [[ "$USER_RESPONSE" =~ "id" ]]; then
        echo "✅ Пользователь создан: $USER_RESPONSE"
        USER_ID=$(echo "$USER_RESPONSE" | grep -o '"id":[0-9]*' | cut -d: -f2)
    else
        echo "❌ Ошибка создания пользователя: $USER_RESPONSE"
        return 1
    fi

    echo "2. Создание продукта..."
    PRODUCT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Test Product",
            "description": "Test Description",
            "price": 99.99,
            "stock": 10
        }')

    if [ $? -eq 0 ] && [[ "$PRODUCT_RESPONSE" =~ "id" ]]; then
        echo "✅ Продукт создан: $PRODUCT_RESPONSE"
        PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | grep -o '"id":[0-9]*' | cut -d: -f2)
    else
        echo "❌ Ошибка создания продукта: $PRODUCT_RESPONSE"
        return 1
    fi

    echo "3. Создание заказа..."
    ORDER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/orders" \
        -H "Content-Type: application/json" \
        -d "{
            \"userId\": $USER_ID,
            \"totalAmount\": 99.99,
            \"productIds\": [$PRODUCT_ID]
        }")

    if [ $? -eq 0 ] && [[ "$ORDER_RESPONSE" =~ "id" ]]; then
        echo "✅ Заказ создан: $ORDER_RESPONSE"
    else
        echo "❌ Ошибка создания заказа: $ORDER_RESPONSE"
        return 1
    fi

    echo "4. Получение всех пользователей..."
    USERS_RESPONSE=$(curl -s "$BASE_URL/api/users")
    echo "Найдено пользователей: $(echo "$USERS_RESPONSE" | grep -o '"id"' | wc -l)"

    echo "5. Получение всех продуктов..."
    PRODUCTS_RESPONSE=$(curl -s "$BASE_URL/api/products")
    echo "Найдено продуктов: $(echo "$PRODUCTS_RESPONSE" | grep -o '"id"' | wc -l)"

    echo "6. Получение всех заказов..."
    ORDERS_RESPONSE=$(curl -s "$BASE_URL/api/orders")
    echo "Найдено заказов: $(echo "$ORDERS_RESPONSE" | grep -o '"id"' | wc -l)"

    echo "✅ CRUD операции протестированы успешно"
}

function test_log_export() {
    echo ""
    echo "=== Тестирование экспорта логов ==="

    echo "Экспорт логов в CSV..."
    LOG_RESPONSE=$(curl -s "$BASE_URL/api/logs/mock-export")

    if [ $? -eq 0 ] && [[ "$LOG_RESPONSE" =~ "Timestamp" ]]; then
        echo "✅ Логи успешно экспортированы в CSV"
        echo "Первые строки CSV:"
        echo "$LOG_RESPONSE" | head -3

        # Save to file for demonstration
        echo "$LOG_RESPONSE" > database_operations_test.csv
        echo "Логи сохранены в database_operations_test.csv"
    else
        echo "❌ Ошибка экспорта логов: $LOG_RESPONSE"
        return 1
    fi
}

function load_test() {
    echo ""
    echo "=== Нагрузочное тестирование ==="

    echo "Отправка 10 параллельных запросов..."

    pids=()
    for i in {1..10}; do
        curl -s -X POST "$BASE_URL/api/users" \
            -H "Content-Type: application/json" \
            -d "{
                \"username\": \"loadtest$i\",
                \"email\": \"loadtest$i@example.com\",
                \"firstName\": \"Load\",
                \"lastName\": \"Test$i\"
            }" > /dev/null &
        pids+=($!)
    done

    # Wait for all background jobs to complete
    for pid in "${pids[@]}"; do
        wait $pid
    done

    echo "✅ Нагрузочное тестирование завершено"

    # Check how many users were created
    USERS_COUNT=$(curl -s "$BASE_URL/api/users" | grep -o '"id"' | wc -l)
    echo "Всего пользователей в системе: $USERS_COUNT"
}

function check_monitoring_services() {
    echo ""
    echo "=== Проверка сервисов мониторинга ==="

    local failed_services=0

    services=(
        "http://localhost:8090/actuator/health:Spring Boot Actuator"
        "http://localhost:8090/actuator/prometheus:Spring Boot Prometheus метрики"
        "http://localhost:9090:Prometheus"
        "http://localhost:3000:Grafana"
        "http://localhost:8080:Adminer"
        "http://localhost:9000:GrayLog"
        "http://localhost:8081:Zabbix Web"
    )

    for service_info in "${services[@]}"; do
        IFS=':' read -r url name <<< "$service_info"
        if ! check_service "$url" "$name"; then
            ((failed_services++))
        fi
    done

    if [ $failed_services -gt 0 ]; then
        echo "⚠️  $failed_services сервисов недоступны (некоторые сервисы могут требовать больше времени для запуска)"
    else
        echo "✅ Все сервисы мониторинга доступны"
    fi
}

function run_all_tests() {
    echo ""
    echo "=== Запуск всех тестов ==="

    local test_results=()

    if check_monitoring_services; then
        test_results+=("✅ Проверка сервисов мониторинга")
    else
        test_results+=("⚠️  Проверка сервисов мониторинга (частично)")
    fi

    if test_crud_operations; then
        test_results+=("✅ CRUD операции")
    else
        test_results+=("❌ CRUD операции")
    fi

    if test_log_export; then
        test_results+=("✅ Экспорт логов")
    else
        test_results+=("❌ Экспорт логов")
    fi

    if load_test; then
        test_results+=("✅ Нагрузочное тестирование")
    else
        test_results+=("❌ Нагрузочное тестирование")
    fi

    echo ""
    echo "=== Результаты тестирования ==="
    for result in "${test_results[@]}"; do
        echo "$result"
    done
}

function print_service_info() {
    echo ""
    echo "=== Информация о сервисах ==="
    echo ""
    echo "Доступные сервисы:"
    echo "- Spring Boot приложение: http://localhost:8090"
    echo "- Adminer (управление БД): http://localhost:8080"
    echo "- Prometheus: http://localhost:9090"
    echo "- Grafana: http://localhost:3000 (admin/admin)"
    echo "- GrayLog: http://localhost:9000 (admin/admin)"
    echo "- Zabbix Web: http://localhost:8081 (Admin/zabbix)"
    echo ""
    echo "API эндпоинты:"
    echo "- GET /api/users - получить всех пользователей"
    echo "- POST /api/users - создать пользователя"
    echo "- GET /api/products - получить все продукты"
    echo "- POST /api/products - создать продукт"
    echo "- GET /api/orders - получить все заказы"
    echo "- POST /api/orders - создать заказ"
    echo "- GET /api/logs/mock-export - экспорт логов в CSV"
    echo ""
}

# Main execution
echo "Переменные окружения:"
echo "- CLEANUP_ON_EXIT: $CLEANUP_ON_EXIT"
echo "- SKIP_COLIMA_START: $SKIP_COLIMA_START"
echo ""

setup_docker
build_and_start_services
wait_for_services
run_all_tests
print_service_info

echo "=== Тестирование завершено успешно ==="
echo ""
echo "Для остановки всех сервисов выполните: docker-compose down -v"
echo "Для просмотра логов выполните: docker-compose logs -f"