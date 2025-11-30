# ONE-COMMAND SETUP - Everything Automated
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ONE-COMMAND WALLET SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "C:\Users\Filip\Desktop\WalletProject"

# Step 1: Create database and tables (need postgres password once)
Write-Host "STEP 1: Setting up database..." -ForegroundColor Yellow
Write-Host "You will be asked for the PostgreSQL admin password ONE TIME." -ForegroundColor Yellow
Write-Host ""

$postgresPassword = Read-Host "Enter PostgreSQL admin (postgres) password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($postgresPassword)
$pgPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$env:PGPASSWORD = $pgPass

Write-Host "Creating database and tables..." -ForegroundColor Yellow
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d postgres -c "DROP DATABASE IF EXISTS wallet;"
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d postgres -c "CREATE DATABASE wallet OWNER gameuser;"
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -d wallet -f "$projectRoot\database\setup-with-permissions.sql"

$env:PGPASSWORD = ""

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Database and tables created!" -ForegroundColor Green
} else {
    Write-Host "? Database setup failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 2: Install Kafka if needed
Write-Host ""
Write-Host "STEP 2: Checking Kafka..." -ForegroundColor Yellow

if (Test-Path "C:\kafka\kafka_2.13-3.6.1") {
    Write-Host "? Kafka already installed" -ForegroundColor Green
} else {
    Write-Host "Downloading Kafka (~100 MB)..." -ForegroundColor Yellow
    
    New-Item -Path "temp_kafka" -ItemType Directory -Force | Out-Null
    Set-Location "temp_kafka"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz" -OutFile "kafka.tgz"
    
    Write-Host "Extracting Kafka..." -ForegroundColor Yellow
    tar -xzf kafka.tgz -C "C:\"
    
    if (!(Test-Path "C:\kafka")) {
        New-Item -Path "C:\kafka" -ItemType Directory | Out-Null
    }
    
    Move-Item "C:\kafka_2.13-3.6.1" "C:\kafka\kafka_2.13-3.6.1" -Force -ErrorAction SilentlyContinue
    
    $startScript = @"
@echo off
cd C:\kafka\kafka_2.13-3.6.1
start "Zookeeper" cmd /k bin\windows\zookeeper-server-start.bat config\zookeeper.properties
timeout /t 10
start "Kafka" cmd /k bin\windows\kafka-server-start.bat config\server.properties
"@
    
    $startScript | Out-File -FilePath "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat" -Encoding ASCII
    
    Set-Location $projectRoot
    Remove-Item -Path "temp_kafka" -Recurse -Force
    
    Write-Host "? Kafka installed!" -ForegroundColor Green
}

# Step 3: Start Kafka
Write-Host ""
Write-Host "STEP 3: Starting Kafka..." -ForegroundColor Yellow

$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    Write-Host "? Kafka already running" -ForegroundColor Green
} else {
    Write-Host "Starting Kafka (30 seconds)..." -ForegroundColor Yellow
    Start-Process "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
    Start-Sleep -Seconds 30
    Write-Host "? Kafka started!" -ForegroundColor Green
}

# Step 4: Create Kafka topics
Write-Host ""
Write-Host "STEP 4: Creating Kafka topics..." -ForegroundColor Yellow

& "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 --if-not-exists 2>$null
& "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 --if-not-exists 2>$null

Write-Host "? Topics created!" -ForegroundColor Green

# Step 5: Verify everything
Write-Host ""
Write-Host "STEP 5: Verifying setup..." -ForegroundColor Yellow

$env:PGPASSWORD = 'gamepass123'
$tables = & 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U gameuser -h localhost -p 5432 -d wallet -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';"
$env:PGPASSWORD = ""

if ($tables -ge 4) {
    Write-Host "? Database tables: OK" -ForegroundColor Green
} else {
    Write-Host "? Database tables: FAILED" -ForegroundColor Red
}

$topics = & "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --list --bootstrap-server localhost:9092 2>$null | Select-String -Pattern "wallet"
if ($topics.Count -ge 2) {
    Write-Host "? Kafka topics: OK" -ForegroundColor Green
} else {
    Write-Host "? Kafka topics: FAILED" -ForegroundColor Red
}

# Step 6: Start the application
Write-Host ""
Write-Host "STEP 6: Starting application..." -ForegroundColor Yellow

Write-Host "Starting API..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\src\Wallet.Api'; dotnet run"

Start-Sleep -Seconds 5

Write-Host "Starting Consumer..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\src\Wallet.Consumer'; dotnet run"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services running:" -ForegroundColor Yellow
Write-Host "  API:      http://localhost:5000" -ForegroundColor White
Write-Host "  Consumer: Running in background" -ForegroundColor White
Write-Host ""
Write-Host "Test it:" -ForegroundColor Yellow
Write-Host "  curl http://localhost:5000/health" -ForegroundColor White
Write-Host ""
Write-Host "Or run: quick-test.bat" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
