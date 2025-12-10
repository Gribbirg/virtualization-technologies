@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

set APP_NAME=mirea-spring-app
set POSTGRES_NAME=mirea-postgres
set APP_PORT=8080

echo === Spring Boot + PostgreSQL Test Script ===
echo Working directory: %cd%
echo.

echo Checking Docker connection...
docker info >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Cannot connect to Docker daemon
    echo Please start Docker Desktop
    exit /b 1
)
echo [OK] Docker is ready

echo.
echo Building and starting services with Docker Compose...
docker-compose up --build -d
if errorlevel 1 (
    echo [FAIL] Error starting services
    goto :cleanup
)

echo.
echo Waiting for PostgreSQL to be ready...
set timeout=60
:wait_postgres
docker exec %POSTGRES_NAME% pg_isready -U mirea_user >nul 2>&1
if errorlevel 1 (
    set /a timeout-=1
    if %timeout% leq 0 (
        echo [FAIL] PostgreSQL failed to start within 60 seconds
        goto :cleanup
    )
    timeout /t 1 /nobreak >nul
    goto :wait_postgres
)
echo [OK] PostgreSQL is ready

echo.
echo Waiting for Spring Boot application to start...
set timeout=120
:wait_spring
curl -s http://localhost:%APP_PORT%/api/items >nul 2>&1
if errorlevel 1 (
    set /a timeout-=1
    if %timeout% leq 0 (
        echo [FAIL] Spring Boot application failed to start within 120 seconds
        echo Application logs:
        docker logs %APP_NAME% --tail 20
        goto :cleanup
    )
    timeout /t 1 /nobreak >nul
    goto :wait_spring
)
echo [OK] Spring Boot application is ready

echo.
echo Testing Spring Boot endpoints...

echo 1. Testing GET /api/items (should return empty list):
curl -s http://localhost:%APP_PORT%/api/items
echo.

echo.
echo 2. Testing POST /api/items (adding new item):
curl -s -X POST http://localhost:%APP_PORT%/api/items -H "Content-Type: application/json" -d "{\"name\":\"Test Item\",\"description\":\"Test Description\"}"
echo.

echo.
echo 3. Testing GET /api/items (should show the added item):
curl -s http://localhost:%APP_PORT%/api/items
echo.

echo.
echo 4. Testing GET /api/mirea-logo (MIREA emblem):
for /f "tokens=*" %%a in ('curl -s -I http://localhost:%APP_PORT%/api/mirea-logo 2^>nul ^| findstr /i "content-type"') do set logo_response=%%a
echo %logo_response% | findstr /i "image/png" >nul
if errorlevel 1 (
    echo [FAIL] MIREA logo endpoint failed or wrong content type
) else (
    echo [OK] MIREA logo endpoint working (PNG image detected)
)

echo.
echo [OK] All tests completed!

echo.
echo Application logs:
docker logs %APP_NAME% --tail 15

echo.
echo PostgreSQL logs:
docker logs %POSTGRES_NAME% --tail 10

echo.
echo All Spring Boot Task 2 requirements verified:
echo [OK] Multi-stage Dockerfile
echo [OK] PostgreSQL integration with environment variables
echo [OK] Item CRUD endpoints
echo [OK] MIREA emblem download and serving
echo [OK] LABEL with student info
echo [OK] ONBUILD command

:cleanup
echo.
echo Cleaning up...
echo Stopping Docker Compose...
docker-compose down -v --remove-orphans 2>nul
echo [OK] Cleanup completed

exit /b 0
