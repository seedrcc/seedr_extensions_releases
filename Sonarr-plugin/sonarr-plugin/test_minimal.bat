@echo off
echo Starting minimal test...
echo.

echo Current directory:
cd
echo.

echo Checking for app\version.py...
if exist "app\version.py" (
    echo FOUND!
) else (
    echo NOT FOUND!
)
echo.

echo This window should stay open...
echo.
pause


