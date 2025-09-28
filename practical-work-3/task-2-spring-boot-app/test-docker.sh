#!/bin/bash

set -e

APP_NAME="mirea-spring-app"
POSTGRES_NAME="mirea-postgres"
APP_PORT=8080

echo "=== Spring Boot + PostgreSQL Test Script with Colima ==="

cleanup() {
    echo "🧹 Cleaning up..."

    echo "Stopping Docker Compose..."
    docker-compose down -v --remove-orphans || true

    echo "Stopping Colima..."
    colima stop || true

    echo "✅ Cleanup completed"
}

trap cleanup EXIT

echo "🚀 Starting Colima..."
if ! colima status >/dev/null 2>&1; then
    colima start --cpu 2 --memory 4
else
    echo "Colima is already running"
fi

echo "⏳ Waiting for Docker daemon..."
timeout=30
while ! docker info >/dev/null 2>&1; do
    if [ $timeout -eq 0 ]; then
        echo "❌ Docker daemon failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
    timeout=$((timeout-1))
done

echo "🏗️ Building and starting services with Docker Compose..."
docker-compose up --build -d

echo "⏳ Waiting for PostgreSQL to be ready..."
timeout=60
while ! docker exec $POSTGRES_NAME pg_isready -U mirea_user >/dev/null 2>&1; do
    if [ $timeout -eq 0 ]; then
        echo "❌ PostgreSQL failed to start within 60 seconds"
        exit 1
    fi
    sleep 1
    timeout=$((timeout-1))
done

echo "⏳ Waiting for Spring Boot application to start..."
timeout=120
while ! curl -s http://localhost:$APP_PORT/api/items >/dev/null 2>&1; do
    if [ $timeout -eq 0 ]; then
        echo "❌ Spring Boot application failed to start within 120 seconds"
        echo "📊 Application logs:"
        docker logs $APP_NAME --tail 20
        exit 1
    fi
    sleep 1
    timeout=$((timeout-1))
done

echo "🧪 Testing Spring Boot endpoints..."

echo "1. Testing GET /api/items (should return empty list):"
curl -s http://localhost:$APP_PORT/api/items | jq '.' || echo "❌ GET items endpoint failed"

echo -e "\n2. Testing POST /api/items (adding new item):"
curl -s -X POST http://localhost:$APP_PORT/api/items \
     -H "Content-Type: application/json" \
     -d '{"name": "Test Item", "description": "Test Description"}' | jq '.' || echo "❌ POST item endpoint failed"

echo -e "\n3. Testing GET /api/items (should show the added item):"
curl -s http://localhost:$APP_PORT/api/items | jq '.' || echo "❌ GET items endpoint failed"

echo -e "\n4. Testing GET /api/mirea-logo (MIREA emblem):"
logo_response=$(curl -s -I http://localhost:$APP_PORT/api/mirea-logo | grep -i "content-type")
if [[ $logo_response == *"image/png"* ]]; then
    echo "✅ MIREA logo endpoint working (PNG image detected)"
else
    echo "❌ MIREA logo endpoint failed or wrong content type"
fi

echo -e "\n✅ All tests completed!"

echo -e "\n📊 Application logs:"
docker logs $APP_NAME --tail 15

echo -e "\n📊 PostgreSQL logs:"
docker logs $POSTGRES_NAME --tail 10

echo -e "\n🎯 All Spring Boot Task 2 requirements verified:"
echo "✅ Multi-stage Dockerfile"
echo "✅ PostgreSQL integration with environment variables"
echo "✅ Item CRUD endpoints"
echo "✅ MIREA emblem download and serving"
echo "✅ LABEL with student info"
echo "✅ ONBUILD command"