@echo off
REM cycle_keys.bat - Windows Batch Launcher for cycle_keys.py
REM This allows Windows users to run the script without typing "python"

setlocal EnableDelayedExpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "PYTHON_SCRIPT=%SCRIPT_DIR%cycle_keys.py"

REM Check if Python is available
python --version >nul 2>&1
if !errorlevel! == 0 (
    set "PYTHON_CMD=python"
) else (
    python3 --version >nul 2>&1
    if !errorlevel! == 0 (
        set "PYTHON_CMD=python3"
    ) else (
        echo Error: Python is not installed or not in PATH
        echo Please install Python from https://www.python.org/
        pause
        exit /b 1
    )
)

REM Check if the Python script exists
if not exist "%PYTHON_SCRIPT%" (
    echo Error: cycle_keys.py not found in %SCRIPT_DIR%
    echo Please run the PowerShell installer first: install.ps1
    pause
    exit /b 1
)

REM Run the Python script with all passed arguments
!PYTHON_CMD! "%PYTHON_SCRIPT%" %*

REM If script was run without arguments, pause to show output
if "%~1"=="" (
    pause
)
