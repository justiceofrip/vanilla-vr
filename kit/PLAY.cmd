@echo off
start "" powershell -nop -ep bypass -sta -w hidden -f "%~dp0launcher.ps1"&exit /b
::
exit /b
