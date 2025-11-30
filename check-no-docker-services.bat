@echo off
color 0A
echo ========================================
echo   NO-DOCKER STARTUP HELPER
echo ========================================
echo.

REM Check if PostgreSQL is running
echo [1/4] Checking PostgreSQL...
sc query | findstr /C:"postgresql" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] PostgreSQL is running
) else (
    echo [!] PostgreSQL not detected
    echo     Install: https://www.postgresql.org/download/
    echo     Or: choco install postgresql
)
echo.

REM Check if Redis is running
echo [2/4] Checking Redis...
redis-cli ping >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Redis is running
) else (
    echo [!] Redis not detected or not running
    echo     Install: https://github.com/microsoftarchive/redis/releases
    echo     Or: choco install redis-64
    echo     Start: redis-server
)
echo.

REM Check if Kafka is running
echo [3/4] Checking Kafka...
netstat -ano | findstr :9092 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Kafka is running on port 9092
) else (
    echo [!] Kafka not detected
    echo     Download: https://kafka.apache.org/downloads
    echo     Start Zookeeper: bin\windows\zookeeper-server-start.bat config\zookeeper.properties
    echo     Start Kafka: bin\windows\kafka-server-start.bat config\server.properties
)
echo.

REM Check if .NET 9 is installed
echo [4/4] Checking .NET 9 SDK...
dotnet --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%i in ('dotnet --version') do set DOTNET_VERSION=%%i
    echo [OK] .NET version: !DOTNET_VERSION!
) else (
    echo [!] .NET 9 SDK not detected
    echo     Install: https://dotnet.microsoft.com/download/dotnet/9.0
)
echo.

echo ========================================
echo   NEXT STEPS
echo ========================================
echo.
echo If all services are running, you can start:
echo.
echo 1. API:
echo    cd src\Wallet.Api
echo    dotnet run
echo.
echo 2. Consumer:
echo    cd src\Wallet.Consumer
echo    dotnet run
echo.
echo Or run: start-api-and-consumer-no-docker.bat
echo.

pause
