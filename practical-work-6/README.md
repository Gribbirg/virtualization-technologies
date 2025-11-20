# Practical Work 6 - Kubernetes Application Deployment

## TL;DR - Quick Commands

⚠️ **ВАЖНО:** Если возникают проблемы, читайте [docs/IMPORTANT.md](docs/IMPORTANT.md)

```bash
./scripts/setup-environment.sh    # Setup Colima & Minikube (first time only)
./scripts/build-images.sh         # Build Docker images
./scripts/test.sh                 # Deploy and test application
./scripts/port-forward-all.sh     # Setup port forwarding for all services
```

**Если что-то не работает:**
```bash
./scripts/setup-environment.sh    # Это исправит проблемы с окружением
./scripts/test.sh                 # Повторите развертывание
```

## Overview

This practical work demonstrates the deployment of a distributed application in Kubernetes consisting of:
- Frontend service (Node.js journal server)
- Redis StatefulSet (3 replicas with master-slave replication)
- Static file server (NGINX)
- Ingress controller for HTTP routing

## Prerequisites

- Docker Desktop OR Colima (recommended for macOS)
- Minikube
- kubectl

### Setup Environment (First Time)

**Important:** Before starting, ensure Docker/Colima is properly configured:

#### For macOS with Colima:

```bash
colima delete -f
colima start --cpu 2 --memory 4 --disk 20
```

#### Start Minikube:

```bash
minikube delete
minikube start --driver=docker --cpus=2 --memory=2048
```

**Note:** Use `--memory=2048` instead of higher values to avoid API server startup issues.

## Architecture

```
                    Ingress
                       |
        +--------------+--------------+
        |                             |
    /api path                     / path
        |                             |
    Frontend Service         FileServer Service
        |                             |
    Frontend Pods (x2)       FileServer Pods (x2)
        |
        +----> Redis Services
                    |
               Redis StatefulSet
            (Master + 2 Replicas)
```

## Project Structure

```
practical-work-6/
├── app/
│   ├── frontend/
│   │   ├── frontend.yaml          # Frontend Deployment
│   │   ├── traffic-service.yml    # Frontend Service
│   │   └── ingress.yaml           # Ingress configuration
│   ├── redis/
│   │   ├── redis.yml              # Redis StatefulSet
│   │   ├── redis-read.yml         # Service for read operations
│   │   ├── redis-write.yml        # Headless service for write operations
│   │   └── launch.sh              # Redis startup script
│   └── fileserver/
│       ├── Dockerfile             # Static files container
│       ├── fileserver.yml         # FileServer Deployment
│       ├── fileserver-service.yml # FileServer Service
│       └── static/
│           └── index.html         # Static content
├── README.md                      # This file
└── test.sh                        # Automated test script
```

## Quick Start Guide

### 1. Setup Environment (REQUIRED - Run First!)

**Automated Setup (Recommended):**

```bash
./setup-environment.sh
```

This script will:
- Check if Colima and Minikube are installed
- Delete existing clusters
- Start Colima with optimal settings
- Start Minikube with correct memory allocation
- Enable Ingress addon
- Verify cluster is working

**Manual Setup:**

```bash
colima delete -f
colima start --cpu 2 --memory 4 --disk 20

minikube delete
minikube start --driver=docker --cpus=2 --memory=2048
minikube addons enable ingress
```

### 2. Build Docker Images

```bash
./build-images.sh
```

### 3. Load Images to Minikube

```bash
minikube image load gribkov/static-files:v1
minikube image load gribkov/journal-server:v1
```

### 4. Create Kubernetes Resources

#### Step 1: Create ConfigMap for frontend configuration

```bash
kubectl create configmap frontend-config --from-literal=journalEntries=10
```

#### Step 2: Create Secret for Redis password

```bash
kubectl create secret generic redis-passwd --from-literal=passwd=$(openssl rand -base64 32)
```

#### Step 3: Create ConfigMap for Redis launch script

