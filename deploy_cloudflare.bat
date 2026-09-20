@echo off
title Deploy LazyJod to Cloudflare Workers
echo ==========================================================
echo  Deploying LazyJod Gemini Vision Proxy to Cloudflare...
echo ==========================================================
cd /d "%~dp0cloudflare-worker"

echo.
echo Step 1: Deploying Worker to your Cloudflare account...
echo (If not logged in, your browser will open to login Cloudflare)
echo.
cmd.exe /c "npx wrangler deploy"

echo.
echo ==========================================================
echo Step 2: Set your GEMINI_API_KEY secret
echo ==========================================================
cmd.exe /c "npx wrangler secret put GEMINI_API_KEY"

echo.
echo Deployment finished! Copy your worker URL and paste it in
echo lib/core/config/gemini_proxy_config.dart (productionProxyUrl)
pause
