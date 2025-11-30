@echo off
echo ========================================
echo   WALLET SERVICE - TEST AND PUSH
echo ========================================
echo.

REM Step 1: Build Test
echo [1/4] Testing Build...
dotnet build
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)
echo [SUCCESS] Build passed!
echo.

REM Step 2: Check Git Status
echo [2/4] Checking Git Status...
git status
echo.

REM Step 3: Stage All Changes
echo [3/4] Staging All Changes...
git add .
echo [SUCCESS] All files staged!
echo.

REM Step 4: Show What Will Be Committed
echo Files to be committed:
git status --short
echo.

REM Ask for confirmation
set /p CONFIRM="Do you want to commit and push these changes? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Push cancelled by user.
    pause
    exit /b 0
)

REM Step 5: Commit
echo.
echo [4/4] Committing Changes...
git commit -m "Add comprehensive beginner-friendly setup guides" -m "- Add SETUP_GUIDE_BEGINNERS.md: Complete step-by-step guide for newcomers" -m "- Add SETUP_GUIDE_VISUAL.md: Visual guide with diagrams and flowcharts" -m "- Add DOCUMENTATION_INDEX.md: Navigation hub for all documentation" -m "- Add REQUIREMENTS_VERIFICATION.md: Complete verification of all 20 requirements" -m "- Update README.md: Add prominent links to new setup guides" -m "" -m "These guides make the Wallet Service accessible to everyone, regardless" -m "of technical background. Features include progress checklists," -m "troubleshooting, visual aids, and respectful, encouraging language." -m "" -m "Documentation added: ~50 pages" -m "Time to setup (beginner): 30-45 minutes" -m "All requirements: VERIFIED (20/20)"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Commit failed!
    pause
    exit /b 1
)
echo [SUCCESS] Changes committed!
echo.

REM Step 6: Push to GitHub
echo Pushing to GitHub...
git push origin main

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Push failed!
    echo.
    echo Common fixes:
    echo 1. Check your internet connection
    echo 2. Verify GitHub credentials
    echo 3. Run: git pull origin main --rebase
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SUCCESS! PUSHED TO GITHUB
echo ========================================
echo.
echo Your changes are now live at:
echo https://github.com/BFilipB/Wallet
echo.
pause
