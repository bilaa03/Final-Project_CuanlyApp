@echo off
title Start Cuanly Backend Background
echo ====================================================
echo Starting Cuanly Backend under PM2 Process Manager...
echo ====================================================

:: Go to backend directory
cd /d "d:\Bilaa's File\Blok B\Artificial Intelligence\FInSight AI\Cuanly\backend"

:: Check if PM2 is installed
where pm2 >nul 2>nul
if %errorlevel% neq 0 (
    echo PM2 not found. Installing globally...
    call npm install -g pm2
)

echo.
echo Starting server...
call pm2 start src/server.js --name "cuanly-backend"

echo.
echo Save PM2 process list...
call pm2 save

echo.
echo PM2 processes active:
call pm2 status

echo.
echo ====================================================
echo Cuanly Backend is now running in the background!
echo You can close this window.
echo ====================================================
pause
