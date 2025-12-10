@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

echo ======================================================================
echo   FULL VALIDATION OF PRACTICAL WORK 4 (Criteria for 2 points)
echo ======================================================================
echo.
echo Working directory: %cd%
echo.

set BASE_URL=http://localhost:8090
set CLEANUP_ON_EXIT=true
if defined CLEANUP_ON_EXIT_ENV set CLEANUP_ON_EXIT=%CLEANUP_ON_EXIT_ENV%

echo Parameters:
echo   CLEANUP_ON_EXIT=%CLEANUP_ON_EXIT%
echo.

set PASSED_TESTS=0
set TOTAL_TESTS=0

echo ============================================================
echo   1. CHECKING DOCKER-COMPOSE FILE
echo ============================================================

docker-compose config --quiet 2>nul
if errorlevel 1 (
    call :print_fail "docker-compose.yml contains errors"
    goto :end
) else (
    call :print_pass "docker-compose.yml is valid"
)

for /f %%a in ('docker-compose config --services 2^>nul ^| find /c /v ""') do set SERVICE_COUNT=%%a
if %SERVICE_COUNT% geq 11 (
    call :print_pass "Number of services: %SERVICE_COUNT% (required >=11)"
) else (
    call :print_fail "Not enough services: %SERVICE_COUNT% (required >=11)"
)

for %%s in (postgres spring-app prometheus grafana graylog zabbix-server zabbix-web adminer) do (
    docker-compose config --services 2>nul | findstr /x "%%s" >nul
    if errorlevel 1 (
        call :print_fail "Service '%%s' missing"
    ) else (
        call :print_pass "Service '%%s' present"
    )
)

echo.
echo ============================================================
echo   2. CHECKING DATA MODELS AND RELATIONSHIPS
echo ============================================================

for %%e in (User Product Order) do (
    if exist "src\main\java\com\mirea\app\entity\%%e.java" (
        call :print_pass "Model %%e found"
    ) else (
        call :print_fail "Model %%e not found"
    )
)

findstr /c:"@OneToMany" src\main\java\com\mirea\app\entity\User.java >nul 2>&1
if errorlevel 1 (
    call :print_fail "1:N relationship not found"
) else (
    call :print_pass "1:N relationship implemented (User -> Orders)"
)

findstr /c:"@ManyToMany" src\main\java\com\mirea\app\entity\Order.java >nul 2>&1
if errorlevel 1 (
    call :print_fail "N:N relationship not found"
) else (
    call :print_pass "N:N relationship implemented (Order <-> Products)"
)

echo.
echo ============================================================
echo   3. CHECKING CRUD ENDPOINTS
echo ============================================================

for %%c in (UserController ProductController OrderController) do (
    if exist "src\main\java\com\mirea\app\controller\%%c.java" (
        call :print_pass "Controller %%c found"
    ) else (
        call :print_fail "Controller %%c not found"
    )
)

echo.
echo ============================================================
echo   4. CHECKING LOG EXPORT ENDPOINT
echo ============================================================

if exist "src\main\java\com\mirea\app\controller\LogController.java" (
    call :print_pass "LogController found"

    findstr /c:"@GetMapping" src\main\java\com\mirea\app\controller\LogController.java | findstr /c:"export" >nul 2>&1
    if errorlevel 1 (
        call :print_fail "Log export endpoint not found"
    ) else (
        call :print_pass "Log export endpoint implemented"
    )

    findstr /c:"CSV" src\main\java\com\mirea\app\controller\LogController.java >nul 2>&1
    if errorlevel 1 (
        call :print_fail "CSV export not found"
    ) else (
        call :print_pass "CSV export implemented"
    )
) else (
    call :print_fail "LogController not found"
)

echo.
echo ============================================================
echo   5. CHECKING GRAYLOG INTEGRATION
echo ============================================================

findstr /c:"logback-gelf" build.gradle.kts >nul 2>&1
if errorlevel 1 (
    call :print_fail "GELF dependency missing"
) else (
    call :print_pass "GELF dependency added"
)

if exist "src\main\resources\logback-spring.xml" (
    call :print_pass "Logback configuration found"

    findstr /c:"GelfUdpAppender" src\main\resources\logback-spring.xml >nul 2>&1
    if errorlevel 1 (
        call :print_fail "GELF appender not configured"
    ) else (
        call :print_pass "GELF appender configured"
    )
) else (
    call :print_fail "logback-spring.xml missing"
)

echo.
echo ============================================================
echo   6. CHECKING PROMETHEUS + GRAFANA SETUP
echo ============================================================

if exist "monitoring\prometheus\prometheus.yml" (
    call :print_pass "Prometheus configuration found"

    findstr /c:"spring-boot" monitoring\prometheus\prometheus.yml >nul 2>&1
    if errorlevel 1 (
        call :print_fail "Prometheus not configured for Spring Boot"
    ) else (
        call :print_pass "Prometheus configured to collect Spring Boot metrics"
    )
) else (
    call :print_fail "Prometheus configuration missing"
)

