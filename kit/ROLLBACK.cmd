@echo off
title Vanilla VR - Go back to the previous version
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1" -Rollback
echo.
pause
