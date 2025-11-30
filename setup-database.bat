@echo off
color 0A
title Setup Wallet Database

echo ========================================
echo   WALLET DATABASE SETUP
echo ========================================
echo.

REM Check if PostgreSQL is running
psql -U postgres -c "SELECT 1;" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PostgreSQL is not running!
    echo.
    echo Please start PostgreSQL first:
    echo   1. Run: start-postgresql.bat
    echo   2. Or manually: net start postgresql-x64-14
    echo.
    pause
    exit /b 1
)

echo [OK] PostgreSQL is running
echo.

REM Check if database exists
psql -U postgres -lqt | cut -d ^| -f 1 | findstr /C:"wallet" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Database 'wallet' already exists
    set /p RECREATE="Do you want to recreate it? (Y/N): "
    if /i "%RECREATE%"=="Y" (
        echo Dropping existing database...
        psql -U postgres -c "DROP DATABASE IF EXISTS wallet;" >nul 2>&1
        psql -U postgres -c "DROP USER IF EXISTS gameuser;" >nul 2>&1
        echo [OK] Old database removed
    ) else (
        echo [INFO] Using existing database
        goto :schema
    )
)

echo Creating database and user...
echo.

REM Create user
echo Creating user 'gameuser'...
psql -U postgres -c "CREATE USER gameuser WITH PASSWORD 'gamepass123';" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] User created
) else (
    echo [INFO] User may already exist
)

REM Create database
echo Creating database 'wallet'...
psql -U postgres -c "CREATE DATABASE wallet OWNER gameuser;" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to create database
    pause
    exit /b 1
)
echo [OK] Database created

:schema
echo.
echo Creating tables and indexes...
echo.

REM Run schema
psql -U gameuser -d wallet -f database\schema.sql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to create schema
    echo.
    echo Trying alternative method...
    type database\schema.sql | psql -U gameuser -d wallet
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Schema creation failed
        pause
        exit /b 1
    )
)

echo [OK] Schema created
echo.

REM Verify tables
echo Verifying tables...
psql -U gameuser -d wallet -c "\dt" 2>nul | findstr "wallets" >nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Tables verified
    echo.
    echo Tables created:
    psql -U gameuser -d wallet -c "\dt"
) else (
    echo [WARNING] Could not verify tables
)

echo.
echo ========================================
echo   DATABASE SETUP COMPLETE
echo ========================================
echo.
echo Database: wallet
echo User:     gameuser
echo Password: gamepass123
echo Host:     localhost
echo Port:     5432
echo.
echo Connection string:
echo Host=localhost;Port=5432;Database=wallet;Username=gameuser;Password=gamepass123
echo.
echo Next: Start the application
echo   1. API: cd src\Wallet.Api ^&^& dotnet run
echo   2. Consumer: cd src\Wallet.Consumer ^&^& dotnet run
echo.
pause
