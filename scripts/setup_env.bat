@echo off
REM One-click Python environment setup for Windows
echo [KIRI-Skill] Checking Python environment...

where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python is already installed:
    python --version
    exit /b 0
)

where py >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python Launcher (py) is installed:
    py --version
    exit /b 0
)

echo [INFO] Python not found. Attempting automatic installation via winget...
where winget >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Installing Python 3.12 via winget...
    winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    if %errorlevel% equ 0 (
        echo [SUCCESS] Python successfully installed! Please restart your terminal/agent.
        exit /b 0
    )
)

echo.
echo [NOTICE] Automatic install could not be completed.
echo Tip: On Windows, you can run the skill without Python using native PowerShell:
echo   powershell -ExecutionPolicy Bypass -File scripts\validate_media.ps1 "<path>"
echo Or download Python from: https://www.python.org/downloads/
exit /b 1
