@echo off

SET is_start_stop_service=F
if "%1"=="start" SET is_start_stop_service=T
if "%1"=="stop" SET is_start_stop_service=T
if "%is_start_stop_service%"=="T" (
    REM Goto the detect section.
    goto lxssDetect
) else (
    REM Goto the net_alter section.
    goto net_alter
)
 
:lxssRestart
    REM ReStart the LxssManager service
    net stop LxssManager

:lxssStart
    REM Start the LxssManager service
    net start LxssManager

:lxssDetect
    REM Detect the LxssManager service status
    for /f "skip=3 tokens=4" %%i in ('sc query LxssManager') do set "state=%%i" &goto lxssStatus

:lxssStatus
    REM If the LxssManager service is stopped, start it.
    if /i "%state%"=="STOPPED" (goto lxssStart)
    REM If the LxssManager service is starting, wait for it to finish start.
    if /i "%state%"=="STARTING" (goto lxssDetect)
    REM If the LxssManager service is running, start the linux service.
    if /i "%state%"=="RUNNING" (goto next)
    REM If the LxssManager service is stopping, nothing to do.
    if /i "%state%"=="STOPPING" (goto end)

:next
    REM Check the LxssManager service is started correctly.
    wsl echo OK >nul 2>nul
    if not %errorlevel% == 0 (goto lxssRestart)

    REM Start services in the WSL
    REM Define the service commands in commands.txt.
::  for /f %%i in (%~dp0commands.txt) do (wsl sudo %%i %*)
    for /f %%i in (%~dp0commands.txt) do (wsl %%i %*)
    goto net_alter

:net_alter
    REM Alter network
    SET net_ps1_path=%~dp0net-alter.ps1
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%net_ps1_path%'";
    goto end

:end