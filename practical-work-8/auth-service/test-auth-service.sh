#!/bin/bash

set -e

echo "=========================================="
echo "Auth Service Test Script"
echo "=========================================="
echo ""

BASE_URL="${BASE_URL:-http://localhost:8081}"
API_BASE="$BASE_URL/api/auth"

echo "Testing Auth Service at: $BASE_URL"
echo ""

echo "1. Testing Health Endpoints..."
echo "   - Liveness probe..."
curl -s "$BASE_URL/actuator/health/liveness" | jq '.' || echo "Failed"

echo "   - Readiness probe..."
curl -s "$BASE_URL/actuator/health/readiness" | jq '.' || echo "Failed"

echo ""
echo "2. Testing User Registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser_'$(date +%s)'",
    "email": "test_'$(date +%s)'@example.com",
    "password": "TestPass123!"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

if echo "$REGISTER_RESPONSE" | jq -e '.id' > /dev/null; then
    echo "✓ Registration successful"
else
    echo "✗ Registration failed"
    exit 1
fi

USERNAME=$(echo "$REGISTER_RESPONSE" | jq -r '.username')
echo ""

echo "3. Testing User Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'$USERNAME'",
    "password": "TestPass123!"
  }')

echo "$LOGIN_RESPONSE" | jq '.'

if echo "$LOGIN_RESPONSE" | jq -e '.token' > /dev/null; then
    echo "✓ Login successful"
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
else
    echo "✗ Login failed"
    exit 1
fi

echo ""
echo "4. Testing Token Validation..."
VALIDATE_RESPONSE=$(curl -s -X GET "$API_BASE/validate" \
  -H "Authorization: Bearer $TOKEN")

echo "$VALIDATE_RESPONSE" | jq '.'

if echo "$VALIDATE_RESPONSE" | jq -e '.valid' | grep -q 'true'; then
    echo "✓ Token validation successful"
else
    echo "✗ Token validation failed"
    exit 1
fi

echo ""
echo "5. Testing Get Current User..."
ME_RESPONSE=$(curl -s -X GET "$API_BASE/me" \
  -H "Authorization: Bearer $TOKEN")

echo "$ME_RESPONSE" | jq '.'

if echo "$ME_RESPONSE" | jq -e '.username' > /dev/null; then
    echo "✓ Get current user successful"
else
    echo "✗ Get current user failed"
    exit 1
fi

echo ""
echo "6. Testing Logout..."
LOGOUT_RESPONSE=$(curl -s -X POST "$API_BASE/logout" \
  -H "Authorization: Bearer $TOKEN")

echo "$LOGOUT_RESPONSE" | jq '.'

if echo "$LOGOUT_RESPONSE" | jq -e '.message' > /dev/null; then
    echo "✓ Logout successful"
else
    echo "✗ Logout failed"
    exit 1
fi

echo ""
echo "7. Testing Token After Logout (should fail)..."
VALIDATE_AFTER_LOGOUT=$(curl -s -X GET "$API_BASE/validate" \
  -H "Authorization: Bearer $TOKEN")

echo "$VALIDATE_AFTER_LOGOUT" | jq '.'

if echo "$VALIDATE_AFTER_LOGOUT" | jq -e '.valid' | grep -q 'false'; then
    echo "✓ Token correctly invalidated after logout"
else
    echo "✗ Token still valid after logout (unexpected)"
fi

echo ""
echo "8. Testing Prometheus Metrics..."
curl -s "$BASE_URL/actuator/prometheus" | grep -E "(auth_registrations_total|auth_logins_total)" || echo "Metrics not found"

echo ""
echo "=========================================="
echo "All tests completed successfully!"
echo "=========================================="

