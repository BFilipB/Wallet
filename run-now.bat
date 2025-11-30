@echo off
color 0A
title Running Wallet Service

echo ========================================
echo   STARTING WALLET SERVICE
echo ========================================
echo.

echo Checking services...
echo.

REM Check PostgreSQL
echo [1/4] PostgreSQL...
psql -U gameuser -d wallet -c "SELECT 1;" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   [OK] PostgreSQL is ready
) else (
    echo   [ERROR] PostgreSQL not accessible
    echo   Please check: postgresql-x64-15 service is running
    pause
    exit /b 1
)

REM Check Redis (optional - will try to use Docker)
echo [2/4] Redis...
redis-cli ping >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   [OK] Redis is ready
    set REDIS_OK=1
) else (
    echo   [WARN] Redis not running, trying Docker...
    docker ps >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo   Starting Redis with Docker...
        docker run -d -p 6379:6379 --name wallet-redis redis:alpine >nul 2>&1
        timeout /t 3 /nobreak >nul
        redis-cli ping >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo   [OK] Redis started with Docker
            set REDIS_OK=1
        ) else (
            echo   [ERROR] Could not start Redis
            echo   The application will run but caching won't work
            set REDIS_OK=0
        )
    ) else (
        echo   [ERROR] Redis and Docker not available
        echo   The application will run but caching won't work
        set REDIS_OK=0
    )
)

REM Check Kafka (optional - will try to use Docker)  
echo [3/4] Kafka...
netstat -an | findstr :9092 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   [OK] Kafka is ready
    set KAFKA_OK=1
) else (
    echo   [WARN] Kafka not running
    echo   Consumer won't work, but API will run
    set KAFKA_OK=0
)

REM Build the solution
echo [4/4] Building solution...
dotnet build --nologo --verbosity quiet >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   [OK] Build successful
) else (
    echo   [ERROR] Build failed
    dotnet build
    pause
    exit /b 1
)

echo.
echo ========================================
echo   STARTING COMPONENTS
echo ========================================
echo.

REM Start API
echo Starting Wallet API...
start "Wallet API - http://localhost:5000" cmd /k "cd /d %~dp0src\Wallet.Api && color 0A && echo Wallet API Starting... && echo. && dotnet run --no-build"

REM Wait for API to start
timeout /t 5 /nobreak >nul

REM Test API
echo.
echo Testing API...
curl -s http://localhost:5000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] API is responding at http://localhost:5000
) else (
    echo [WAIT] API still starting...
    timeout /t 5 /nobreak >nul
)

REM Start Consumer if Kafka is available
if %KAFKA_OK%==1 (
    echo.
    echo Starting Wallet Consumer...
    start "Wallet Consumer - Kafka" cmd /k "cd /d %~dp0src\Wallet.Consumer && color 0E && echo Wallet Consumer Starting... && echo. && dotnet run --no-build"
) else (
    echo.
    echo [SKIP] Not starting Consumer (Kafka not available)
)

echo.
echo ========================================
echo   READY TO TEST!
echo ========================================
echo.
echo API Running: http://localhost:5000
echo.
if %REDIS_OK%==1 (
    echo Redis:    [OK] Caching enabled
) else (
    echo Redis:    [SKIP] Running without cache
)
echo.
if %KAFKA_OK%==1 (
    echo Kafka:    [OK] Consumer running
) else (
    echo Kafka:    [SKIP] API only mode
)
echo.
echo TEST COMMANDS:
echo.
echo Health Check:
echo   curl http://localhost:5000/health
echo.
echo Or open in browser:
echo   http://localhost:5000/health
echo.
echo First Top-Up (PowerShell):
echo   $body = @{playerId='player-001';amount=100.00;externalRef='test-1'} ^| ConvertTo-Json
echo   Invoke-RestMethod -Uri 'http://localhost:5000/wallet/topup' -Method Post -ContentType 'application/json' -Body $body
echo.
echo To stop: Close the terminal windows
echo.
pause
