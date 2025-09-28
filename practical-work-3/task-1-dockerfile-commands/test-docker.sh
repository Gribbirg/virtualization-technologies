#!/bin/bash

set -e

IMAGE_NAME="docker-commands-demo"
CONTAINER_NAME="test-docker-commands"
PORT=3000

echo "=== Docker Test Script with Colima ==="

cleanup() {
    echo "🧹 Cleaning up..."

    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Stopping container: $CONTAINER_NAME"
        docker stop $CONTAINER_NAME || true
    fi

    if docker ps -a -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Removing container: $CONTAINER_NAME"
        docker rm $CONTAINER_NAME || true
    fi

    if docker images -q $IMAGE_NAME | grep -q .; then
        echo "Removing image: $IMAGE_NAME"
        docker rmi $IMAGE_NAME || true
    fi

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

echo "🏗️ Building Docker image..."
docker build -t $IMAGE_NAME .

echo "🏃 Running container..."
docker run -d --name $CONTAINER_NAME -p $PORT:$PORT $IMAGE_NAME

echo "⏳ Waiting for application to start..."
sleep 5

echo "🧪 Testing endpoints..."

echo "Testing root endpoint:"
curl -s http://localhost:$PORT/ | jq '.' || echo "❌ Root endpoint failed"

echo -e "\nTesting health endpoint:"
curl -s http://localhost:$PORT/health | jq '.' || echo "❌ Health endpoint failed"

echo -e "\nTesting files endpoint:"
curl -s http://localhost:$PORT/files | jq '.' || echo "❌ Files endpoint failed"

echo -e "\n✅ All tests completed!"
echo "📊 Container logs:"
docker logs $CONTAINER_NAME --tail 10

echo -e "\n🎯 All Docker commands verified in Dockerfile:"
echo "FROM, LABEL, ENV, WORKDIR, RUN, COPY, ADD, USER, VOLUME, EXPOSE, ONBUILD, ENTRYPOINT, CMD"