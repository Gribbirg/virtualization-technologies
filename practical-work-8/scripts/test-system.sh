#!/bin/bash

NAMESPACE="task-management"
KRAKEND_URL="http://localhost:8080"
AUTH_URL="http://localhost:8081"
TASK_URL="http://localhost:8082"
NOTIFICATION_URL="http://localhost:8083"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=$3
    local method=${4:-GET}
    local data=${5:-}
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$url" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null || echo "000")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$url" 2>/dev/null || echo "000")
    fi
    
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_code" ]; then
        log_success "$name (HTTP $http_code)" >&2
        echo "$body"
        return 0
    else
        log_error "$name (Expected $expected_code, got $http_code)" >&2
        return 1
    fi
}

echo "=========================================="
echo "  System Integration Tests"
echo "=========================================="
echo ""

log_info "Checking if port forwarding is active..."
if ! curl -s "$AUTH_URL/actuator/health" > /dev/null 2>&1; then
    log_error "Services are not accessible. Please run ./scripts/port-forward.sh first"
    exit 1
fi
log_success "Port forwarding is active"
echo ""

log_info "Test 1: Health Checks"
test_endpoint "Auth Service Health" "$AUTH_URL/actuator/health" "200"
test_endpoint "Task Service Health" "$TASK_URL/actuator/health" "200"
test_endpoint "Notification Service Health" "$NOTIFICATION_URL/actuator/health" "200"
echo ""

log_info "Test 2: User Registration (через KrakenD)"
TEST_USER="testuser$(date +%s)"
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASSWORD="TestPassword123"
REGISTER_DATA="{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
REGISTER_RESPONSE=$(test_endpoint "Register User via KrakenD" "$KRAKEND_URL/auth/register" "200" "POST" "$REGISTER_DATA")
echo "$REGISTER_RESPONSE" | jq . 2>/dev/null || echo "$REGISTER_RESPONSE"
echo ""

log_info "Test 3: User Login (через KrakenD)"
LOGIN_DATA="{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}"
LOGIN_RESPONSE=$(test_endpoint "User Login via KrakenD" "$KRAKEND_URL/auth/login" "200" "POST" "$LOGIN_DATA")
echo "$LOGIN_RESPONSE" | jq . 2>/dev/null || echo "$LOGIN_RESPONSE"

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token' 2>/dev/null || echo "")
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    log_error "Failed to extract token from login response"
    exit 1
fi
log_success "Token extracted: ${TOKEN:0:20}..."
echo ""

log_info "Test 4: Token Validation"
curl -s -X GET "$AUTH_URL/api/auth/validate" \
    -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "Failed"
echo ""

log_info "Test 5: Create Task (через KrakenD)"
TASK_DATA='{"title":"Test Task","description":"This is a test task","status":"PENDING"}'
CREATE_TASK_RESPONSE=$(curl -s -X POST "$KRAKEND_URL/tasks" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$TASK_DATA")
echo "$CREATE_TASK_RESPONSE" | jq . 2>/dev/null || echo "$CREATE_TASK_RESPONSE"

TASK_ID=$(echo "$CREATE_TASK_RESPONSE" | jq -r '.id' 2>/dev/null || echo "")
if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "null" ]; then
    log_success "Task created with ID: $TASK_ID"
else
    log_error "Failed to create task"
fi
echo ""

log_info "Test 6: Get Tasks (через KrakenD)"
curl -s -X GET "$KRAKEND_URL/tasks" \
    -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "Failed"
echo ""

log_info "Test 7: Get Notifications (через KrakenD)"
sleep 2
curl -s -X GET "$KRAKEND_URL/notifications" \
    -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "Failed"
echo ""

log_info "Test 8: Get Task Statistics (прямое обращение)"
curl -s -X GET "$TASK_URL/api/tasks/stats" \
    -H "Authorization: Bearer $TOKEN" | jq . 2>/dev/null || echo "Failed"
echo ""

log_info "Test 9: Checking Kafka Topics"
KAFKA_POD=$(kubectl get pod -n $NAMESPACE -l app=kafka -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$KAFKA_POD" ]; then
    log_info "Kafka topics:"
    kubectl exec -n $NAMESPACE $KAFKA_POD -- kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null && log_success "Kafka topics listed" || log_error "Failed to list Kafka topics"
else
    log_error "Kafka pod not found"
fi
echo ""

log_info "Test 10: Checking Database Connections"
for db in auth-postgres task-postgres notification-postgres; do
    POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/instance=$db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD" ]; then
        kubectl exec -n $NAMESPACE $POD -- bash -c 'PGPASSWORD=$(cat /opt/bitnami/postgresql/secrets/postgres-password) pg_isready -h 127.0.0.1 -p 5432 -U postgres' > /dev/null 2>&1 && log_success "$db is ready" || log_error "$db is not ready"
    else
        log_error "$db pod not found"
    fi
done
echo ""

log_info "Test 11: Checking Redis"
REDIS_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}')
if [ -n "$REDIS_POD" ]; then
    kubectl exec -n $NAMESPACE $REDIS_POD -- redis-cli -a redis_password ping > /dev/null 2>&1 && log_success "Redis is ready" || log_error "Redis is not ready"
fi
echo ""

echo "=========================================="
log_success "ALL TESTS COMPLETED"
echo "=========================================="
echo ""
echo "📊 Monitoring URLs:"
echo "  - Grafana:    http://localhost:3000 (admin/admin)"
echo "  - Prometheus: http://localhost:9090"
echo "  - Jaeger:     http://localhost:16686"
echo ""
echo "🔍 To view logs:"
echo "  kubectl logs -n $NAMESPACE -l app=auth-service --tail=50"
echo "  kubectl logs -n $NAMESPACE -l app=task-service --tail=50"
echo "  kubectl logs -n $NAMESPACE -l app=notification-service --tail=50"
echo ""

