@echo off
echo ========================================
echo   SETUP AND RUN - Wallet Service
echo ========================================
echo.
echo This script will:
echo   1. Create database tables
echo   2. Install and start Kafka
echo   3. Start the API and Consumer
echo.
echo Make sure you have already created the 'wallet' database!
echo.
pause

cd /d "%~dp0"

echo.
echo ========================================
echo   STEP 1: Creating Database Tables
echo ========================================
echo.

set PGPASSWORD=gamepass123
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U gameuser -h localhost -p 5432 -d wallet -f "database\schema.sql"

if %errorlevel% equ 0 (
    echo Tables created successfully!
) else (
    echo WARNING: Error creating tables. They might already exist.
)
set PGPASSWORD=

echo.
echo ========================================
echo   STEP 2: Installing/Starting Kafka
echo ========================================
echo.

if exist "C:\kafka\kafka_2.13-3.6.1" (
    echo Kafka is already installed.
) else (
    echo Installing Kafka...
    if not exist "temp_install" mkdir temp_install
    cd temp_install
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz' -OutFile 'kafka.tgz'}"
    powershell -Command "tar -xzf kafka.tgz -C C:\"
    if not exist "C:\kafka" mkdir C:\kafka
    xcopy /E /I /Y "C:\kafka_2.13-3.6.1" "C:\kafka\kafka_2.13-3.6.1\" >nul
    rd /s /q "C:\kafka_2.13-3.6.1"
    (
        echo @echo off
        echo cd C:\kafka\kafka_2.13-3.6.1
        echo start "Zookeeper" cmd /k bin\windows\zookeeper-server-start.bat config\zookeeper.properties
        echo timeout /t 10
        echo start "Kafka" cmd /k bin\windows\kafka-server-start.bat config\server.properties
    ) > C:\kafka\kafka_2.13-3.6.1\start-kafka.bat
    cd ..
    rd /s /q temp_install
    echo Kafka installed!
)

tasklist /FI "IMAGENAME eq java.exe" 2>NUL | find /I /N "java.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Kafka is already running.
) else (
    echo Starting Kafka (30 seconds)...
    start "" "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
    timeout /t 35 /nobreak > nul
)

echo.
echo ========================================
echo   STEP 3: Creating Kafka Topics
echo ========================================
echo.

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-topup-requests' created or already exists.

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-events' created or already exists.

echo.
echo ========================================
echo   STEP 4: Starting Application
echo ========================================
echo.

echo Starting Wallet API...
start "Wallet API" cmd /k "cd /d %~dp0src\Wallet.Api && dotnet run"
timeout /t 5 /nobreak > nul

echo Starting Wallet Consumer...
start "Wallet Consumer" cmd /k "cd /d %~dp0src\Wallet.Consumer && dotnet run"

echo.
echo ========================================
echo   ALL SERVICES STARTED!
echo ========================================
echo.
echo API is running on http://localhost:5000
echo.
echo You can now run 'quick-test.bat' or test manually.
echo.
pause
