@echo off
echo ================================================================================
echo                    RELEASE SCRIPT - DEBUG TEST
echo ================================================================================
echo.
echo Testing basic functionality...
echo.

REM Test 1: Check current directory
echo [Test 1] Current directory:
cd
echo.

REM Test 2: Check if app/version.py exists
echo [Test 2] Checking for app\version.py...
if exist "app\version.py" (
    echo   [OK] File found!
) else (
    echo   [ERROR] File NOT found!
    echo   Make sure you're in the project root directory.
)
echo.

REM Test 3: Read version
echo [Test 3] Reading version from app\version.py...
set VERSION=
for /f "tokens=2 delims==" %%a in ('findstr "__version__" app\version.py 2^>nul') do (
    set VERLINE=%%a
)
set VERSION=%VERLINE:"=%
set VERSION=%VERSION: =%
if not "%VERSION%"=="" (
    echo   [OK] Version: %VERSION%
) else (
    echo   [ERROR] Could not read version!
)
echo.

REM Test 4: Check for build.bat
echo [Test 4] Checking for build.bat...
if exist "build.bat" (
    echo   [OK] build.bat found!
) else (
    echo   [ERROR] build.bat NOT found!
)
echo.

REM Test 5: Check for GitHub CLI
echo [Test 5] Checking for GitHub CLI (gh)...
where gh >nul 2>&1
if errorlevel 1 (
    echo   [WARNING] GitHub CLI NOT installed!
    echo   Install from: https://cli.github.com/
) else (
    echo   [OK] GitHub CLI found!
    
    REM Check authentication
    echo.
    echo [Test 6] Checking GitHub authentication...
    gh auth status >nul 2>&1
    if errorlevel 1 (
        echo   [WARNING] Not authenticated!
        echo   Run: gh auth login
    ) else (
        echo   [OK] Authenticated!
    )
)
echo.

REM Test 6: Check for releases folder
echo [Test 7] Checking releases folder...
if exist "releases" (
    echo   [OK] releases\ folder exists
) else (
    echo   [WARNING] releases\ folder not found
    echo   Will be created during build
)
echo.

echo ================================================================================
echo                              TEST COMPLETE
echo ================================================================================
echo.
echo If all tests show [OK], the release script should work!
echo.
echo To run the actual release: release.bat
echo.
pause


