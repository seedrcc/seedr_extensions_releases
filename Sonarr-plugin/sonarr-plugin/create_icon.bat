@echo off
echo ============================================
echo    SonarrSeedr Icon Creator
echo ============================================
echo.

REM Check if Pillow is installed
python -c "import PIL" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Pillow library not installed!
    echo.
    echo Installing Pillow...
    pip install Pillow
    echo.
)

REM Run the icon creator
python create_icon.py %1

echo.
echo ============================================
pause

