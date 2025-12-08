@echo off
setlocal enabledelayedexpansion

echo === Generating load for Grafana dashboards ===

for /f "tokens=2 delims=:, " %%a in ('curl -s -X POST http://localhost:8081/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"loaduser1\",\"password\":\"TestPass123\"}" ^| findstr /C:"token"') do set TOKEN=%%~a

echo Token obtained: %TOKEN:~0,30%...
echo.

echo === Registering users ===
for /l %%i in (1,1,20) do (
    curl -s -X POST http://localhost:8081/api/auth/register -H "Content-Type: application/json" -d "{\"username\":\"user%%i\",\"email\":\"user%%i@test.com\",\"password\":\"TestPass123\"}" >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Creating tasks ===
for /l %%i in (1,1,30) do (
    curl -s -X POST http://localhost:8082/api/tasks -H "Content-Type: application/json" -H "Authorization: Bearer %TOKEN%" -d "{\"title\":\"Task %%i\",\"description\":\"Description for task %%i\",\"status\":\"PENDING\"}" >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Fetching tasks ===
for /l %%i in (1,1,50) do (
    curl -s http://localhost:8082/api/tasks -H "Authorization: Bearer %TOKEN%" >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Fetching notifications ===
for /l %%i in (1,1,30) do (
    curl -s http://localhost:8083/api/notifications -H "Authorization: Bearer %TOKEN%" >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Checking health endpoints ===
for /l %%i in (1,1,20) do (
    curl -s http://localhost:8081/actuator/health >nul
    curl -s http://localhost:8082/actuator/health >nul
    curl -s http://localhost:8083/actuator/health >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Login attempts ===
for /l %%i in (1,1,20) do (
    curl -s -X POST http://localhost:8081/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"loaduser1\",\"password\":\"TestPass123\"}" >nul
    echo|set /p="."
)
echo  Done
echo.

echo === Load generation complete ===
echo Check Grafana at http://localhost:3000
