@echo off
echo ========================================
echo   SUPER LAZY STOP
echo   Stopping Everything
echo ========================================
echo.

echo Stopping .NET applications...
taskkill /FI "WINDOWTITLE eq Wallet API*" /F > nul 2>&1
taskkill /FI "WINDOWTITLE eq Wallet Consumer*" /F > nul 2>&1
echo   Stopped

echo.
echo Stopping Kafka and Zookeeper...
taskkill /IM java.exe /F > nul 2>&1
echo   Stopped

echo.
echo NOTE: PostgreSQL and Redis are Windows services
echo They will keep running in the background (this is good!)
echo.
echo If you want to stop them too:
echo   Redis: taskkill /IM redis-server.exe /F
echo   PostgreSQL: net stop postgresql-x64-16
echo.
echo Press any key to exit...
pause > nul