if exist "monitoring\grafana\provisioning\datasources\prometheus.yml" (
    call :print_pass "Grafana datasource for Prometheus configured"
) else (
    call :print_fail "Grafana datasource not configured"
)

if exist "monitoring\grafana\provisioning\dashboards\spring-boot-dashboard.json" (
    call :print_pass "Grafana dashboard created"
) else (
    call :print_warn "Pre-made Grafana dashboard missing"
)

echo.
echo ============================================================
echo   7. CHECKING ZABBIX
echo ============================================================

docker-compose config 2>nul | findstr /c:"zabbix-server" >nul
if errorlevel 1 (
    call :print_fail "Zabbix Server missing"
) else (
    call :print_pass "Zabbix Server configured"
)

docker-compose config 2>nul | findstr /c:"zabbix-web" >nul
if errorlevel 1 (
    call :print_fail "Zabbix Web missing"
) else (
    call :print_pass "Zabbix Web configured"
)

docker-compose config 2>nul | findstr /c:"zabbix-postgres" >nul
if errorlevel 1 (
    call :print_fail "Separate DB for Zabbix missing"
) else (
    call :print_pass "Separate DB for Zabbix configured"
)

echo.
echo ============================================================
echo   8. STARTING AND TESTING THE SYSTEM
echo ============================================================

echo Checking Docker daemon availability...
docker info >nul 2>&1
if errorlevel 1 (
    call :print_fail "Docker daemon not running"
    echo.
    echo Please start Docker Desktop and run this script again.
    echo.
    goto :static_results
)
call :print_pass "Docker daemon is running and available"

echo Stopping existing containers...
docker-compose down -v 2>nul

echo Building and starting services...
docker-compose up -d --build
if errorlevel 1 (
    call :print_fail "Error starting containers"
    goto :cleanup
)
call :print_pass "Containers started successfully"

echo.
echo Waiting for services to be ready (up to 2 minutes each)...

call :wait_for_service "http://localhost:8090/actuator/health" "Spring Boot"
call :wait_for_service "http://localhost:9090/-/healthy" "Prometheus"
call :wait_for_service "http://localhost:3000/api/health" "Grafana"
call :wait_for_service "http://localhost:8080" "Adminer"

timeout /t 10 /nobreak >nul

echo.
echo ============================================================
echo   9. TESTING CRUD OPERATIONS
echo ============================================================

echo Checking API availability...
curl -s -m 5 "%BASE_URL%/actuator/health" | findstr /c:"UP" >nul
if errorlevel 1 (
    call :print_warn "Spring Boot API may not be ready"
    timeout /t 5 /nobreak >nul
) else (
    call :print_pass "Spring Boot API ready for testing"
)

echo Creating user...
curl -s -m 10 -X POST "%BASE_URL%/api/users" -H "Content-Type: application/json" -d "{\"username\":\"test_user_validation\",\"email\":\"test@validation.com\",\"firstName\":\"Test\",\"lastName\":\"User\"}" > temp_user_response.txt
type temp_user_response.txt | findstr /c:"id" >nul
if errorlevel 1 (
    call :print_fail "Creating user (POST /api/users)"
) else (
    call :print_pass "Creating user (POST /api/users)"
)

echo Getting all users...
curl -s -m 10 "%BASE_URL%/api/users" | findstr /c:"test_user_validation" >nul
if errorlevel 1 (
    call :print_fail "Reading users (GET /api/users)"
) else (
    call :print_pass "Reading users (GET /api/users)"
)

echo Creating product...
curl -s -m 10 -X POST "%BASE_URL%/api/products" -H "Content-Type: application/json" -d "{\"name\":\"Test Product\",\"description\":\"Validation test\",\"price\":99.99,\"stock\":10}" > temp_product_response.txt
type temp_product_response.txt | findstr /c:"id" >nul
if errorlevel 1 (
    call :print_fail "Creating product (POST /api/products)"
) else (
    call :print_pass "Creating product (POST /api/products)"
)

echo.
echo ============================================================
echo   10. CHECKING LOG EXPORT TO CSV
echo ============================================================

echo Exporting logs...
curl -s -m 10 "%BASE_URL%/api/logs/mock-export" > temp_logs.csv
type temp_logs.csv | findstr /c:"Timestamp" >nul
if errorlevel 1 (
    call :print_fail "Log export endpoint not working"
) else (
    call :print_pass "Log export endpoint working"
    echo   First lines of CSV:
    for /f "tokens=1-3 delims=," %%a in ('type temp_logs.csv') do (
        echo     %%a,%%b,%%c
        goto :done_csv_preview
    )
    :done_csv_preview
)

echo.
echo ============================================================
echo   11. CHECKING PROMETHEUS METRICS
echo ============================================================

echo Checking Spring Boot metrics...
curl -s -m 10 "%BASE_URL%/actuator/prometheus" > temp_metrics.txt
type temp_metrics.txt | findstr /c:"jvm_memory" >nul
if errorlevel 1 (
    call :print_fail "JVM metrics unavailable"
) else (
    call :print_pass "JVM metrics available"
)

