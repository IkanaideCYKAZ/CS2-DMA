@echo off
chcp 65001 >nul 2>&1
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0troubleshoot.ps1"
