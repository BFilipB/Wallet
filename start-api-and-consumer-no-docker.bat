@echo off
color 0B
echo ========================================
echo   WALLET SERVICE - NO DOCKER STARTUP
echo ========================================
echo.

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

echo Starting Wallet API and Consumer...
echo.

REM Check if services are running first
echo Checking required services...
call "%SCRIPT_DIR%\check-no-docker-services.bat"

echo.
echo Starting Wallet Service components...
echo.

REM Start API in new window
echo [1/2] Starting Wallet API...
start "Wallet API - http://localhost:5000" cmd /k "cd /d %SCRIPT_DIR%\src\Wallet.Api && color 0A && echo Wallet API Starting... && echo. && dotnet run"

REM Wait 5 seconds for API to initialize
echo Waiting for API to start...
timeout /t 5 /nobreak >nul

REM Start Consumer in new window
echo [2/2] Starting Wallet Consumer...
start "Wallet Consumer - Kafka Listener" cmd /k "cd /d %SCRIPT_DIR%\src\Wallet.Consumer && color 0E && echo Wallet Consumer Starting... && echo. && dotnet run"

echo.
echo ========================================
echo   SERVICES STARTED
echo ========================================
echo.
echo Two windows have opened:
echo   1. Wallet API (GREEN) - http://localhost:5000
echo   2. Wallet Consumer (YELLOW) - Kafka listener
echo.
echo Test the API:
echo   curl http://localhost:5000/health
echo.
echo Or open in browser:
echo   http://localhost:5000/health
echo.
echo To stop: Close both command windows or press Ctrl+C
echo.

REM Wait a bit more then test health
timeout /t 3 /nobreak >nul

echo Testing API health...
curl -s http://localhost:5000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] API is responding!
) else (
    echo [WAIT] API is still starting up...
    echo       Try: http://localhost:5000/health in a few seconds
)

echo.
pause
