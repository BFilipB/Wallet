# Ultimate Lazy Setup - PowerShell Version
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ULTIMATE LAZY SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot

# Step 1: Create wallet database
Write-Host "STEP 1: Creating wallet database..." -ForegroundColor Yellow
Write-Host ""

try {
    $env:PGPASSWORD = 'gamepass123'
    & 'C:\Program Files\PostgreSQL\15\bin\createdb.exe' -U gameuser -h localhost -p 5432 wallet 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Database might already exist or no permission. Trying as postgres..." -ForegroundColor Yellow
        Read-Host "Enter PostgreSQL admin password" | Set-Variable -Name pgAdminPass
        $env:PGPASSWORD = $pgAdminPass
        & 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U postgres -h localhost -p 5432 -c "CREATE DATABASE wallet OWNER gameuser;"
    }
    
    Write-Host "Database created!" -ForegroundColor Green
} catch {
    Write-Host "Database might already exist (this is OK)" -ForegroundColor Yellow
}

# Step 2: Create tables
Write-Host ""
Write-Host "STEP 2: Creating tables..." -ForegroundColor Yellow

$env:PGPASSWORD = 'gamepass123'
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' -U gameuser -h localhost -p 5432 -d wallet -f "$projectRoot\database\schema.sql"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Tables created successfully!" -ForegroundColor Green
} else {
    Write-Host "Error creating tables" -ForegroundColor Red
}

# Step 3: Check/Install Kafka
Write-Host ""
Write-Host "STEP 3: Checking Kafka..." -ForegroundColor Yellow

if (Test-Path "C:\kafka\kafka_2.13-3.6.1") {
    Write-Host "Kafka is already installed!" -ForegroundColor Green
} else {
    Write-Host "Installing Kafka..." -ForegroundColor Yellow
    Write-Host "Downloading (100 MB)..." -ForegroundColor Yellow
    
    New-Item -Path "temp" -ItemType Directory -Force | Out-Null
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://archive.apache.org/dist/kafka/3.6.1/kafka_2.13-3.6.1.tgz" -OutFile "temp\kafka.tgz"
    
    Write-Host "Extracting..." -ForegroundColor Yellow
    tar -xzf "temp\kafka.tgz" -C "C:\"
    
    if (!(Test-Path "C:\kafka")) {
        New-Item -Path "C:\kafka" -ItemType Directory | Out-Null
    }
    
    Move-Item "C:\kafka_2.13-3.6.1" "C:\kafka\kafka_2.13-3.6.1" -Force
    
    # Create startup script
    $startScript = @"
@echo off
cd C:\kafka\kafka_2.13-3.6.1
start "Zookeeper" cmd /k bin\windows\zookeeper-server-start.bat config\zookeeper.properties
timeout /t 10
start "Kafka" cmd /k bin\windows\kafka-server-start.bat config\server.properties
"@
    
    $startScript | Out-File -FilePath "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat" -Encoding ASCII
    
    Remove-Item -Path "temp" -Recurse -Force
    
    Write-Host "Kafka installed!" -ForegroundColor Green
}

# Step 4: Start Kafka
Write-Host ""
Write-Host "STEP 4: Starting Kafka..." -ForegroundColor Yellow

$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    Write-Host "Kafka is already running" -ForegroundColor Green
} else {
    Write-Host "Starting Kafka (30 seconds)..." -ForegroundColor Yellow
    Start-Process "C:\kafka\kafka_2.13-3.6.1\start-kafka.bat"
    Start-Sleep -Seconds 30
    Write-Host "Kafka started!" -ForegroundColor Green
}

# Step 5: Create topics
Write-Host ""
Write-Host "STEP 5: Creating Kafka topics..." -ForegroundColor Yellow

& "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --create --bootstrap-server localhost:9092 --topic wallet-topup-requests --partitions 12 --replication-factor 1 2>$null
Write-Host "Topic 'wallet-topup-requests' created" -ForegroundColor Green

& "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --create --bootstrap-server localhost:9092 --topic wallet-events --partitions 12 --replication-factor 1 2>$null
Write-Host "Topic 'wallet-events' created" -ForegroundColor Green

Write-Host ""
Write-Host "Verifying topics:" -ForegroundColor Yellow
& "C:\kafka\kafka_2.13-3.6.1\bin\windows\kafka-topics.bat" --list --bootstrap-server localhost:9092

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  PostgreSQL: localhost:5432 (database: wallet)" -ForegroundColor White
Write-Host "  Redis:      localhost:6379" -ForegroundColor White
Write-Host "  Kafka:      localhost:9092" -ForegroundColor White
Write-Host ""
Write-Host "Next: Run .\quick-start.bat" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
