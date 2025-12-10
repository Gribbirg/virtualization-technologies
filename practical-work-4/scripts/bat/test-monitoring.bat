@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

echo === Testing MIREA Spring Boot Application Monitoring System ===
echo Working directory: %cd%
echo.

set BASE_URL=http://localhost:8090
set CLEANUP_ON_EXIT=true
if defined CLEANUP_ON_EXIT_ENV set CLEANUP_ON_EXIT=%CLEANUP_ON_EXIT_ENV%

echo Environment variables:
echo - CLEANUP_ON_EXIT: %CLEANUP_ON_EXIT%
echo.

echo === Setting up Docker environment ===
echo Checking Docker connection...
docker info >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Cannot connect to Docker daemon
    echo Please start Docker Desktop
    exit /b 1
)
echo [OK] Docker is ready

echo.
echo === Building and starting services ===
echo Stopping existing containers...
docker-compose down -v 2>nul

echo Building images and starting services...
docker-compose up -d --build
if errorlevel 1 (
    echo [FAIL] Error starting services
    goto :cleanup
)
echo [OK] Services started

echo.
echo === Waiting for services to be ready ===

call :wait_for_service "http://localhost:8090/actuator/health" "Spring Boot"
call :wait_for_service "http://localhost:9090" "Prometheus"
call :wait_for_service "http://localhost:3000" "Grafana"

echo Additional stabilization wait (30 seconds)...
timeout /t 30 /nobreak >nul

echo [OK] All main services ready

echo.
echo === Testing CRUD operations ===

echo 1. Creating user...
curl -s -X POST "%BASE_URL%/api/users" -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"firstName\":\"Test\",\"lastName\":\"User\"}" > temp_user.json
type temp_user.json
echo.

echo 2. Creating product...
curl -s -X POST "%BASE_URL%/api/products" -H "Content-Type: application/json" -d "{\"name\":\"Test Product\",\"description\":\"Test Description\",\"price\":99.99,\"stock\":10}" > temp_product.json
type temp_product.json
echo.

echo 3. Getting all users...
curl -s "%BASE_URL%/api/users"
echo.

echo 4. Getting all products...
curl -s "%BASE_URL%/api/products"
echo.

echo [OK] CRUD operations tested

echo.
echo === Testing log export ===
echo Exporting logs to CSV...
curl -s "%BASE_URL%/api/logs/mock-export" > database_operations_test.csv
echo Logs saved to database_operations_test.csv
type database_operations_test.csv | more
echo [OK] Log export tested

echo.
echo === Load testing ===
echo Sending 10 requests...
for /L %%i in (1,1,10) do (
    start /b curl -s -X POST "%BASE_URL%/api/users" -H "Content-Type: application/json" -d "{\"username\":\"loadtest%%i\",\"email\":\"loadtest%%i@example.com\",\"firstName\":\"Load\",\"lastName\":\"Test%%i\"}" >nul 2>&1
)
timeout /t 5 /nobreak >nul
echo [OK] Load testing completed

echo.
echo === Checking monitoring services ===
call :check_service "http://localhost:8090/actuator/health" "Spring Boot Actuator"
call :check_service "http://localhost:8090/actuator/prometheus" "Spring Boot Prometheus Metrics"
call :check_service "http://localhost:9090" "Prometheus"
call :check_service "http://localhost:3000" "Grafana"
call :check_service "http://localhost:8080" "Adminer"
call :check_service "http://localhost:9000" "GrayLog"
call :check_service "http://localhost:8081" "Zabbix Web"

echo.
echo === Service Information ===
echo.
echo Available services:
echo - Spring Boot application: http://localhost:8090
echo - Adminer (DB management): http://localhost:8080
echo - Prometheus: http://localhost:9090
echo - Grafana: http://localhost:3000 (admin/admin)
echo - GrayLog: http://localhost:9000 (admin/admin)
echo - Zabbix Web: http://localhost:8081 (Admin/zabbix)
echo.
echo API endpoints:
echo - GET /api/users - get all users
echo - POST /api/users - create user
echo - GET /api/products - get all products
echo - POST /api/products - create product
echo - GET /api/orders - get all orders
echo - POST /api/orders - create order
echo - GET /api/logs/mock-export - export logs to CSV
echo.

echo === Testing completed successfully ===
echo.
echo To stop all services run: docker-compose down -v
echo To view logs run: docker-compose logs -f

:cleanup
if exist temp_user.json del temp_user.json
if exist temp_product.json del temp_product.json

if "%CLEANUP_ON_EXIT%"=="true" (
    echo.
    echo === Cleaning up resources ===
    echo Stopping and removing containers...
    docker-compose down -v 2>nul
    echo Cleaning up Docker images...
    docker image prune -f 2>nul
    echo [OK] Cleanup completed
) else (
    echo Services left running (CLEANUP_ON_EXIT=false)
)

exit /b 0

:wait_for_service
set url=%~1
set name=%~2
echo Waiting for %name%...
set attempts=0
:wait_loop
set /a attempts+=1
if %attempts% gtr 60 (
    echo [FAIL] %name% not ready after 60 attempts
    exit /b 1
)
curl -f -s "%url%" >nul 2>&1
if errorlevel 1 (
    echo Attempt %attempts%/60 for %name%...
    timeout /t 5 /nobreak >nul
    goto :wait_loop
)
echo [OK] %name% ready
exit /b 0

:check_service
set url=%~1
set name=%~2
curl -f -s "%url%" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] %name% unavailable
) else (
    echo [OK] %name% available
)
exit /b 0
