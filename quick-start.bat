@echo off
echo ========================================
echo   QUICK START - Wallet Service
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Checking PostgreSQL...
sc query "postgresql-x64-15" | find "RUNNING" > nul
if %errorlevel% equ 0 (
    echo      PostgreSQL is running.
) else (
    echo      Starting PostgreSQL...
    net start postgresql-x64-15 > nul 2>&1
    if %errorlevel% equ 0 (
        echo      PostgreSQL started.
    ) else (
        echo      ERROR: Could not start PostgreSQL.
    )
)

echo.
echo [2/4] Checking Redis...
sc query "Redis" | find "RUNNING" > nul
if %errorlevel% equ 0 (
    echo      Redis is running.
) else (
    echo      Starting Redis...
    net start Redis > nul 2>&1
    if %errorlevel% equ 0 (
        echo      Redis started.
    ) else (
        echo      ERROR: Could not start Redis.
    )
)

echo.
echo [3/4] Starting Kafka...
tasklist /FI "IMAGENAME eq java.exe" 2>NUL | find /I /N "java.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo      Kafka is already running.
) else (
    if exist "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat" (
        echo      Starting Kafka (30 seconds)...
        start "" "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
        timeout /t 35 /nobreak > nul
        echo      Kafka started.
    ) else (
        echo      ERROR: Kafka not installed! Run 'ultimate-setup.bat' first!
        pause
        exit /b 1
    )
)

echo.
echo [4/4] Starting Wallet Services...

echo.
echo Starting Wallet API...
start "Wallet API" cmd /k "cd /d %~dp0src\Wallet.Api && dotnet run"
timeout /t 5 /nobreak > nul

echo.
echo Starting Wallet Consumer...
start "Wallet Consumer" cmd /k "cd /d %~dp0src\Wallet.Consumer && dotnet run"

echo.
echo ========================================
echo   ALL SERVICES STARTED!
echo ========================================
echo.
echo Services:
echo   PostgreSQL: localhost:5432 (database: wallet)
echo   Redis:      localhost:6379
echo   Kafka:      localhost:9092
echo   API:        http://localhost:5000
echo   Consumer:   Running in background
echo.
echo Test your API:
echo   curl http://localhost:5000/health
echo.
echo Or run: quick-test.bat
echo.
pause
