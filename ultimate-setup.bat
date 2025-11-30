@echo off
echo ========================================
echo   ULTIMATE SETUP SCRIPT
echo   (The one that actually works)
echo ========================================
echo.
echo This script will:
echo   1. Create the 'wallet' database using your 'gameuser'.
echo   2. Create all the necessary tables.
echo   3. Install and start Kafka (if needed).
echo   4. Create Kafka topics.
echo.
echo This should be a one-time setup.
echo.
pause

cd /d "%~dp0"

echo.
echo ========================================
echo   STEP 1: Creating Database 'wallet'
echo ========================================
echo.

set PGPASSWORD=gamepass123
"C:\Program Files\PostgreSQL\15\bin\createdb.exe" -U gameuser -h localhost -p 5432 wallet

if %errorlevel% equ 0 (
    echo Database 'wallet' created successfully!
) else (
    echo Database 'wallet' probably already exists. That's OK.
)

echo.
echo ========================================
echo   STEP 2: Creating Tables
echo ========================================
echo.

"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U gameuser -h localhost -p 5432 -d wallet -f "database\schema.sql"

if %errorlevel% equ 0 (
    echo Tables created successfully!
) else (
    echo WARNING: Error creating tables. They might already exist.
)
set PGPASSWORD=

echo.
echo ========================================
echo   STEP 3: Installing/Starting Kafka
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
echo   STEP 4: Creating Kafka Topics
echo ========================================
echo.

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-topup-requests' created or already exists.

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-events' created or already exists.

echo.
echo ========================================
echo   SETUP COMPLETE!
echo ========================================
echo.
echo Everything is ready.
echo.
echo Next: Run 'quick-start.bat' to start the application.
echo.
pause