type temp_metrics.txt | findstr /c:"http_server_requests" >nul
if errorlevel 1 (
    call :print_fail "HTTP metrics unavailable"
) else (
    call :print_pass "HTTP metrics available"
)

echo.
echo ============================================================
echo   12. CHECKING MONITORING SYSTEMS
echo ============================================================

echo Checking web interfaces availability...
call :check_web_service "http://localhost:3000" "Grafana"
call :check_web_service "http://localhost:8081" "Zabbix Web"
call :check_web_service "http://localhost:9000" "GrayLog Web"

echo.
echo ============================================================
echo   13. CHECKING SEPARATE DATABASES FOR MONITORING
echo ============================================================

docker-compose config 2>nul | findstr /c:"POSTGRES_DB: zabbix" >nul
if errorlevel 1 (
    call :print_fail "Zabbix may use main database"
) else (
    call :print_pass "Zabbix uses separate database (not main)"
)

docker-compose config 2>nul | findstr /c:"mongodb" >nul
if errorlevel 1 (
    call :print_fail "GrayLog may use main database"
) else (
    call :print_pass "GrayLog uses MongoDB (not application PostgreSQL)"
)

echo.
echo ============================================================
echo   14. CHECKING DOCUMENTATION
echo ============================================================

if exist "README.md" (
    call :print_pass "README.md exists"

    findstr /c:"docker-compose up" README.md >nul 2>&1
    if errorlevel 1 (
        call :print_fail "README does not contain startup instructions"
    ) else (
        call :print_pass "README contains startup instructions"
    )
) else (
    call :print_fail "README.md missing"
)

goto :final_results

:static_results
echo.
echo ============================================================
echo   15. FINAL RESULTS (STATIC CHECKS ONLY)
echo ============================================================
echo.
echo ============================================================
set /a SUCCESS_RATE=PASSED_TESTS*100/TOTAL_TESTS
echo   Tests passed: %PASSED_TESTS% of %TOTAL_TESTS%
echo   Success rate (static checks): %SUCCESS_RATE%%%
echo ============================================================
echo.
echo [WARN] Docker not running. Start Docker for full testing.
echo.
goto :end

:final_results
echo.
echo ============================================================
echo   15. FINAL RESULTS
echo ============================================================
echo.
echo ============================================================
set /a SUCCESS_RATE=PASSED_TESTS*100/TOTAL_TESTS
echo   Tests passed: %PASSED_TESTS% of %TOTAL_TESTS%
echo   Success rate: %SUCCESS_RATE%%%
echo ============================================================
echo.

if %SUCCESS_RATE% geq 90 (
    echo [SUCCESS] EXCELLENT! Project ready for submission for 2 points!
) else if %SUCCESS_RATE% geq 75 (
    echo [WARN] GOOD! Minor issues, but main requirements met.
) else (
    echo [FAIL] NEEDS WORK! Not all criteria met.
)

echo.
echo Service access:
echo   - Spring Boot API:  http://localhost:8090
echo   - Adminer:          http://localhost:8080
echo   - Prometheus:       http://localhost:9090
echo   - Grafana:          http://localhost:3000 (admin/admin)
echo   - GrayLog:          http://localhost:9000 (admin/admin)
echo   - Zabbix:           http://localhost:8081 (Admin/zabbix)
echo.
echo To stop: docker-compose down -v
echo.

:cleanup
if exist temp_user_response.txt del temp_user_response.txt
if exist temp_product_response.txt del temp_product_response.txt
if exist temp_logs.csv del temp_logs.csv
if exist temp_metrics.txt del temp_metrics.txt

if "%CLEANUP_ON_EXIT%"=="true" (
    echo.
    echo Cleaning up resources...
    docker-compose down -v 2>nul
    echo [OK] Cleanup completed
)

:end
exit /b 0

:print_pass
set /a TOTAL_TESTS+=1
set /a PASSED_TESTS+=1
echo [OK] %~1
exit /b 0

:print_fail
set /a TOTAL_TESTS+=1
echo [FAIL] %~1
exit /b 0

:print_warn
set /a TOTAL_TESTS+=1
echo [WARN] %~1
exit /b 0

:wait_for_service
set url=%~1
set name=%~2
echo Waiting for %name%...
set attempts=0
:wait_loop_service
set /a attempts+=1
if %attempts% gtr 12 (
    echo   %name% not ready after 2 minutes
    exit /b 1
)
curl -s -m 10 "%url%" >nul 2>&1
if errorlevel 1 (
    echo   Waiting for %name%... (%attempts%0 seconds)
    timeout /t 10 /nobreak >nul
    goto :wait_loop_service
)
echo   %name% responded
exit /b 0

:check_web_service
set url=%~1
set name=%~2
curl -s -m 10 "%url%" >nul 2>&1
if errorlevel 1 (
    call :print_warn "%name% may be unavailable"
) else (
    call :print_pass "%name% available (%url%)"
)
exit /b 0
