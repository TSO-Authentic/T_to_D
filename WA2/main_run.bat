@echo off
setlocal enabledelayedexpansion

start "" /wait cmd /c "cd /d %~dp01 & run.bat"
if %errorlevel% neq 0 (
    echo run.bat failed with errorlevel %errorlevel%.
    goto :eof
)
timeout /t 3 /nobreak >nul 

start "" /wait cmd /c "cd /d %~dp02 & run.bat"
if %errorlevel% neq 0 (
    echo run.bat failed with errorlevel %errorlevel%.
    goto :eof
)
timeout /t 3 /nobreak >nul 

if exist "%~dp0\exit_code.txt" del "%~dp0\exit_code.txt"

start "" /wait cmd /c "%~dp03\Automation_Auth.lnk" 
timeout /t 10 /nobreak > nul

start "" /wait cmd /c "cd /d %~dp03\bat & run_query.bat"
timeout /t 10 /nobreak > nul

start "" /wait cmd /c "%~dp03\Automation.lnk" 
timeout /t 40 /nobreak > nul

if exist "%~dp0\exit_code.txt" (
    set /p EXIT_CODE=<"%~dp0\exit_code.txt"
) 
timeout /t 2 /nobreak > nul

if !EXIT_CODE! NEQ 0 (

    set "fullMessage="

    if exist "%~dp0\3\temp_error_message.txt" (
        for /f "usebackq delims=" %%a in ("%~dp0\3\temp_error_message.txt") do (
            set "fullMessage=!fullMessage!%%a<br>"
        )
        cscript //nologo "%~dp0utils\sendMail.vbs" "!fullMessage!"
    )
    if exist "%~dp03\temp_error_message.txt" del "%~dp03\temp_error_message.txt"
    if exist "%~dp0\exit_code.txt" del "%~dp0\exit_code.txt"
    goto :eof 
)
timeout /t 4 /nobreak > nul

start "" /wait cmd /c "%~dp04\Automation.lnk" 
timeout /t 20 /nobreak > nul

if exist "%~dp0\exit_code.txt" (
    set /p EXIT_CODE=<"%~dp0\exit_code.txt"
)
timeout /t 2 /nobreak > nul

if !EXIT_CODE! NEQ 0 (

    set "fullMessage="

    if exist "%~dp0\4\temp_error_message.txt" (
        for /f "usebackq delims=" %%a in ("%~dp0\4\temp_error_message.txt") do (
            set "fullMessage=!fullMessage!%%a<br>"
        )
        cscript //nologo "%~dp0utils\sendMail.vbs" "!fullMessage!"
    )
    if exist "%~dp0\4\temp_error_message.txt" del "%~dp0\4\temp_error_message.txt"
    if exist "%~dp0\exit_code.txt" del "%~dp0\exit_code.txt"
    goto :eof
) else (
    if exist "%~dp0\4\temp_error_message.txt" del "%~dp0\4\temp_error_message.txt"
    if exist "%~dp0\exit_code.txt" del "%~dp0\exit_code.txt"

    timeout /t 4 /nobreak >nul
    start "" /wait cmd /c "cd /d %~dp05 & run.bat"
)