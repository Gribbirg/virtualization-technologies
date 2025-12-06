#!/bin/bash

set -e

echo "=== Task Service Test Script ==="
echo ""

BASE_URL="${BASE_URL:-http://localhost:8082}"
AUTH_URL="${AUTH_URL:-http://localhost:8081}"

echo "Base URL: $BASE_URL"
echo "Auth URL: $AUTH_URL"
echo ""

echo "Step 1: Check health endpoints..."
curl -s "$BASE_URL/actuator/health" | jq '.'
echo ""

echo "Step 2: Register test user..."
REGISTER_RESPONSE=$(curl -s -X POST "$AUTH_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123!"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
echo ""

echo "Step 3: Login and get token..."
LOGIN_RESPONSE=$(curl -s -X POST "$AUTH_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Test123!"
  }')
echo "$LOGIN_RESPONSE" | jq '.'

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to get token"
  exit 1
fi
echo "Token obtained: ${TOKEN:0:20}..."
echo ""

echo "Step 4: Create task..."
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/tasks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task",
    "status": "PENDING"
  }')
echo "$CREATE_RESPONSE" | jq '.'

TASK_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')
echo "Created task ID: $TASK_ID"
echo ""

echo "Step 5: Get all tasks..."
curl -s -X GET "$BASE_URL/api/tasks" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "Step 6: Get task by ID..."
curl -s -X GET "$BASE_URL/api/tasks/$TASK_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "Step 7: Update task..."
curl -s -X PUT "$BASE_URL/api/tasks/$TASK_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Updated Test Task",
    "description": "This task has been updated",
    "status": "IN_PROGRESS"
  }' | jq '.'
echo ""

echo "Step 8: Get task statistics..."
curl -s -X GET "$BASE_URL/api/tasks/stats" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "Step 9: Create another task..."
curl -s -X POST "$BASE_URL/api/tasks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Second Task",
    "description": "Another test task",
    "status": "COMPLETED"
  }' | jq '.'
echo ""

echo "Step 10: Get tasks with filter (status=COMPLETED)..."
curl -s -X GET "$BASE_URL/api/tasks?status=COMPLETED" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

echo "Step 11: Delete task..."
curl -s -X DELETE "$BASE_URL/api/tasks/$TASK_ID" \
  -H "Authorization: Bearer $TOKEN" -w "\nHTTP Status: %{http_code}\n"
echo ""

echo "Step 12: Verify task deleted (should return 404)..."
curl -s -X GET "$BASE_URL/api/tasks/$TASK_ID" \
  -H "Authorization: Bearer $TOKEN" -w "\nHTTP Status: %{http_code}\n" | jq '.'
echo ""

echo "Step 13: Check Prometheus metrics..."
curl -s "$BASE_URL/actuator/prometheus" | grep "tasks_"
echo ""

echo "=== All tests completed successfully! ==="

