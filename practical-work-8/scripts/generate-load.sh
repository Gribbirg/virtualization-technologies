#!/bin/bash

echo "=== Generating load for Grafana dashboards ==="

TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"loaduser1","password":"TestPass123"}' | jq -r '.token')

echo "Token obtained: ${TOKEN:0:30}..."

echo ""
echo "=== Registering users ==="
for i in $(seq 1 20); do
  curl -s -X POST http://localhost:8081/api/auth/register \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"user$i\",\"email\":\"user$i@test.com\",\"password\":\"TestPass123\"}" > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Creating tasks ==="
for i in $(seq 1 30); do
  curl -s -X POST http://localhost:8082/api/tasks \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"title\":\"Task $i\",\"description\":\"Description for task $i\",\"status\":\"PENDING\"}" > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Fetching tasks ==="
for i in $(seq 1 50); do
  curl -s http://localhost:8082/api/tasks \
    -H "Authorization: Bearer $TOKEN" > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Fetching notifications ==="
for i in $(seq 1 30); do
  curl -s http://localhost:8083/api/notifications \
    -H "Authorization: Bearer $TOKEN" > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Checking health endpoints ==="
for i in $(seq 1 20); do
  curl -s http://localhost:8081/actuator/health > /dev/null
  curl -s http://localhost:8082/actuator/health > /dev/null
  curl -s http://localhost:8083/actuator/health > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Login attempts ==="
for i in $(seq 1 20); do
  curl -s -X POST http://localhost:8081/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"loaduser1","password":"TestPass123"}' > /dev/null
  echo -n "."
done
echo " Done"

echo ""
echo "=== Load generation complete ==="
echo "Check Grafana at http://localhost:3000"
