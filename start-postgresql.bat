@echo off
color 0C
title PostgreSQL Starter

echo ========================================
echo   STARTING POSTGRESQL
echo ========================================
echo.

REM Check if PostgreSQL service exists
sc query | findstr /C:"postgresql" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PostgreSQL service not found!
    echo.
    echo Possible service names:
    sc query | findstr /C:"postgres"
    echo.
    echo If you see a service above, note its name.
    echo Then edit this script and replace "postgresql-x64-14" with the correct name.
    echo.
    pause
    exit /b 1
)

echo Attempting to start PostgreSQL...
echo.

REM Try common PostgreSQL service names
net start postgresql-x64-16 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] PostgreSQL 16 started!
    goto :verify
)

net start postgresql-x64-15 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] PostgreSQL 15 started!
    goto :verify
)

net start postgresql-x64-14 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] PostgreSQL 14 started!
    goto :verify
)

net start postgresql 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] PostgreSQL started!
    goto :verify
)

echo [ERROR] Could not start PostgreSQL with common service names.
echo.
echo Please check your PostgreSQL installation:
echo 1. Open Services (Win+R, type "services.msc")
echo 2. Find PostgreSQL service
echo 3. Right-click and Start
echo.
pause
exit /b 1

:verify
echo.
echo Verifying PostgreSQL is running...
timeout /t 2 /nobreak >nul

REM Test connection
psql -U postgres -c "SELECT version();" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] PostgreSQL is running and accepting connections!
) else (
    echo [WARNING] PostgreSQL started but cannot connect yet. Wait a few seconds.
)

echo.
echo ========================================
echo   POSTGRESQL READY
echo ========================================
echo.
echo Next steps:
echo 1. Setup database: run setup-database.bat
echo 2. Start API: cd src\Wallet.Api ^&^& dotnet run
echo.
pause
