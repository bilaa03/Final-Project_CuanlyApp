@echo off
title Hentikan Backend Cuanly
echo Menghentikan proses server Node.js...
taskkill /f /im node.exe >nul 2>&1
echo.
echo ===========================================
echo Server backend telah berhasil dihentikan!
echo Jendela ini bisa ditutup.
echo ===========================================
pause
