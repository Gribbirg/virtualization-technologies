# Demonstration Guide for Practical Work 5

This guide contains step-by-step commands for demonstrating the practical work functionality.

## Prerequisites

Ensure that kubectl and minikube are installed:

```bash
kubectl version --client
minikube version
```

---

## Part 1: Launch and Setup

### 1.1. Start Minikube

```bash
minikube start
```

Expected output:
- Minikube cluster starts successfully
- Control plane node is created
- Kubernetes is configured

### 1.2. Check Minikube Status

```bash
minikube status
```

Expected output:
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### 1.3. Configure Docker Environment

```bash
eval $(minikube docker-env)
```

This command configures your shell to use Minikube's Docker daemon.

### 1.4. Build Docker Image

```bash
docker build -t gribkov-ikbo-16-22-obraz .
```

### 1.5. Verify Image is Built

```bash
docker images | grep gribkov-ikbo-16-22-obraz
```

---

## Part 2: Demonstrate Minikube Functionality

### 2.1. View Cluster Information

```bash
kubectl cluster-info
```

Expected output shows master and KubeDNS running.

### 2.2. View Nodes

```bash
kubectl get nodes
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   XXm   vX.XX.X
```

### 2.3. Create Deployment

```bash
kubectl apply -f deployment.yaml
```

Expected output:
```
deployment.apps/gribkov-ikbo-16-22 created
```

### 2.4. View Deployments

```bash
kubectl get deployments
```

Expected output:
```
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
gribkov-ikbo-16-22   1/1     1            1           XXs
```

### 2.5. View Pods

```bash
kubectl get pods
```

Expected output:
```
NAME                                  READY   STATUS    RESTARTS   AGE
gribkov-ikbo-16-22-XXXXXXXXXX-XXXXX   1/1     Running   0          XXs
```

### 2.6. View Detailed Pod Information

```bash
kubectl describe pod <pod-name>
```

Replace `<pod-name>` with the actual pod name from previous command.

### 2.7. View Pod Logs

```bash
kubectl logs <pod-name>
```

This shows the Node.js server output.

### 2.8. View Cluster Events

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

Shows all cluster events in chronological order.

### 2.9. View kubectl Configuration

```bash
kubectl config view
```

Shows the current cluster configuration.

---

## Part 3: Demonstrate Node Functionality

### 3.1. Expose Service

```bash
kubectl expose deployment gribkov-ikbo-16-22 --type=NodePort --port=8080
```

Expected output:
```
service/gribkov-ikbo-16-22 exposed
```

### 3.2. View Services

```bash
kubectl get services
```

Expected output:
```
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
gribkov-ikbo-16-22   NodePort    10.XXX.XXX.XXX   <none>        8080:XXXXX/TCP   XXs
kubernetes           ClusterIP   10.96.0.1        <none>        443/TCP          XXm
```

### 3.3. Get Service Details

```bash
kubectl describe service gribkov-ikbo-16-22
```

### 3.4. Get Service URL

```bash
minikube ip
kubectl get service gribkov-ikbo-16-22 -o jsonpath='{.spec.ports[0].nodePort}'
```

Note the IP and port for the next step.

### 3.5. Test Service via Port-Forward

Open a new terminal and run:

```bash
kubectl port-forward service/gribkov-ikbo-16-22 8080:8080
```

Keep this terminal open. In another terminal, test the service:

```bash
curl http://localhost:8080
```

Expected output:
```
Hello World!
```

After testing, press `Ctrl+C` in the port-forward terminal to stop.

### 3.6. View Resource Usage

```bash
kubectl top nodes
kubectl top pods
```

Note: This requires metrics-server addon to be enabled.

---

## Part 4: Demonstrate Kubernetes Dashboard

### 4.1. Enable Dashboard Addon

```bash
minikube addons enable dashboard
```

Expected output:
```
✅  dashboard was successfully enabled
```

### 4.2. Enable Metrics Server (Optional but Recommended)

```bash
minikube addons enable metrics-server
```

### 4.3. View Dashboard Pods

