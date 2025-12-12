#!/bin/bash

echo "Starting port-forward for all services..."
echo ""

kubectl port-forward service/frontend 8085:8080 > /dev/null 2>&1 &
FRONTEND_PID=$!
echo "✓ Frontend API (Journal Server): http://localhost:8085/api (PID: $FRONTEND_PID)"

kubectl port-forward service/fileserver 8086:80 > /dev/null 2>&1 &
FILESERVER_PID=$!
echo "✓ File Server (Static files): http://localhost:8086/ (PID: $FILESERVER_PID)"

kubectl port-forward service/redis 6379:6379 > /dev/null 2>&1 &
REDIS_PID=$!
echo "✓ Redis: localhost:6379 (PID: $REDIS_PID)"

echo ""
echo "All port-forwards are running in background."
echo ""
echo "Test commands:"
echo "  curl http://localhost:8085/api                                    # GET journal entries"
echo "  curl -X POST http://localhost:8085/api -H 'Content-Type: application/json' -d '{\"author\":\"Test\",\"message\":\"Hello\"}'"
echo "  curl http://localhost:8086/                                       # Static files"
echo "  redis-cli -h localhost -p 6379 -a \$(kubectl get secret redis-passwd -o jsonpath='{.data.passwd}' | base64 -d) PING"
echo ""
echo "To stop all port-forwards, run:"
echo "  pkill -f 'kubectl port-forward'"
echo ""
echo "PIDs: Frontend=$FRONTEND_PID, FileServer=$FILESERVER_PID, Redis=$REDIS_PID"