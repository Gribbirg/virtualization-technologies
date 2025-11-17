# Practical Work 6 - Kubernetes Application Deployment

## Overview

This practical work demonstrates the deployment of a distributed application in Kubernetes consisting of:
- Frontend service (Node.js journal server)
- Redis StatefulSet (3 replicas with master-slave replication)
- Static file server (NGINX)
- Ingress controller for HTTP routing

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Docker (for building images)

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

## Build Instructions

### 1. Build Docker Images

You can use the automated build script:

```bash
./build-images.sh
```

To build and push to Docker Hub:

```bash
PUSH_IMAGES=yes DOCKER_USERNAME=your-username ./build-images.sh
```

Or manually:

```bash
cd practical-work-6/app/fileserver
docker build -t gribkov/static-files:v1 .
docker push gribkov/static-files:v1
```

For frontend, you can build from the kbp-sample or use the automated script.

### 2. Create Kubernetes Resources

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

### 3. Enable Ingress Controller (for Minikube)

```bash
minikube addons enable ingress
```

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

For a quick 5-minute setup, see [QUICK_START.md](QUICK_START.md)

For a detailed demonstration guide for your teacher, see [DEMO_GUIDE.md](DEMO_GUIDE.md)

## Author

Gribkov A.S. IKBO-16-22

## References

- Kubernetes Documentation: https://kubernetes.io/docs/
- Kubernetes Best Practices Book
- Redis Replication: https://redis.io/topics/replication
