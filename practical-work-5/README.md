# Practical Work 5: Kubernetes and Minikube

## Description

This practical work demonstrates deployment of a simple Node.js HTTP server using Kubernetes and Minikube.

## Prerequisites

- Docker installed
- Minikube installed
- kubectl installed

## Project Structure

```
practical-work-5/
├── server.js          # Node.js HTTP server
├── Dockerfile         # Docker image configuration
├── deployment.yaml    # Kubernetes deployment manifest
├── test.sh           # Automated test script
└── README.md         # This file
```

## Build Instructions

### 1. Start Minikube

```bash
minikube start
```

### 2. Configure Docker to use Minikube's Docker daemon

```bash
eval $(minikube docker-env)
```

### 3. Build Docker Image

```bash
docker build -t gribkov-ikbo-16-22-obraz .
```

### 4. Verify the image was created

```bash
docker images | grep gribkov-ikbo-16-22-obraz
```

## Run Instructions

### 1. Create Deployment

```bash
kubectl apply -f deployment.yaml
```

### 2. Verify Deployment

```bash
kubectl get deployments
kubectl get pods
```

### 3. Expose Service

```bash
kubectl expose deployment gribkov-ikbo-16-22 --type=NodePort --port=8080
```

### 4. Get Service URL

```bash
minikube service gribkov-ikbo-16-22 --url
```

### 5. Test the Service

```bash
curl $(minikube service gribkov-ikbo-16-22 --url)
```

Expected output: `Hello World!`

## Automated Testing

Run the automated test script:

```bash
chmod +x test.sh
./test.sh
```

## Useful Commands

### View deployment information
```bash
kubectl get deployments
```

### View pod information
```bash
kubectl get pods
```

### View cluster events
```bash
kubectl get events
```

### View kubectl configuration
```bash
kubectl config view
```

### View services
```bash
kubectl get services
```

### View addon list
```bash
minikube addons list
```

### Enable ingress addon
```bash
minikube addons enable ingress
```

### Check ingress pods
```bash
kubectl get pod,svc -n kube-system
```

### Disable ingress addon
```bash
minikube addons disable ingress
```

### Open Kubernetes Dashboard
```bash
minikube dashboard
```

## Cleanup

### Delete service
```bash
kubectl delete service gribkov-ikbo-16-22
```

### Delete deployment
```bash
kubectl delete deployment gribkov-ikbo-16-22
```

### Stop Minikube
```bash
minikube stop
```

### Delete Minikube cluster (optional)
```bash
minikube delete
```

## Troubleshooting

If you encounter issues:

1. Check Minikube status:
   ```bash
   minikube status
   ```

2. Check pod logs:
   ```bash
   kubectl logs <pod-name>
   ```

3. Describe pod for detailed information:
   ```bash
   kubectl describe pod <pod-name>
   ```

## Author

Gribkov A.S., IKBO-16-22
