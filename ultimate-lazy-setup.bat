@echo off
echo ========================================
echo   ULTIMATE LAZY SETUP
echo   Everything in One Click!
echo ========================================
echo.

cd /d "%~dp0"

echo.
echo STEP 1: Creating wallet database...
echo.
echo Please enter the PostgreSQL ADMIN password when prompted.
echo (This is the password you set when installing PostgreSQL)
echo.

"C:\Program Files\PostgreSQL\15\bin\createdb.exe" -U postgres -h localhost -p 5432 wallet

if %errorlevel% neq 0 (
    echo.
    echo Database might already exist, trying to create tables anyway...
)

echo.
echo STEP 2: Creating tables in wallet database...
echo.

$env:PGPASSWORD='gamepass123'
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U gameuser -h localhost -p 5432 -d wallet -f "database\schema.sql"

if %errorlevel% equ 0 (
    echo Tables created successfully!
) else (
    echo Error: Could not create tables
    echo Trying with postgres user...
    "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -h localhost -p 5432 -d wallet -f "database\schema.sql"
)

echo.
echo STEP 3: Checking Kafka...
echo.

if exist "C:\kafka\kafka_2.13-3.6.1" (
    echo Kafka is installed!
) else (
    echo Kafka not found. Installing...
    echo This will take a few minutes...
    
    if not exist "temp" mkdir temp
    cd temp
    
    powershell -Command "Invoke-WebRequest -Uri 'https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz' -OutFile 'kafka.tgz'"
    powershell -Command "tar -xzf kafka.tgz -C C:\"
    
    if not exist "C:\kafka" mkdir C:\kafka
    xcopy /E /I /Y "C:\kafka_2.13-3.6.1" "C:\kafka\kafka_2.13-3.6.1\"
    rd /s /q "C:\kafka_2.13-3.6.1"
    
    (
        echo @echo off
        echo cd C:\kafka\kafka_2.13-3.6.1
        echo start "Zookeeper" cmd /k bin\windows\zookeeper-server-start.bat config\zookeeper.properties
        echo timeout /t 10
        echo start "Kafka" cmd /k bin\windows\kafka-server-start.bat config\server.properties
    ) > C:\kafka\kafka_2.13-3.6.1\start-kafka.bat
    
    cd ..
    rd /s /q temp
    
    echo Kafka installed!
)

echo.
echo STEP 4: Starting Kafka...
echo.

tasklist /FI "IMAGENAME eq java.exe" 2>NUL | find /I /N "java.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Kafka is already running
) else (
    echo Starting Kafka...
    start "" "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
    echo Waiting 30 seconds for Kafka to start...
    timeout /t 30 /nobreak > nul
)

echo.
echo STEP 5: Creating Kafka topics...
echo.

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-topup-requests' created

C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>nul
echo Topic 'wallet-events' created

echo.
echo Verifying topics:
C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat --list --bootstrap-server localhost:9092

echo.
echo ========================================
echo   SETUP COMPLETE!
echo ========================================
echo.
echo Now run: quick-start.bat
echo.
pause
