@echo off
cd /d "%~dp0"
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" (
  echo Chrome not found — using Microsoft Edge for Flutter web.
  set "CHROME=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
set CHROME_EXECUTABLE=%CHROME%
flutter run -d chrome
