#!/bin/bash
NAMESPACE="task-management"

echo "Setting up port forwarding..."
echo "Press Ctrl+C to stop all port forwards"
echo ""

kubectl port-forward -n $NAMESPACE svc/krakend 8080:8080 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/auth-service 8081:8081 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/task-service 8082:8082 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/notification-service 8083:8083 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/web-client 8084:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/graylog 9000:9000 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/grafana 3000:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/jaeger-query 16686:16686 > /dev/null 2>&1 &

sleep 2

echo "Port forwarding active:"
echo "  Web Client:          http://localhost:8084"
echo "  KrakenD (Gateway):   http://localhost:8080"
echo "  Auth Service:        http://localhost:8081"
echo "  Task Service:        http://localhost:8082"
echo "  Notification Service: http://localhost:8083"
echo "  Graylog:             http://localhost:9000 (admin/admin)"
echo "  Grafana:             http://localhost:3000 (admin/admin)"
echo "  Prometheus:          http://localhost:9090"
echo "  Jaeger:              http://localhost:16686"
echo ""
echo "Press Ctrl+C to stop"

wait
