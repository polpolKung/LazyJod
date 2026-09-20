@echo off
title LazyJod - Gemini Vision Backend Proxy
echo ====================================================
echo Starting LazyJod Gemini Vision Backend Proxy...
echo ====================================================
cd /d "%~dp0backend"
if not exist node_modules (
    echo Installing dependencies...
    cmd.exe /c npm install
)
echo Starting server...
node server.js
pause
