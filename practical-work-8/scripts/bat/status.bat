@echo off
setlocal

set NAMESPACE=task-management

echo ==========================================
echo   Task Management System Status
echo ==========================================
echo.

echo [INFO] Minikube Status:
minikube status
echo.

echo [INFO] Namespace: %NAMESPACE%
echo.

echo [INFO] Pods:
kubectl get pods -n %NAMESPACE% -o wide
echo.

echo [INFO] Services:
kubectl get svc -n %NAMESPACE%
echo.

echo [INFO] Persistent Volume Claims:
kubectl get pvc -n %NAMESPACE%
echo.

echo [INFO] Helm Releases:
helm list -n %NAMESPACE%
echo.

echo [INFO] Resource Usage:
kubectl top pods -n %NAMESPACE% 2>nul || echo Metrics not available (metrics-server may not be ready)
echo.

echo [INFO] Recent Events:
kubectl get events -n %NAMESPACE% --sort-by=.lastTimestamp
echo.

echo ==========================================
echo To view logs:
echo   kubectl logs -n %NAMESPACE% ^<pod-name^> -f
echo.
echo To access services:
echo   scripts\bat\port-forward.bat
echo.
echo To test the system:
echo   scripts\bat\test-system.bat
echo ==========================================
