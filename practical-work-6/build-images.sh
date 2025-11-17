#!/bin/bash

set -e

echo "=================================="
echo "Docker Images Build Script"
echo "Practical Work 6"
echo "Author: Gribkov A.S. IKBO-16-22"
echo "=================================="
echo ""

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

DOCKER_USERNAME=${DOCKER_USERNAME:-"gribkov"}
PUSH_IMAGES=${PUSH_IMAGES:-"no"}

echo "Docker username: ${DOCKER_USERNAME}"
echo "Push to registry: ${PUSH_IMAGES}"
echo ""

if ! command -v docker &> /dev/null; then
    error_exit "Docker is not installed"
fi
success_msg "Docker is available"
echo ""

info_msg "Building static-files image..."
cd app/fileserver
docker build -t ${DOCKER_USERNAME}/static-files:v1 .
success_msg "Built ${DOCKER_USERNAME}/static-files:v1"
cd ../..
echo ""

info_msg "Checking if journal-server source code exists..."
if [ -d "kbp-sample/example-app" ]; then
    info_msg "Building journal-server image from kbp-sample..."
    cd kbp-sample/example-app
    docker build -t ${DOCKER_USERNAME}/journal-server:v1 .
    success_msg "Built ${DOCKER_USERNAME}/journal-server:v1"
    cd ../..
else
    info_msg "kbp-sample not found. Using existing image or pull from registry."
    info_msg "You can use: docker pull denbikmaev/journal-server:latest"
    info_msg "Then tag it: docker tag denbikmaev/journal-server:latest ${DOCKER_USERNAME}/journal-server:v1"
fi
echo ""

if [ "$PUSH_IMAGES" = "yes" ]; then
    info_msg "Logging in to Docker Hub..."
    docker login

    info_msg "Pushing images to Docker Hub..."
    docker push ${DOCKER_USERNAME}/static-files:v1
    success_msg "Pushed ${DOCKER_USERNAME}/static-files:v1"

    if docker images | grep -q "${DOCKER_USERNAME}/journal-server"; then
        docker push ${DOCKER_USERNAME}/journal-server:v1
        success_msg "Pushed ${DOCKER_USERNAME}/journal-server:v1"
    fi

    echo ""
    success_msg "All images pushed successfully!"
else
    info_msg "Images built locally. To push to registry, run:"
    echo "  PUSH_IMAGES=yes ./build-images.sh"
    echo ""
    info_msg "Or manually push:"
    echo "  docker login"
    echo "  docker push ${DOCKER_USERNAME}/static-files:v1"
    echo "  docker push ${DOCKER_USERNAME}/journal-server:v1"
fi

echo ""
info_msg "Available images:"
docker images | grep -E "REPOSITORY|${DOCKER_USERNAME}/(static-files|journal-server)"

echo ""
success_msg "Build completed!"
echo ""
echo "Next steps:"
echo "  1. If using Minikube, load images: minikube image load ${DOCKER_USERNAME}/static-files:v1"
echo "  2. Run deployment: ./test.sh"
