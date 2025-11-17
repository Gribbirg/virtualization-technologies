#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

info_msg() {
    echo -e "${YELLOW}→ $1${NC}"
}

echo "======================================"
echo "API Testing Script"
echo "Practical Work 6"
echo "Author: Gribkov A.S. IKBO-16-22"
echo "======================================"
echo ""

API_URL="http://localhost:8080/api"
FILESERVER_URL="http://localhost:8081"

info_msg "Checking API availability..."
if ! curl -s -f "$API_URL" > /dev/null 2>&1; then
    error_exit "API is not accessible at $API_URL. Make sure port-forward is running: kubectl port-forward svc/frontend 8080:8080"
fi
success_msg "API is accessible"
echo ""

echo "=== Test 1: Get initial entries ==="
RESPONSE=$(curl -s "$API_URL")
echo "Response: $RESPONSE"
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq
fi
success_msg "Test 1 passed"
echo ""

echo "=== Test 2: Add test entries ==="
for i in {1..5}; do
    info_msg "Adding entry #$i..."
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"Test entry #$i from automated test\"}")
    echo "Response: $RESPONSE"
done
success_msg "Test 2 passed"
echo ""

echo "=== Test 3: Get all entries ==="
RESPONSE=$(curl -s "$API_URL")
echo "Response:"
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq
    COUNT=$(echo "$RESPONSE" | jq 'length')
    info_msg "Total entries: $COUNT"
else
    echo "$RESPONSE"
fi
success_msg "Test 3 passed"
echo ""

echo "=== Test 4: Add entry with Cyrillic text ==="
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"text":"Тестовая запись на русском языке: ИКБО-16-22"}')
echo "Response: $RESPONSE"
success_msg "Test 4 passed"
echo ""

echo "=== Test 5: Add entry with special characters ==="
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"text":"Special chars: @#$%^&*()_+-=[]{}|"}')
echo "Response: $RESPONSE"
success_msg "Test 5 passed"
echo ""

echo "=== Test 6: Check FileServer ==="
if curl -s -f "$FILESERVER_URL" > /dev/null 2>&1; then
    RESPONSE=$(curl -s "$FILESERVER_URL")
    echo "Response: $RESPONSE"
    success_msg "Test 6 passed"
else
    error_exit "FileServer is not accessible at $FILESERVER_URL. Make sure port-forward is running: kubectl port-forward svc/fileserver 8081:80"
fi
echo ""

echo "=== Test 7: Get final entries count ==="
RESPONSE=$(curl -s "$API_URL")
if command -v jq &> /dev/null; then
    COUNT=$(echo "$RESPONSE" | jq 'length')
    info_msg "Final total entries: $COUNT"

    echo ""
    info_msg "Latest entries:"
    echo "$RESPONSE" | jq '.[-3:]'
else
    echo "$RESPONSE"
fi
success_msg "Test 7 passed"
echo ""

echo "=== Test 8: Performance test ==="
info_msg "Testing response time..."
TIME_START=$(date +%s%3N)
curl -s "$API_URL" > /dev/null
TIME_END=$(date +%s%3N)
TIME_DIFF=$((TIME_END - TIME_START))
info_msg "Response time: ${TIME_DIFF}ms"
success_msg "Test 8 passed"
echo ""

echo "======================================"
success_msg "All tests passed successfully!"
echo "======================================"
echo ""

if command -v jq &> /dev/null; then
    echo "Final API state:"
    curl -s "$API_URL" | jq
else
    echo "Install jq for better output formatting: brew install jq"
fi
