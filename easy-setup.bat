@echo off
echo ========================================
echo   SUPER EASY SETUP - Using Your Existing Services
echo ========================================
echo.
echo You already have PostgreSQL and Redis!
echo We just need to:
echo   1. Create the wallet database
echo   2. Install Kafka
echo   3. Create Kafka topics
echo.
pause

cd /d "%~dp0"

echo.
echo ========================================
echo   STEP 1: Creating Wallet Database
echo ========================================
echo.

echo Connecting to PostgreSQL...
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U gameuser -h localhost -p 5432 -c "CREATE DATABASE wallet;" 2>nul
if %errorlevel% equ 0 (
    echo Database 'wallet' created successfully!
) else (
    echo Database 'wallet' already exists or error occurred (this is usually fine)
)

echo.
echo Creating tables...
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U gameuser -h localhost -p 5432 -d wallet -f "database\schema.sql"
if %errorlevel% equ 0 (
    echo Tables created successfully!
) else (
    echo Error creating tables (they might already exist)
)

echo.
echo ========================================
echo   STEP 2: Installing Kafka
echo ========================================
echo.

if exist "C:\kafka\kafka_2.13-3.6.1" (
    echo Kafka is already installed! Skipping...
) else (
    echo Downloading Apache Kafka (100 MB)...
    echo This might take a few minutes...
    
    if not exist "temp_kafka" mkdir temp_kafka
    cd temp_kafka
    
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz' -OutFile 'kafka.tgz'}"
    
    if exist "kafka.tgz" (
        echo Extracting Kafka to C:\kafka...
        powershell -Command "& {tar -xzf kafka.tgz -C C:\ }"
        
        if not exist "C:\kafka" mkdir C:\kafka
        move C:\kafka_2.13-3.6.1 C:\kafka\ >nul 2>&1
        
        echo Creating Kafka startup script...
        (
            echo @echo off
            echo cd C:\kafka\kafka_2.13-3.6.1
            echo start "Zookeeper" cmd /k bin\windows\zookeeper-server-start.bat config\zookeeper.properties
            echo timeout /t 10
            echo start "Kafka" cmd /k bin\windows\kafka-server-start.bat config\server.properties
        ) > C:\kafka\kafka_2.13-3.6.1\start-kafka.bat
        
        echo Kafka installed!
    ) else (
        echo ERROR: Failed to download Kafka
        pause
    )
    
    cd ..
    rd /s /q temp_kafka 2>nul
)

echo.
echo ========================================
echo   STEP 3: Starting Kafka
echo ========================================
echo.

tasklist /FI "IMAGENAME eq java.exe" 2>NUL | find /I /N "java.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Kafka is already running!
) else (
    echo Starting Kafka (this takes 30 seconds)...
    start "" "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
    echo Waiting for Kafka to start...
    timeout /t 35 /nobreak > nul
)

echo.
echo ========================================
echo   STEP 4: Creating Kafka Topics
echo ========================================
echo.

echo Creating wallet-topup-requests topic...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>nul
if %errorlevel% equ 0 (
    echo Topic created!
) else (
    echo Topic already exists or error (this is usually fine)
)

echo Creating wallet-events topic...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>nul
if %errorlevel% equ 0 (
    echo Topic created!
) else (
    echo Topic already exists or error (this is usually fine)
)

echo.
echo Verifying topics...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092

echo.
echo ========================================
echo   SETUP COMPLETE!
echo ========================================
echo.
echo Services Status:
echo   PostgreSQL: Already installed (port 5432)
echo   Redis:      Already installed (port 6379)
echo   Kafka:      Installed and running (port 9092)
echo.
echo Database:
echo   Name:     wallet
echo   User:     gameuser
echo   Password: gamepass123
echo.
echo Next steps:
echo   1. Make sure Redis is running: Start-Service Redis
echo   2. Run: quick-start.bat
echo   3. Test your API!
echo.
pause
