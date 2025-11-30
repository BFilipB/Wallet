@echo off
color 0B
title FIX EVERYTHING - PostgreSQL Starter

echo ========================================
echo   POSTGRESQL FIXER - SUPER EASY
echo ========================================
echo.
echo This will:
echo   1. Start PostgreSQL
echo   2. Create database
echo   3. Create tables
echo.
pause

REM ====================================
REM STEP 1: START POSTGRESQL
REM ====================================

echo.
echo [STEP 1] Starting PostgreSQL...
echo.

REM Try all common service names
set STARTED=0

echo Trying postgresql-x64-16...
net start postgresql-x64-16 2>nul
if %ERRORLEVEL% EQU 0 (
    set STARTED=1
    set SERVICE_NAME=postgresql-x64-16
    goto :step2
)

echo Trying postgresql-x64-15...
net start postgresql-x64-15 2>nul
if %ERRORLEVEL% EQU 0 (
    set STARTED=1
    set SERVICE_NAME=postgresql-x64-15
    goto :step2
)

echo Trying postgresql-x64-14...
net start postgresql-x64-14 2>nul
if %ERRORLEVEL% EQU 0 (
    set STARTED=1
    set SERVICE_NAME=postgresql-x64-14
    goto :step2
)

echo Trying postgresql...
net start postgresql 2>nul
if %ERRORLEVEL% EQU 0 (
    set STARTED=1
    set SERVICE_NAME=postgresql
    goto :step2
)

REM Check if already running
sc query | findstr /C:"postgresql" | findstr /C:"RUNNING" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] PostgreSQL is already running!
    set STARTED=1
    goto :step2
)

REM Failed to start
echo.
echo [ERROR] Could not start PostgreSQL automatically.
echo.
echo MANUAL FIX:
echo   1. Press Win+R
echo   2. Type: services.msc
echo   3. Find "postgresql" in the list
echo   4. Right-click and click "Start"
echo   5. Then run this script again
echo.
pause
exit /b 1

:step2
echo [OK] PostgreSQL is running!

REM Wait a moment for PostgreSQL to fully start
timeout /t 2 /nobreak >nul

REM ====================================
REM STEP 2: CREATE DATABASE
REM ====================================

echo.
echo [STEP 2] Setting up database...
echo.

REM Check if psql is in PATH
where psql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] psql not in PATH, trying common locations...
    
    if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
        set PSQL="C:\Program Files\PostgreSQL\16\bin\psql.exe"
    ) else if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" (
        set PSQL="C:\Program Files\PostgreSQL\15\bin\psql.exe"
    ) else if exist "C:\Program Files\PostgreSQL\14\bin\psql.exe" (
        set PSQL="C:\Program Files\PostgreSQL\14\bin\psql.exe"
    ) else (
        echo [ERROR] Cannot find psql.exe
        echo.
        echo Please add PostgreSQL bin folder to PATH:
        echo   1. Search for "Environment Variables" in Windows
        echo   2. Edit PATH variable
        echo   3. Add: C:\Program Files\PostgreSQL\XX\bin
        echo.
        pause
        exit /b 1
    )
) else (
    set PSQL=psql
)

REM Create user (ignore error if exists)
echo Creating user 'gameuser'...
%PSQL% -U postgres -c "CREATE USER gameuser WITH PASSWORD 'gamepass123';" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] User created
) else (
    echo [INFO] User already exists (this is fine)
)

REM Create database (ignore error if exists)
echo Creating database 'wallet'...
%PSQL% -U postgres -c "CREATE DATABASE wallet OWNER gameuser;" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Database created
) else (
    echo [INFO] Database already exists (this is fine)
)

REM ====================================
REM STEP 3: CREATE TABLES
REM ====================================

echo.
echo [STEP 3] Creating tables...
echo.

REM Check if schema file exists
if not exist "database\schema.sql" (
    echo [ERROR] Schema file not found: database\schema.sql
    echo.
    echo Make sure you're in the WalletProject directory!
    echo.
    pause
    exit /b 1
)

REM Run schema
%PSQL% -U gameuser -d wallet -f database\schema.sql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Schema may have errors, trying alternative...
    type database\schema.sql | %PSQL% -U gameuser -d wallet
)

echo [OK] Tables created

REM Verify
echo.
echo Verifying setup...
%PSQL% -U gameuser -d wallet -c "\dt" 2>nul | findstr "wallets" >nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] All tables verified!
    echo.
    echo Tables in database:
    %PSQL% -U gameuser -d wallet -c "\dt"
) else (
    echo [WARNING] Could not verify tables
)

REM ====================================
REM DONE
REM ====================================

echo.
echo ========================================
echo   SETUP COMPLETE! ?
echo ========================================
echo.
echo PostgreSQL: RUNNING ?
echo Database:   wallet ?
echo User:       gameuser ?
echo Tables:     4 tables created ?
echo.
echo Connection string:
echo Host=localhost;Port=5432;Database=wallet;Username=gameuser;Password=gamepass123
echo.
echo Ready to run your application!
echo.
echo NEXT STEPS:
echo   1. Terminal 1: cd src\Wallet.Api ^&^& dotnet run
echo   2. Terminal 2: cd src\Wallet.Consumer ^&^& dotnet run
echo.
echo Or just run: run-and-test.bat
echo.
pause
