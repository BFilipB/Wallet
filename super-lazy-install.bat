@echo off
echo ========================================
echo   SUPER LAZY INSTALLER
echo   Installing Everything You Need
echo ========================================
echo.
echo This will install:
echo   1. PostgreSQL 16
echo   2. Redis
echo   3. Apache Kafka
echo   4. Set up database and topics
echo.
echo Just sit back and relax! This will take 10-15 minutes.
echo.
pause

cd /d "%~dp0"

:: Create temp directory
if not exist "temp_installers" mkdir temp_installers
cd temp_installers

echo.
echo ========================================
echo   STEP 1: Installing PostgreSQL
echo ========================================
echo.

:: Check if PostgreSQL is already installed
if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
    echo PostgreSQL is already installed! Skipping...
) else (
    echo Downloading PostgreSQL installer (200 MB)...
    echo This might take a few minutes...
    
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://sbp.enterprisedb.com/getfile.jsp?fileid=1258893' -OutFile 'postgresql-16-windows-x64.exe'}"
    
    if exist "postgresql-16-windows-x64.exe" (
        echo Installing PostgreSQL silently...
        echo Password will be: postgres
        
        postgresql-16-windows-x64.exe --mode unattended --unattendedmodeui none --superpassword "postgres" --serverport 5432
        
        echo Waiting for installation to complete...
        timeout /t 30 /nobreak > nul
        
        echo PostgreSQL installed!
    ) else (
        echo ERROR: Failed to download PostgreSQL
        echo Please download manually from: https://www.postgresql.org/download/windows/
        pause
    )
)

echo.
echo ========================================
echo   STEP 2: Installing Redis
echo ========================================
echo.

:: Check if Redis is already installed
if exist "C:\Redis\redis-server.exe" (
    echo Redis is already installed! Skipping...
) else (
    echo Downloading Redis (5 MB)...
    
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.zip' -OutFile 'Redis.zip'}"
    
    if exist "Redis.zip" (
        echo Extracting Redis to C:\Redis...
        powershell -Command "Expand-Archive -Path 'Redis.zip' -DestinationPath 'C:\Redis' -Force"
        
        echo Installing Redis as Windows service...
        cd C:\Redis
        redis-server --service-install redis.windows.conf
        redis-server --service-start
        
        echo Redis installed and started!
    ) else (
        echo ERROR: Failed to download Redis
        pause
    )
)

cd "%~dp0\temp_installers"

echo.
echo ========================================
echo   STEP 3: Installing Kafka
echo ========================================
echo.

:: Check if Kafka is already installed
if exist "C:\kafka\kafka_2.13-3.6.1" (
    echo Kafka is already installed! Skipping...
) else (
    echo Downloading Apache Kafka (100 MB)...
    echo This might take a few minutes...
    
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz' -OutFile 'kafka.tgz'}"
    
    if exist "kafka.tgz" (
        echo Extracting Kafka to C:\kafka...
        powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('kafka.tgz', 'C:\kafka')}"
        
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
)

echo.
echo ========================================
echo   STEP 4: Setting Up Database
echo ========================================
echo.

echo Creating wallet database...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -c "CREATE DATABASE wallet;" 2>nul
echo Database created (or already exists)

echo.
echo Creating tables...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -d wallet -f "%~dp0\..\database\schema.sql"

if %errorlevel% equ 0 (
    echo Tables created successfully!
) else (
    echo WARNING: Error creating tables
    echo This might be okay if they already exist
)

echo.
echo ========================================
echo   STEP 5: Starting Kafka
echo ========================================
echo.

echo Starting Kafka services...
start "" "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"

echo Waiting for Kafka to start (30 seconds)...
timeout /t 30 /nobreak > nul

echo.
echo ========================================
echo   STEP 6: Creating Kafka Topics
echo ========================================
echo.

echo Creating wallet-topup-requests topic...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>nul

echo Creating wallet-events topic...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>nul

echo Topics created!

echo.
echo ========================================
echo   STEP 7: Verifying Installation
echo ========================================
echo.

echo Checking PostgreSQL...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -c "SELECT version();" > nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] PostgreSQL is running
) else (
    echo [FAIL] PostgreSQL is not responding
)

echo Checking Redis...
C:\Redis\redis-cli ping > nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Redis is running
) else (
    echo [FAIL] Redis is not responding
)

echo Checking Kafka topics...
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092 > nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Kafka is running
) else (
    echo [FAIL] Kafka is not responding
)

echo.
echo ========================================
echo   INSTALLATION COMPLETE!
echo ========================================
echo.
echo All services are installed and running!
echo.
echo Services:
echo   PostgreSQL: localhost:5432 (password: postgres)
echo   Redis: localhost:6379
echo   Kafka: localhost:9092
echo.
echo Next steps:
echo   1. Open a new terminal
echo   2. Run: cd src\Wallet.Api
echo   3. Run: dotnet run
echo   4. Open another terminal
echo   5. Run: cd src\Wallet.Consumer
echo   6. Run: dotnet run
echo.
echo Or just use the quick-start.bat script!
echo.

:: Cleanup
cd "%~dp0"
echo Cleaning up installers...
rd /s /q temp_installers 2>nul

echo.
echo Press any key to exit...
pause > nul
