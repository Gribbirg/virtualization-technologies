#!/bin/bash

set -e

DOCKER_USERNAME="gribbirg"
IMAGE_NAME="spring-boot-mirea"
TAG="latest"
VERSION_TAG="1.0"

echo "=== Загрузка образа на Docker Hub ==="
echo ""

echo "Шаг 1: Проверка Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен"
    exit 1
fi
echo "✓ Docker найден"

echo ""
echo "Шаг 2: Проверка авторизации Docker Hub..."
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo "⚠️  Вы не авторизованы в Docker Hub"
    echo "Выполните команду: docker login"
    echo "Затем запустите скрипт снова"
    exit 1
fi
echo "✓ Авторизация найдена"

echo ""
echo "Шаг 3: Сборка образа..."
docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} .

echo ""
echo "Шаг 4: Добавление тега версии..."
docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION_TAG}

echo ""
echo "Шаг 5: Загрузка образа на Docker Hub..."
echo "Загрузка тега: ${TAG}..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}

echo "Загрузка тега: ${VERSION_TAG}..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION_TAG}

echo ""
echo "=== ✓ Успешно загружено! ==="
echo ""
echo "Образ доступен по адресу:"
echo "https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
echo ""
echo "Команда для использования:"
echo "docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo ""