```bash
kubectl create configmap redis-config --from-file=launch.sh=app/redis/launch.sh
```

#### Step 4: Deploy Redis StatefulSet and Services

```bash
kubectl apply -f app/redis/redis.yml
kubectl apply -f app/redis/redis-read.yml
kubectl apply -f app/redis/redis-write.yml
```

#### Step 5: Deploy Frontend

```bash
kubectl apply -f app/frontend/frontend.yaml
kubectl apply -f app/frontend/traffic-service.yml
```

#### Step 6: Deploy FileServer

```bash
kubectl apply -f app/fileserver/fileserver.yml
kubectl apply -f app/fileserver/fileserver-service.yml
```

#### Step 7: Configure Ingress

```bash
kubectl apply -f app/frontend/ingress.yaml
```

**Wait for Ingress Controller:** After enabling ingress addon, wait 1-2 minutes for the controller to be ready before accessing services.

## Verification

### Check all resources

```bash
kubectl get all
kubectl get ingress
kubectl get configmap
kubectl get secret
kubectl get pvc
```

### Check Redis replication

```bash
kubectl exec redis-0 -- redis-cli -a $(kubectl get secret redis-passwd -o jsonpath='{.data.passwd}' | base64 -d) INFO replication
```

### Access the application

For Minikube:
```bash
minikube service frontend --url
```

Or get Ingress IP:
```bash
kubectl get ingress frontend-ingress
```

Then access:
- Static files: `http://<INGRESS_IP>/`
- API: `http://<INGRESS_IP>/api`

## Testing

Run the automated test script:

```bash
./test.sh
```

This script will:
1. Check if Kubernetes cluster is running
2. Create all necessary ConfigMaps and Secrets
3. Deploy all components
4. Verify deployments are ready
5. Test connectivity to services
6. Display access URLs

## Cleanup

To remove all resources:

```bash
./cleanup.sh
```

Or manually:

```bash
kubectl delete -f app/frontend/ingress.yaml
kubectl delete -f app/frontend/
kubectl delete -f app/fileserver/
kubectl delete -f app/redis/
kubectl delete configmap frontend-config redis-config
kubectl delete secret redis-passwd
kubectl delete pvc -l app=redis
```

## Troubleshooting

### Error: "failed to download openapi: EOF"

This means the Kubernetes API server is not responding. Solution:

```bash
minikube delete
colima restart
minikube start --driver=docker --cpus=2 --memory=2048
```

**Important:** Use `--memory=2048` (not 3072 or 4096) to avoid API server startup issues on macOS.

### Minikube API Server Not Starting

If `minikube status` shows `apiserver: Stopped`:

```bash
minikube delete
colima delete -f
colima start --cpu 2 --memory 4 --disk 20
minikube start --driver=docker --cpus=2 --memory=2048
```

### Docker/Colima Hanging

If Docker commands are slow or timeout:

```bash
pkill -f colima
colima delete -f
colima start --cpu 2 --memory 4 --disk 20
```

### Pods not starting

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Ingress status

```bash
kubectl describe ingress frontend-ingress
```

### Redis connection issues

```bash
kubectl exec -it redis-0 -- redis-cli -a $(kubectl get secret redis-passwd -o jsonpath='{.data.passwd}' | base64 -d) PING
```

## Quick Start

For a quick 5-minute setup, see [docs/QUICK_START.md](docs/QUICK_START.md)

For a detailed demonstration guide for your teacher, see [docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md)

## Port Forwarding

To access services from your local machine:

```bash
./scripts/port-forward-all.sh
```

This will setup port forwarding for:
- Frontend API (Journal Server): http://localhost:8083/api
- File Server (Static files): http://localhost:8081/
- Redis: localhost:6379

## Author

Gribkov A.S. IKBO-16-22

## References

- Kubernetes Documentation: https://kubernetes.io/docs/
- Kubernetes Best Practices Book
- Redis Replication: https://redis.io/topics/replication
