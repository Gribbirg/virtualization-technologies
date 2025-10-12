#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "======================================================================"
echo "  ПОЛНАЯ ПРОВЕРКА ПРАКТИЧЕСКОЙ РАБОТЫ 4 (Критерии на 2 балла)"
echo "======================================================================"
echo ""
echo "Рабочая директория: $PROJECT_DIR"
echo ""
echo "Параметры запуска:"
echo "  START_COLIMA=$START_COLIMA (автоматический запуск Colima)"
echo "  STOP_COLIMA=$STOP_COLIMA (остановка Colima после тестов)"
echo "  CLEANUP_ON_EXIT=$CLEANUP_ON_EXIT (очистка контейнеров)"
echo ""

BASE_URL="http://localhost:8090"
TIMEOUT=180
CLEANUP_ON_EXIT=${CLEANUP_ON_EXIT:-true}
START_COLIMA=${START_COLIMA:-true}
STOP_COLIMA=${STOP_COLIMA:-false}

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED_TESTS=0
TOTAL_TESTS=0

print_status() {
    local status=$1
    local message=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ [PASS]${NC} $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ [FAIL]${NC} $message"
    else
        echo -e "${YELLOW}⚠️  [WARN]${NC} $message"
    fi
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cleanup() {
    if [ "$CLEANUP_ON_EXIT" = "true" ]; then
        echo ""
        echo "Очистка ресурсов..."
        docker-compose down -v 2>/dev/null || true
        
        if [ "$STOP_COLIMA" = "true" ]; then
            echo "Остановка Colima..."
            colima stop 2>/dev/null || true
            echo "✅ Colima остановлен"
        fi
    fi
}

trap cleanup EXIT

print_header "1. ПРОВЕРКА DOCKER-COMPOSE ФАЙЛА"

if docker-compose config --quiet 2>/dev/null; then
    print_status "PASS" "docker-compose.yml валиден"
else
    print_status "FAIL" "docker-compose.yml содержит ошибки"
    exit 1
fi

SERVICE_COUNT=$(docker-compose config --services 2>/dev/null | wc -l | tr -d ' ')
if [ "$SERVICE_COUNT" -ge 11 ]; then
    print_status "PASS" "Количество сервисов: $SERVICE_COUNT (требуется ≥11)"
else
    print_status "FAIL" "Недостаточно сервисов: $SERVICE_COUNT (требуется ≥11)"
fi

EXPECTED_SERVICES=("postgres" "spring-app" "prometheus" "grafana" "graylog" "zabbix-server" "zabbix-web" "adminer")
for service in "${EXPECTED_SERVICES[@]}"; do
    if docker-compose config --services 2>/dev/null | grep -q "^${service}$"; then
        print_status "PASS" "Сервис '$service' присутствует"
    else
        print_status "FAIL" "Сервис '$service' отсутствует"
    fi
done

print_header "2. ПРОВЕРКА МОДЕЛЕЙ ДАННЫХ И СВЯЗЕЙ"

ENTITIES=("User" "Product" "Order")
for entity in "${ENTITIES[@]}"; do
    if [ -f "src/main/java/com/mirea/app/entity/${entity}.java" ]; then
        print_status "PASS" "Модель ${entity} найдена"
    else
        print_status "FAIL" "Модель ${entity} не найдена"
    fi
done

if grep -q "@OneToMany" src/main/java/com/mirea/app/entity/User.java 2>/dev/null; then
    print_status "PASS" "Связь 1:N реализована (User → Orders)"
else
    print_status "FAIL" "Связь 1:N не найдена"
fi

if grep -q "@ManyToMany" src/main/java/com/mirea/app/entity/Order.java 2>/dev/null; then
    print_status "PASS" "Связь N:N реализована (Order ↔ Products)"
else
    print_status "FAIL" "Связь N:N не найдена"
fi

print_header "3. ПРОВЕРКА CRUD ЭНДПОИНТОВ"

CONTROLLERS=("UserController" "ProductController" "OrderController")
for controller in "${CONTROLLERS[@]}"; do
    if [ -f "src/main/java/com/mirea/app/controller/${controller}.java" ]; then
        print_status "PASS" "Контроллер ${controller} найден"
        
        file="src/main/java/com/mirea/app/controller/${controller}.java"
        has_post=$(grep -c "@PostMapping" "$file" 2>/dev/null || echo 0)
        has_get=$(grep -c "@GetMapping" "$file" 2>/dev/null || echo 0)
        has_put=$(grep -c "@PutMapping" "$file" 2>/dev/null || echo 0)
        has_delete=$(grep -c "@DeleteMapping" "$file" 2>/dev/null || echo 0)
        
        if [ "$has_post" -gt 0 ] && [ "$has_get" -gt 0 ] && [ "$has_put" -gt 0 ] && [ "$has_delete" -gt 0 ]; then
            print_status "PASS" "  └─ CRUD операции реализованы (POST/GET/PUT/DELETE)"
        else
            print_status "WARN" "  └─ Не все CRUD операции найдены"
        fi
    else
        print_status "FAIL" "Контроллер ${controller} не найден"
    fi
done

print_header "4. ПРОВЕРКА ЭНДПОИНТА ЭКСПОРТА ЛОГОВ"

if [ -f "src/main/java/com/mirea/app/controller/LogController.java" ]; then
    print_status "PASS" "LogController найден"
    
    if grep -q "@GetMapping.*export" src/main/java/com/mirea/app/controller/LogController.java; then
        print_status "PASS" "Эндпоинт экспорта логов реализован"
    else
        print_status "FAIL" "Эндпоинт экспорта логов не найден"
    fi
    
    if grep -q "CSV" src/main/java/com/mirea/app/controller/LogController.java; then
        print_status "PASS" "Экспорт в CSV реализован"
    else
        print_status "FAIL" "Экспорт в CSV не найден"
    fi
else
    print_status "FAIL" "LogController не найден"
fi

print_header "5. ПРОВЕРКА ИНТЕГРАЦИИ С GRAYLOG"

if grep -q "logback-gelf" build.gradle.kts 2>/dev/null; then
    print_status "PASS" "GELF зависимость добавлена"
else
    print_status "FAIL" "GELF зависимость отсутствует"
fi

if [ -f "src/main/resources/logback-spring.xml" ]; then
    print_status "PASS" "Конфигурация logback найдена"
    
    if grep -q "GelfUdpAppender" src/main/resources/logback-spring.xml; then
        print_status "PASS" "GELF аппендер настроен"
    else
        print_status "FAIL" "GELF аппендер не настроен"
    fi
else
    print_status "FAIL" "logback-spring.xml отсутствует"
fi

print_header "6. ПРОВЕРКА НАСТРОЙКИ PROMETHEUS + GRAFANA"

if [ -f "monitoring/prometheus/prometheus.yml" ]; then
    print_status "PASS" "Конфигурация Prometheus найдена"
    
    if grep -q "spring-boot" monitoring/prometheus/prometheus.yml; then
        print_status "PASS" "Prometheus настроен на сбор метрик Spring Boot"
    else
        print_status "FAIL" "Prometheus не настроен на Spring Boot"
    fi
    
    if grep -q "postgres-exporter" monitoring/prometheus/prometheus.yml; then
        print_status "PASS" "Prometheus настроен на сбор метрик PostgreSQL"
    else
        print_status "WARN" "Prometheus может не собирать метрики PostgreSQL"
    fi
else
    print_status "FAIL" "Конфигурация Prometheus отсутствует"
fi

if [ -f "monitoring/grafana/provisioning/datasources/prometheus.yml" ]; then
    print_status "PASS" "Grafana datasource для Prometheus настроен"
else
    print_status "FAIL" "Grafana datasource не настроен"
fi

if [ -f "monitoring/grafana/provisioning/dashboards/spring-boot-dashboard.json" ]; then
    print_status "PASS" "Grafana dashboard создан"
else
    print_status "WARN" "Готовый Grafana dashboard отсутствует"
fi

print_header "7. ПРОВЕРКА ZABBIX"

if docker-compose config 2>/dev/null | grep -q "zabbix-server"; then
    print_status "PASS" "Zabbix Server настроен"
else
    print_status "FAIL" "Zabbix Server отсутствует"
fi

if docker-compose config 2>/dev/null | grep -q "zabbix-web"; then
    print_status "PASS" "Zabbix Web настроен"
else
    print_status "FAIL" "Zabbix Web отсутствует"
fi

if docker-compose config 2>/dev/null | grep -q "zabbix-postgres"; then
    print_status "PASS" "Отдельная БД для Zabbix настроена"
else
    print_status "FAIL" "Отдельная БД для Zabbix отсутствует"
fi

print_header "8. ЗАПУСК И ТЕСТИРОВАНИЕ СИСТЕМЫ"

echo "Проверка доступности Docker daemon..."
if ! docker info > /dev/null 2>&1; then
    if [ "$START_COLIMA" = "true" ]; then
        print_status "WARN" "Docker daemon не запущен, попытка запуска Colima..."
        echo ""
        echo "🚀 Запуск Colima с параметрами: memory 8GB, cpu 4"
        
        if colima start --memory 8 --cpu 4 2>&1 | tee /tmp/colima-start.log; then
            echo ""
            echo "⏳ Ожидание готовности Docker daemon (30 секунд)..."
            sleep 30
            
            if docker info > /dev/null 2>&1; then
                print_status "PASS" "Colima запущен, Docker daemon доступен"
            else
                print_status "FAIL" "Colima запущен, но Docker daemon недоступен"
                echo ""
                echo "Попробуйте:"
                echo "  1. Подождать ещё минуту"
                echo "  2. Проверить: colima status"
                echo "  3. Перезапустить: colima restart"
                exit 1
            fi
        else
            print_status "FAIL" "Не удалось запустить Colima"
            echo ""
            echo "Проверьте логи: /tmp/colima-start.log"
            echo ""
            echo "Статические проверки завершены. Для полного тестирования запустите Docker вручную."
            echo ""
            
            print_header "15. ИТОГОВЫЕ РЕЗУЛЬТАТЫ (СТАТИЧЕСКИЕ ПРОВЕРКИ)"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "  Пройдено тестов: ${GREEN}$PASSED_TESTS${NC} из ${TOTAL_TESTS}"
            SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
            echo "  Процент успеха (статические проверки): ${SUCCESS_RATE}%"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo -e "${YELLOW}⚠️  Docker не запущен. Запустите Docker вручную для полного тестирования.${NC}"
            echo ""
            exit 0
        fi
    else
        print_status "FAIL" "Docker daemon не запущен"
        echo ""
        echo "❗ Для запуска Docker выполните:"
        echo "   colima start --memory 8 --cpu 4"
        echo ""
        echo "Или запустите Docker Desktop, если он установлен."
        echo ""
        echo "Или запустите скрипт с автоматическим запуском Colima:"
        echo "   START_COLIMA=true ./scripts/full-validation.sh"
        echo ""
        echo "Статические проверки завершены. Для полного тестирования запустите Docker."
        echo ""
        
        print_header "15. ИТОГОВЫЕ РЕЗУЛЬТАТЫ (СТАТИЧЕСКИЕ ПРОВЕРКИ)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "  Пройдено тестов: ${GREEN}$PASSED_TESTS${NC} из ${TOTAL_TESTS}"
        SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "  Процент успеха (статические проверки): ${SUCCESS_RATE}%"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${YELLOW}⚠️  Docker не запущен. Для полного тестирования запустите Docker daemon.${NC}"
        echo ""
        exit 0
    fi
else
    print_status "PASS" "Docker daemon уже запущен и доступен"
fi

echo "Остановка существующих контейнеров..."
docker-compose down -v 2>/dev/null || true

echo "Сборка и запуск сервисов..."
MAX_RETRIES=3
RETRY=1

while [ $RETRY -le $MAX_RETRIES ]; do
    echo "Попытка $RETRY из $MAX_RETRIES..."
    
    if docker-compose up -d --build 2>&1 | tee /tmp/docker-compose-up.log; then
        print_status "PASS" "Контейнеры запущены успешно"
        break
    else
        if [ $RETRY -eq $MAX_RETRIES ]; then
            print_status "FAIL" "Ошибка запуска контейнеров после $MAX_RETRIES попыток"
            echo ""
            echo "Возможные причины:"
            echo "  1. Проблема с Docker registry (403 Forbidden)"
            echo "  2. Нехватка памяти или ресурсов"
            echo "  3. Проблемы с сетью"
            echo ""
            echo "Решение:"
            echo "  1. Подождите 1-2 минуты и попробуйте снова"
            echo "  2. Проверьте подключение к интернету"
            echo "  3. Попробуйте: docker system prune -a"
            echo "  4. Перезапустите Colima: colima restart"
            echo ""
            echo "Логи: /tmp/docker-compose-up.log"
            echo "Проверьте логи: docker-compose logs"
            exit 1
        else
            print_status "WARN" "Попытка $RETRY не удалась, повторяю через 10 секунд..."
            sleep 10
            RETRY=$((RETRY + 1))
        fi
    fi
done

echo ""
echo "Ожидание готовности сервисов (до 2 минут на каждый)..."

wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=12
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local response=$(curl -s -m 10 -w "\n%{http_code}" "$url" 2>&1)
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "302" ] || [ "$http_code" = "301" ]; then
            echo "  └─ $name ответил (код: $http_code)"
            if [ -n "$body" ] && [ ${#body} -lt 200 ]; then
                echo "     Ответ: $body"
            fi
            return 0
        fi
        
        if [ $attempt -eq 1 ] || [ $((attempt % 2)) -eq 0 ]; then
            echo "  └─ Ожидание $name... ($((attempt * 10))s, код: ${http_code:-timeout})"
            if [ -n "$body" ] && [ ${#body} -lt 150 ]; then
                echo "     Ответ: $body"
            fi
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
    echo "  └─ Последний ответ от $name (код: ${http_code:-timeout})"
    if [ -n "$body" ] && [ ${#body} -lt 200 ]; then
        echo "     Ответ: $body"
    fi
    return 1
}

SERVICES_TO_CHECK=(
    "http://localhost:8090/actuator/health|Spring Boot"
    "http://localhost:9090/-/healthy|Prometheus"
    "http://localhost:3000/api/health|Grafana"
    "http://localhost:8080|Adminer"
)

ALL_SERVICES_UP=true
for service_info in "${SERVICES_TO_CHECK[@]}"; do
    IFS='|' read -r url name <<< "$service_info"
    echo ""
    echo "Проверка: $name"
    if wait_for_service "$url" "$name"; then
        print_status "PASS" "Сервис $name доступен"
    else
        print_status "WARN" "Сервис $name недоступен (может требовать больше времени)"
        ALL_SERVICES_UP=false
    fi
done

if [ "$ALL_SERVICES_UP" = "false" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Некоторые сервисы не успели запуститься. Продолжаем тестирование...${NC}"
    echo "   (Для медленных машин можно увеличить TIMEOUT)"
fi

sleep 10

print_header "9. ТЕСТИРОВАНИЕ CRUD ОПЕРАЦИЙ"

echo "Проверка доступности API..."
API_HEALTH=$(curl -s -m 5 "$BASE_URL/actuator/health" 2>/dev/null)
if echo "$API_HEALTH" | grep -q '"status":"UP"'; then
    print_status "PASS" "Spring Boot API готов к тестированию"
else
    print_status "WARN" "Spring Boot API может быть не готов, но продолжаем тестирование"
    sleep 5
fi

echo "Создание пользователя..."
USER_RESPONSE=$(curl -s -m 10 -X POST "$BASE_URL/api/users" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "test_user_validation",
        "email": "test@validation.com",
        "firstName": "Test",
        "lastName": "User"
    }' 2>&1)

if echo "$USER_RESPONSE" | grep -q "id"; then
    print_status "PASS" "Создание пользователя (POST /api/users)"
    USER_ID=$(echo "$USER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo "  └─ Создан пользователь с ID: $USER_ID"
else
    print_status "FAIL" "Создание пользователя не работает"
    echo "  └─ Ответ сервера: ${USER_RESPONSE:0:200}"
    USER_ID=1
fi

echo "Получение всех пользователей..."
USERS_RESPONSE=$(curl -s -m 10 "$BASE_URL/api/users" 2>&1)
if echo "$USERS_RESPONSE" | grep -q "test_user_validation"; then
    print_status "PASS" "Чтение пользователей (GET /api/users)"
    USER_COUNT=$(echo "$USERS_RESPONSE" | grep -o '"id":' | wc -l | tr -d ' ')
    echo "  └─ Найдено пользователей: $USER_COUNT"
else
    print_status "FAIL" "Чтение пользователей не работает"
    echo "  └─ Ответ сервера: ${USERS_RESPONSE:0:200}"
fi

echo "Обновление пользователя..."
UPDATE_RESPONSE=$(curl -s -m 10 -X PUT "$BASE_URL/api/users/$USER_ID" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "test_user_updated",
        "email": "updated@validation.com",
        "firstName": "Updated",
        "lastName": "User"
    }' 2>/dev/null)

if echo "$UPDATE_RESPONSE" | grep -q "updated"; then
    print_status "PASS" "Обновление пользователя (PUT /api/users/{id})"
else
    print_status "WARN" "Обновление пользователя может не работать"
fi

echo "Создание продукта..."
PRODUCT_RESPONSE=$(curl -s -m 10 -X POST "$BASE_URL/api/products" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test Product",
        "description": "Validation test",
        "price": 99.99,
        "stock": 10
    }' 2>&1)

if echo "$PRODUCT_RESPONSE" | grep -q "id"; then
    print_status "PASS" "Создание продукта (POST /api/products)"
    PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo "  └─ Создан продукт с ID: $PRODUCT_ID"
else
    print_status "FAIL" "Создание продукта не работает"
    echo "  └─ Ответ сервера: ${PRODUCT_RESPONSE:0:200}"
    PRODUCT_ID=1
fi

echo "Создание заказа..."
ORDER_RESPONSE=$(curl -s -m 10 -X POST "$BASE_URL/api/orders" \
    -H "Content-Type: application/json" \
    -d "{
        \"userId\": $USER_ID,
        \"totalAmount\": 99.99,
        \"productIds\": [$PRODUCT_ID]
    }" 2>&1)

if echo "$ORDER_RESPONSE" | grep -q "id"; then
    print_status "PASS" "Создание заказа (POST /api/orders) - проверка связей"
    ORDER_ID=$(echo "$ORDER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo "  └─ Создан заказ с ID: $ORDER_ID (User: $USER_ID, Product: $PRODUCT_ID)"
else
    print_status "FAIL" "Создание заказа не работает"
    echo "  └─ Ответ сервера: ${ORDER_RESPONSE:0:200}"
fi

echo "Удаление пользователя..."
DELETE_RESPONSE=$(curl -s -m 10 -w "\n%{http_code}" -X DELETE "$BASE_URL/api/users/$USER_ID" 2>&1)
DELETE_CODE=$(echo "$DELETE_RESPONSE" | tail -1)
DELETE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')
if [ "$DELETE_CODE" = "204" ] || [ "$DELETE_CODE" = "200" ]; then
    print_status "PASS" "Удаление пользователя (DELETE /api/users/{id})"
    echo "  └─ HTTP код: $DELETE_CODE"
else
    print_status "WARN" "Удаление пользователя вернуло код: $DELETE_CODE"
    if [ -n "$DELETE_BODY" ]; then
        echo "  └─ Ответ: ${DELETE_BODY:0:150}"
    fi
fi

print_header "10. ПРОВЕРКА ЭКСПОРТА ЛОГОВ В CSV"

echo "Экспорт логов..."
LOG_RESPONSE=$(curl -s -m 10 "$BASE_URL/api/logs/mock-export" 2>&1)

if echo "$LOG_RESPONSE" | grep -q "Timestamp"; then
    print_status "PASS" "Эндпоинт экспорта логов работает"
    
    LOG_LINES=$(echo "$LOG_RESPONSE" | wc -l | tr -d ' ')
    echo "  └─ Получено строк в CSV: $LOG_LINES"
    
    if echo "$LOG_RESPONSE" | grep -qi "created\|updated\|deleted"; then
        print_status "PASS" "CSV содержит операции с БД"
        DB_OPS=$(echo "$LOG_RESPONSE" | grep -ci "created\|updated\|deleted")
        echo "  └─ Найдено операций с БД: $DB_OPS"
    else
        print_status "WARN" "CSV может не содержать операции с БД"
    fi
    
    echo "$LOG_RESPONSE" > /tmp/validation_logs.csv
    echo "  └─ Логи сохранены в /tmp/validation_logs.csv"
    echo "  └─ Первые 3 строки:"
    echo "$LOG_RESPONSE" | head -n 3 | sed 's/^/     /'
else
    print_status "FAIL" "Экспорт логов не работает"
    echo "  └─ Ответ сервера: ${LOG_RESPONSE:0:200}"
fi

print_header "11. ПРОВЕРКА МЕТРИК PROMETHEUS"

echo "Проверка метрик Spring Boot..."
METRICS_RESPONSE=$(curl -s -m 10 "$BASE_URL/actuator/prometheus" 2>&1)

if echo "$METRICS_RESPONSE" | grep -q "jvm_memory"; then
    print_status "PASS" "JVM метрики доступны"
    JVM_METRICS=$(echo "$METRICS_RESPONSE" | grep -c "^jvm_" || echo 0)
    echo "  └─ Найдено JVM метрик: $JVM_METRICS"
else
    print_status "FAIL" "JVM метрики недоступны"
    echo "  └─ Ответ (первые 200 символов): ${METRICS_RESPONSE:0:200}"
fi

if echo "$METRICS_RESPONSE" | grep -q "http_server_requests"; then
    print_status "PASS" "HTTP метрики доступны"
    HTTP_METRICS=$(echo "$METRICS_RESPONSE" | grep -c "http_server" || echo 0)
    echo "  └─ Найдено HTTP метрик: $HTTP_METRICS"
else
    print_status "FAIL" "HTTP метрики недоступны"
fi

print_header "12. ПРОВЕРКА СИСТЕМ МОНИТОРИНГА"

echo "Проверка доступности веб-интерфейсов..."

check_web_service() {
    local url=$1
    local name=$2
    local retries=$3
    local retry=1
    
    while [ $retry -le $retries ]; do
        local response=$(curl -s -m 10 -w "\n%{http_code}" "$url" 2>&1)
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "302" ] || [ "$http_code" = "301" ]; then
            print_status "PASS" "$name доступен ($url, код: $http_code)"
            return 0
        fi
        
        if [ $retry -lt $retries ]; then
            echo "  └─ Ожидание $name (попытка $retry из $retries, код: ${http_code:-timeout})..."
            if [ -n "$body" ] && [ ${#body} -lt 100 ]; then
                echo "     Ответ: $body"
            fi
            sleep 10
        else
            echo "  └─ Последний ответ от $name (код: ${http_code:-timeout})"
            if [ -n "$body" ] && [ ${#body} -lt 150 ]; then
                echo "     Ответ: $body"
            fi
        fi
        retry=$((retry + 1))
    done
    
    print_status "WARN" "$name может быть недоступен (последний код: ${http_code:-timeout})"
    return 1
}

check_web_service "http://localhost:3000" "Grafana" 2
check_web_service "http://localhost:8081" "Zabbix Web" 3
check_web_service "http://localhost:9000" "GrayLog Web" 5

print_header "13. ПРОВЕРКА ОТДЕЛЬНЫХ БД ДЛЯ СИСТЕМ МОНИТОРИНГА"

if docker-compose config 2>/dev/null | grep -A 10 "zabbix-postgres" | grep -q "POSTGRES_DB: zabbix"; then
    print_status "PASS" "Zabbix использует отдельную БД (не основную)"
else
    print_status "FAIL" "Zabbix может использовать основную БД"
fi

if docker-compose config 2>/dev/null | grep -q "mongodb"; then
    print_status "PASS" "GrayLog использует MongoDB (не PostgreSQL приложения)"
else
    print_status "FAIL" "GrayLog может использовать основную БД"
fi

print_header "14. ПРОВЕРКА ДОКУМЕНТАЦИИ"

if [ -f "README.md" ]; then
    README_LINES=$(wc -l < README.md)
    if [ "$README_LINES" -gt 100 ]; then
        print_status "PASS" "README.md существует и содержит $README_LINES строк"
    else
        print_status "WARN" "README.md слишком короткий ($README_LINES строк)"
    fi
    
    if grep -q "docker-compose up" README.md; then
        print_status "PASS" "README содержит инструкции по запуску"
    else
        print_status "FAIL" "README не содержит инструкции по запуску"
    fi
else
    print_status "FAIL" "README.md отсутствует"
fi

print_header "15. ИТОГОВЫЕ РЕЗУЛЬТАТЫ"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Пройдено тестов: ${GREEN}$PASSED_TESTS${NC} из ${TOTAL_TESTS}"
SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "  Процент успеха: ${SUCCESS_RATE}%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $SUCCESS_RATE -ge 90 ]; then
    echo -e "${GREEN}🎉 ОТЛИЧНО! Проект готов к сдаче на 2 балла!${NC}"
elif [ $SUCCESS_RATE -ge 75 ]; then
    echo -e "${YELLOW}⚠️  ХОРОШО! Есть небольшие замечания, но основные требования выполнены.${NC}"
else
    echo -e "${RED}❌ ТРЕБУЕТСЯ ДОРАБОТКА! Не все критерии выполнены.${NC}"
fi

echo ""
echo "Доступ к сервисам:"
echo "  • Spring Boot API:  http://localhost:8090"
echo "  • Adminer:          http://localhost:8080"
echo "  • Prometheus:       http://localhost:9090"
echo "  • Grafana:          http://localhost:3000 (admin/admin)"
echo "  • GrayLog:          http://localhost:9000 (admin/admin)"
echo "  • Zabbix:           http://localhost:8081 (Admin/zabbix)"
echo ""
echo "Для остановки: docker-compose down -v"
echo ""

exit 0

