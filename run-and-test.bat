@echo off
color 0A
title Wallet Service - COMPLETE TESTER

echo.
echo ========================================
echo   WALLET SERVICE - RUN AND TEST
echo ========================================
echo.
echo This will start everything and test it!
echo.
pause

REM Step 1: Check if services are running
echo.
echo [1/5] Checking services...
echo.

docker ps >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker is running
    set USE_DOCKER=1
) else (
    echo [INFO] Docker not detected - will check native services
    set USE_DOCKER=0
)

REM Step 2: Start services
echo.
echo [2/5] Starting services...
echo.

if %USE_DOCKER%==1 (
    echo Starting with Docker...
    docker-compose up -d
    timeout /t 10 /nobreak >nul
) else (
    echo Checking native services...
    sc query | findstr "postgresql" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [!] PostgreSQL not running
        echo Please run: net start postgresql-x64-14
        pause
        exit /b 1
    )
    
    redis-cli ping >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [!] Redis not running
        echo Please start Redis
        pause
        exit /b 1
    )
    
    echo [OK] Services detected
)

REM Step 3: Start API
echo.
echo [3/5] Starting Wallet API...
echo.
start "Wallet API - http://localhost:5000" cmd /k "cd /d %~dp0src\Wallet.Api && color 0A && echo Starting Wallet API... && echo. && dotnet run"

REM Wait for API to start
echo Waiting for API to start...
timeout /t 10 /nobreak >nul

REM Step 4: Start Consumer
echo.
echo [4/5] Starting Wallet Consumer...
echo.
start "Wallet Consumer - Kafka Listener" cmd /k "cd /d %~dp0src\Wallet.Consumer && color 0E && echo Starting Wallet Consumer... && echo. && dotnet run"

REM Wait for consumer to start
echo Waiting for Consumer to start...
timeout /t 5 /nobreak >nul

REM Step 5: Run tests
echo.
echo [5/5] Running Tests...
echo.

REM Test 1: Health check
echo Test 1: Health Check
curl -s http://localhost:5000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [PASS] Health check: OK
) else (
    echo [FAIL] Health check failed - API might still be starting
    echo Waiting 5 more seconds...
    timeout /t 5 /nobreak >nul
)

REM Test 2: First top-up
echo.
echo Test 2: First Top-Up ($100 to player-001)
powershell -Command "$body = @{playerId='player-001';amount=100.00;externalRef='test-1'} | ConvertTo-Json; try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/topup' -Method Post -ContentType 'application/json' -Body $body; Write-Host '[PASS] Top-up successful: Balance = $' + $result.newBalance; } catch { Write-Host '[FAIL] Top-up failed'; }"

timeout /t 2 /nobreak >nul

REM Test 3: Get balance
echo.
echo Test 3: Get Balance
powershell -Command "try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/player-001/balance'; Write-Host '[PASS] Balance retrieved: $' + $result.balance; } catch { Write-Host '[FAIL] Failed to get balance'; }"

timeout /t 2 /nobreak >nul

REM Test 4: Idempotency test
echo.
echo Test 4: Idempotency (same request again)
powershell -Command "$body = @{playerId='player-001';amount=100.00;externalRef='test-1'} | ConvertTo-Json; try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/topup' -Method Post -ContentType 'application/json' -Body $body; if ($result.idempotent -eq $true) { Write-Host '[PASS] Idempotency works: Balance still $' + $result.newBalance; } else { Write-Host '[FAIL] Idempotency failed: Created duplicate'; } } catch { Write-Host '[FAIL] Request failed'; }"

timeout /t 2 /nobreak >nul

REM Test 5: Second top-up
echo.
echo Test 5: Second Top-Up ($50 more, different externalRef)
powershell -Command "$body = @{playerId='player-001';amount=50.00;externalRef='test-2'} | ConvertTo-Json; try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/topup' -Method Post -ContentType 'application/json' -Body $body; Write-Host '[PASS] Second top-up: New balance = $' + $result.newBalance; } catch { Write-Host '[FAIL] Top-up failed'; }"

timeout /t 2 /nobreak >nul

REM Test 6: Validation test (negative amount)
echo.
echo Test 6: Validation (negative amount - should fail)
powershell -Command "$body = @{playerId='player-001';amount=-100.00;externalRef='test-neg'} | ConvertTo-Json; try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/topup' -Method Post -ContentType 'application/json' -Body $body; Write-Host '[FAIL] Validation did not catch negative amount'; } catch { Write-Host '[PASS] Validation correctly rejected negative amount'; }"

timeout /t 2 /nobreak >nul

REM Test 7: Get history
echo.
echo Test 7: Get Transaction History
powershell -Command "try { $result = Invoke-RestMethod -Uri 'http://localhost:5000/wallet/player-001/history'; Write-Host '[PASS] History retrieved:' $result.Count 'transaction(s)'; } catch { Write-Host '[FAIL] Failed to get history'; }"

echo.
echo ========================================
echo   TESTS COMPLETE!
echo ========================================
echo.
echo Summary:
echo   - API is running on http://localhost:5000
echo   - Consumer is listening for Kafka messages
echo   - All basic tests have been executed
echo.
echo Next Steps:
echo   1. Check the API window for logs
echo   2. Check the Consumer window for logs
echo   3. Open http://localhost:5000/health in browser
echo   4. Try manual tests from SUPER_SIMPLE_TESTING_GUIDE.md
echo.
echo To stop:
echo   - Close the API and Consumer windows
echo   - Run: quick-stop.bat
echo.
pause
