@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

echo === Quick check of practical work 4 ===
echo.
echo Working directory: %cd%
echo.

set BASE_URL=http://localhost:8090

echo 1. Checking docker-compose syntax...
docker-compose config --quiet 2>nul
if errorlevel 1 (
    echo [FAIL] docker-compose.yml contains errors
) else (
    echo [OK] docker-compose.yml is valid
)

echo.
echo 2. Checking project build...
cd /d "%~dp0..\..\.."
call gradlew.bat :practical-work-4:build -x test --quiet 2>nul
if errorlevel 1 (
    echo [FAIL] Build error
) else (
    echo [OK] Project builds successfully
)

echo.
echo 3. Checking required files...
cd /d "%~dp0..\.."

if exist "src\main\resources\logback-spring.xml" (
    echo [OK] src\main\resources\logback-spring.xml exists
) else (
    echo [FAIL] src\main\resources\logback-spring.xml missing
)

if exist "monitoring\grafana\provisioning\dashboards\spring-boot-dashboard.json" (
    echo [OK] monitoring\grafana\provisioning\dashboards\spring-boot-dashboard.json exists
) else (
    echo [FAIL] monitoring\grafana\provisioning\dashboards\spring-boot-dashboard.json missing
)

if exist "docker-compose.yml" (
    echo [OK] docker-compose.yml exists
) else (
    echo [FAIL] docker-compose.yml missing
)

if exist "Dockerfile" (
    echo [OK] Dockerfile exists
) else (
    echo [FAIL] Dockerfile missing
)

if exist "README.md" (
    echo [OK] README.md exists
) else (
    echo [FAIL] README.md missing
)

echo.
echo 4. Counting services in docker-compose...
for /f %%a in ('docker-compose config --services 2^>nul ^| find /c /v ""') do set SERVICE_COUNT=%%a
echo Number of services: %SERVICE_COUNT%
if %SERVICE_COUNT% geq 11 (
    echo [OK] Enough services (required >=11)
) else (
    echo [WARN] Not enough services (found %SERVICE_COUNT%, required >=11)
)

echo.
echo 5. Checking GELF dependency...
findstr /c:"logback-gelf" build.gradle.kts >nul 2>&1
if errorlevel 1 (
    echo [FAIL] GELF dependency missing
) else (
    echo [OK] GELF dependency added
)

echo.
echo 6. Checking logging configuration...
if exist "src\main\resources\logback-spring.xml" (
    findstr /c:"GelfUdpAppender" src\main\resources\logback-spring.xml >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] GELF appender not configured
    ) else (
        echo [OK] GELF appender configured
    )
)

echo.
echo 7. Checking data models...
set entity_count=0
if exist "src\main\java\com\mirea\app\entity\User.java" set /a entity_count+=1
if exist "src\main\java\com\mirea\app\entity\Product.java" set /a entity_count+=1
if exist "src\main\java\com\mirea\app\entity\Order.java" set /a entity_count+=1

echo Found models: %entity_count%
if %entity_count% geq 3 (
    echo [OK] Enough data models (required >=3)
) else (
    echo [FAIL] Not enough data models
)

echo.
echo 8. Checking model relationships...
findstr /c:"OneToMany" src\main\java\com\mirea\app\entity\User.java >nul 2>&1
if errorlevel 1 (
    echo [FAIL] 1:N relationship not found
) else (
    echo [OK] 1:N relationship found (User -> Orders)
)

findstr /c:"ManyToMany" src\main\java\com\mirea\app\entity\Order.java >nul 2>&1
if errorlevel 1 (
    echo [FAIL] N:N relationship not found
) else (
    echo [OK] N:N relationship found (Order <-> Products)
)

echo.
echo 9. Checking controllers...
set controller_count=0
if exist "src\main\java\com\mirea\app\controller\UserController.java" set /a controller_count+=1
if exist "src\main\java\com\mirea\app\controller\ProductController.java" set /a controller_count+=1
if exist "src\main\java\com\mirea\app\controller\OrderController.java" set /a controller_count+=1
if exist "src\main\java\com\mirea\app\controller\LogController.java" set /a controller_count+=1

echo Found controllers: %controller_count%
if %controller_count% equ 4 (
    echo [OK] All controllers present
) else (
    echo [WARN] Controller count: %controller_count% (expected 4)
)

echo.
echo 10. Checking log export endpoint...
findstr /c:"/api/logs/export" src\main\java\com\mirea\app\controller\LogController.java >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Log export endpoint not found
) else (
    echo [OK] Log export endpoint implemented
)

echo.
echo === Check completed ===
echo.
echo For full testing with container startup use:
echo   scripts\bat\test-monitoring.bat
echo.

exit /b 0