```bash
kubectl get pod,svc -n kubernetes-dashboard
```

Wait until all pods are in Running status.

### 4.4. Open Kubernetes Dashboard

```bash
minikube dashboard
```

This command will automatically open the dashboard in your default browser.

The dashboard shows:
- **Workloads**: Deployments, Pods, ReplicaSets
- **Services**: Service endpoints and ports
- **Storage**: Persistent volumes and claims
- **Config**: ConfigMaps and Secrets
- **Cluster**: Nodes and namespaces

### 4.5. Navigate to Deployment in Dashboard

In the dashboard:
1. Click on "Deployments" in the left menu
2. Find and click on `gribkov-ikbo-16-22`
3. Review displayed parameters:
   - Replica count
   - Pod status
   - Container image
   - Resource limits
   - Labels and selectors
   - Events

### 4.6. Check Pods in Dashboard

1. Click on "Pods" in the left menu
2. Find your pod `gribkov-ikbo-16-22-*`
3. Click on it to see:
   - Container details
   - Resource usage
   - Logs (click "Logs" button)
   - Events

---

## Part 5: View Addons

### 5.1. List All Available Addons

```bash
minikube addons list
```

Shows all addons with their status (enabled/disabled).

### 5.2. Enable Ingress Addon (Example)

```bash
minikube addons enable ingress
```

### 5.3. View Ingress Pods

```bash
kubectl get pod,svc -n ingress-nginx
```

### 5.4. Disable Ingress Addon

```bash
minikube addons disable ingress
```

---

## Part 6: Cleanup

### 6.1. Delete Service

```bash
kubectl delete service gribkov-ikbo-16-22
```

Expected output:
```
service "gribkov-ikbo-16-22" deleted
```

### 6.2. Delete Deployment

```bash
kubectl delete deployment gribkov-ikbo-16-22
```

Expected output:
```
deployment.apps "gribkov-ikbo-16-22" deleted
```

### 6.3. Verify Resources are Deleted

```bash
kubectl get all
```

Should only show the default kubernetes service.

### 6.4. Disable Dashboard (Optional)

```bash
minikube addons disable dashboard
minikube addons disable metrics-server
```

### 6.5. Stop Minikube

```bash
minikube stop
```

Expected output:
```
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
🛑  1 node stopped.
```

### 6.6. Delete Minikube Cluster (Optional - Complete Cleanup)

⚠️ **Warning**: This will completely remove the cluster and all data!

```bash
minikube delete
```

Expected output:
```
🔥  Deleting "minikube" in docker ...
🔥  Deleting container "minikube" ...
🔥  Removing /Users/username/.minikube/machines/minikube ...
💀  Removed all traces of the "minikube" cluster.
```

### 6.7. Verify Minikube is Stopped

```bash
minikube status
```

Expected output:
```
❌  There is no local cluster named "minikube"
```

---

## Quick Reference Commands

### Check Status
```bash
minikube status
kubectl cluster-info
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get services
```

### View Logs and Details
```bash
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl describe deployment gribkov-ikbo-16-22
kubectl get events
```

### Dashboard
```bash
minikube dashboard
```

### Cleanup
```bash
kubectl delete service gribkov-ikbo-16-22
kubectl delete deployment gribkov-ikbo-16-22
minikube stop
minikube delete
```

---

## Automated Testing

To run all demonstration steps automatically:

```bash
./test.sh
```

This script will:
1. Start Minikube (if not running)
2. Build Docker image
3. Create deployment
4. Expose service
5. Test the service
6. Display all relevant information

---

## Troubleshooting

### Minikube won't start
```bash
minikube delete
minikube start --driver=docker
```

### Pods are not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service is not accessible
```bash
kubectl get svc
kubectl describe svc gribkov-ikbo-16-22
```

### Dashboard won't open
```bash
minikube addons disable dashboard
minikube addons enable dashboard
kubectl get pod -n kubernetes-dashboard
minikube dashboard
```

---

## Author

Gribkov A.S., IKBO-16-22
