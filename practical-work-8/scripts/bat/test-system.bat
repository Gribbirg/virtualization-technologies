@echo off
setlocal enabledelayedexpansion

set NAMESPACE=task-management
set KRAKEND_URL=http://localhost:8080
set AUTH_URL=http://localhost:8081
set TASK_URL=http://localhost:8082
set NOTIFICATION_URL=http://localhost:8083

echo ==========================================
echo   System Integration Tests
echo ==========================================
echo.

echo [INFO] Checking if port forwarding is active...
curl -s %AUTH_URL%/actuator/health >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Services are not accessible. Please run scripts\bat\port-forward.bat first
    exit /b 1
)
echo [SUCCESS] Port forwarding is active
echo.

echo [INFO] Test 1: Health Checks
echo Testing Auth Service Health...
curl -s -w "\n%%{http_code}" %AUTH_URL%/actuator/health
echo.
echo Testing Task Service Health...
curl -s -w "\n%%{http_code}" %TASK_URL%/actuator/health
echo.
echo Testing Notification Service Health...
curl -s -w "\n%%{http_code}" %NOTIFICATION_URL%/actuator/health
echo.

echo [INFO] Test 2: User Registration (через KrakenD)
for /f %%i in ('powershell -command "[int](Get-Date -UFormat %%s)"') do set TIMESTAMP=%%i
set TEST_USER=testuser!TIMESTAMP!
set TEST_EMAIL=test!TIMESTAMP!@example.com
set TEST_PASSWORD=TestPassword123
set REGISTER_DATA={"username":"%TEST_USER%","email":"%TEST_EMAIL%","password":"%TEST_PASSWORD%"}

echo Registering user: %TEST_USER%
curl -s -X POST %KRAKEND_URL%/auth/register -H "Content-Type: application/json" -d "%REGISTER_DATA%"
echo.

echo [INFO] Test 3: User Login (через KrakenD)
set LOGIN_DATA={"username":"%TEST_USER%","password":"%TEST_PASSWORD%"}
for /f "tokens=*" %%a in ('curl -s -X POST %KRAKEND_URL%/auth/login -H "Content-Type: application/json" -d "%LOGIN_DATA%"') do set LOGIN_RESPONSE=%%a
echo %LOGIN_RESPONSE%
echo.

for /f "tokens=2 delims=:, " %%a in ('echo %LOGIN_RESPONSE% ^| findstr /C:"token"') do set TOKEN=%%~a
if "%TOKEN%"=="" (
    echo [ERROR] Failed to extract token from login response
    exit /b 1
)
echo [SUCCESS] Token extracted
echo.

echo [INFO] Test 4: Token Validation
curl -s -X GET %AUTH_URL%/api/auth/validate -H "Authorization: Bearer %TOKEN%"
echo.

echo [INFO] Test 5: Create Task (через KrakenD)
set TASK_DATA={"title":"Test Task","description":"This is a test task","status":"PENDING"}
curl -s -X POST %KRAKEND_URL%/tasks -H "Content-Type: application/json" -H "Authorization: Bearer %TOKEN%" -d "%TASK_DATA%"
echo.

echo [INFO] Test 6: Get Tasks (через KrakenD)
curl -s -X GET %KRAKEND_URL%/tasks -H "Authorization: Bearer %TOKEN%"
echo.

echo [INFO] Test 7: Get Notifications (через KrakenD)
timeout /t 2 /nobreak >nul
curl -s -X GET %KRAKEND_URL%/notifications -H "Authorization: Bearer %TOKEN%"
echo.

echo [INFO] Test 8: Get Task Statistics (прямое обращение)
curl -s -X GET %TASK_URL%/api/tasks/stats -H "Authorization: Bearer %TOKEN%"
echo.

echo [INFO] Test 9: Checking Kafka Topics
for /f "tokens=*" %%a in ('kubectl get pod -n %NAMESPACE% -l app=kafka -o jsonpath^={.items[0].metadata.name} 2^>nul') do set KAFKA_POD=%%a
if not "%KAFKA_POD%"=="" (
    echo Kafka topics:
    kubectl exec -n %NAMESPACE% %KAFKA_POD% -- kafka-topics --bootstrap-server localhost:9092 --list
) else (
    echo [ERROR] Kafka pod not found
)
echo.

echo [INFO] Test 10: Checking Database Connections
for %%d in (auth-postgres task-postgres notification-postgres) do (
    for /f "tokens=*" %%a in ('kubectl get pod -n %NAMESPACE% -l app.kubernetes.io/instance^=%%d -o jsonpath^={.items[0].metadata.name} 2^>nul') do (
        kubectl exec -n %NAMESPACE% %%a -- bash -c "PGPASSWORD=$(cat /opt/bitnami/postgresql/secrets/postgres-password) pg_isready -h 127.0.0.1 -p 5432 -U postgres" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] %%d is not ready
        ) else (
            echo [SUCCESS] %%d is ready
        )
    )
)
echo.

echo [INFO] Test 11: Checking Redis
for /f "tokens=*" %%a in ('kubectl get pod -n %NAMESPACE% -l app.kubernetes.io/name^=redis -o jsonpath^={.items[0].metadata.name} 2^>nul') do set REDIS_POD=%%a
if not "%REDIS_POD%"=="" (
    kubectl exec -n %NAMESPACE% %REDIS_POD% -- redis-cli -a redis_password ping >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Redis is not ready
    ) else (
        echo [SUCCESS] Redis is ready
    )
)
echo.

echo ==========================================
echo [SUCCESS] ALL TESTS COMPLETED
echo ==========================================
echo.
echo Monitoring URLs:
echo   - Grafana:    http://localhost:3000 (admin/admin)
echo   - Prometheus: http://localhost:9090
echo   - Jaeger:     http://localhost:16686
echo.
echo To view logs:
echo   kubectl logs -n %NAMESPACE% -l app=auth-service --tail=50
echo   kubectl logs -n %NAMESPACE% -l app=task-service --tail=50
echo   kubectl logs -n %NAMESPACE% -l app=notification-service --tail=50
echo.
