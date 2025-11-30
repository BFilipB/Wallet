@echo off
echo ========================================
echo   SUPER LAZY TESTING
echo   Automated API Tests
echo ========================================
echo.

:: Wait for API to be ready
echo Waiting for API to be ready...
timeout /t 5 /nobreak > nul

echo.
echo ========================================
echo   Running Tests
echo ========================================
echo.

echo [1/5] Testing Health Check...
curl -s http://localhost:5238/health
echo.
echo.

echo [2/5] Testing Top-Up (New Transaction)...
curl -X POST http://localhost:5238/wallet/topup -H "Content-Type: application/json" -d "{\"playerId\":\"test-player\",\"amount\":100.00,\"externalRef\":\"test-%RANDOM%\"}"
echo.
echo.

echo [3/5] Testing Idempotency (Same ExternalRef)...
curl -X POST http://localhost:5238/wallet/topup -H "Content-Type: application/json" -d "{\"playerId\":\"test-player\",\"amount\":100.00,\"externalRef\":\"idempotent-test\"}"
echo.
echo Should return same result twice:
curl -X POST http://localhost:5238/wallet/topup -H "Content-Type: application/json" -d "{\"playerId\":\"test-player\",\"amount\":100.00,\"externalRef\":\"idempotent-test\"}"
echo.
echo.

echo [4/5] Testing Balance Query...
curl -s http://localhost:5238/wallet/test-player/balance
echo.
echo.

echo [5/5] Testing Transaction History...
curl -s http://localhost:5238/wallet/test-player/history
echo.
echo.

echo ========================================
echo   Tests Complete!
echo ========================================
echo.
echo Check the output above for results.
echo All tests should return 200 OK.
echo.
echo Next: Check the Wallet Consumer window
echo You should see "Message processed successfully"
echo.
pause
