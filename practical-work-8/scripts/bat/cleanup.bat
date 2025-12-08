@echo off
setlocal enabledelayedexpansion

set NAMESPACE=task-management

echo ==========================================
echo   Cleanup Task Management System
echo ==========================================
echo.

echo [INFO] Uninstalling microservices...
helm uninstall auth-service -n %NAMESPACE% 2>nul
helm uninstall task-service -n %NAMESPACE% 2>nul
helm uninstall notification-service -n %NAMESPACE% 2>nul
echo [SUCCESS] Microservices uninstalled
echo.

echo [INFO] Uninstalling infrastructure...
helm uninstall auth-postgres -n %NAMESPACE% 2>nul
helm uninstall task-postgres -n %NAMESPACE% 2>nul
helm uninstall notification-postgres -n %NAMESPACE% 2>nul
helm uninstall redis -n %NAMESPACE% 2>nul
helm uninstall kafka -n %NAMESPACE% 2>nul
helm uninstall prometheus -n %NAMESPACE% 2>nul
helm uninstall grafana -n %NAMESPACE% 2>nul
helm uninstall jaeger -n %NAMESPACE% 2>nul
echo [SUCCESS] Infrastructure uninstalled
echo.

echo [INFO] Deleting PVCs...
kubectl delete pvc --all -n %NAMESPACE% 2>nul
echo [SUCCESS] PVCs deleted
echo.

echo [INFO] Deleting namespace...
kubectl delete namespace %NAMESPACE% 2>nul
echo [SUCCESS] Namespace deleted
echo.

set /p DELETE_MINIKUBE="Do you want to delete Minikube cluster? (y/N): "
if /i "%DELETE_MINIKUBE%"=="y" (
    echo [INFO] Deleting Minikube cluster...
    minikube delete
    echo [SUCCESS] Minikube cluster deleted
)

echo.
echo [SUCCESS] Cleanup complete!
