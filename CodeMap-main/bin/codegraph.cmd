@echo off
:: codegraph.cmd - Windows CMD wrapper with multi-level binary discovery
:: Lookup order: PATH > %CODEMAP_HOME%\bin\ > local dir > dev build > auto-download

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"

if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "_ARCH=x86_64"
) else if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "_ARCH=aarch64"
) else if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
    set "_ARCH=x86_64"
) else (
    echo [CodeMap] Unsupported architecture: %PROCESSOR_ARCHITECTURE% >&2
    exit /b 1
)

set "_BIN_NAME=codegraph-%_ARCH%-windows.exe"
if defined CODEMAP_HOME (
    set "CODEMAP_HOME=%CODEMAP_HOME%"
) else (
    set "CODEMAP_HOME=%USERPROFILE%\.codemap"
)
set "CODEMAP_BIN_DIR=%CODEMAP_HOME%\bin"
set "GITHUB_REPO=killvxk/CodeMap"
set "_BIN="

where %_BIN_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where %_BIN_NAME%') do (
        set "_BIN=%%i"
        goto :found
    )
)

if exist "%CODEMAP_BIN_DIR%\%_BIN_NAME%" (
    set "_BIN=%CODEMAP_BIN_DIR%\%_BIN_NAME%"
    goto :found
)

if exist "%SCRIPT_DIR%%_BIN_NAME%" (
    set "_BIN=%SCRIPT_DIR%%_BIN_NAME%"
    goto :found
)

if exist "%REPO_ROOT%\rust-cli\target\release\codegraph.exe" (
    set "_BIN=%REPO_ROOT%\rust-cli\target\release\codegraph.exe"
    goto :found
)
if exist "%REPO_ROOT%\rust-cli\target\debug\codegraph.exe" (
    set "_BIN=%REPO_ROOT%\rust-cli\target\debug\codegraph.exe"
    goto :found
)
if exist "rust-cli\target\release\codegraph.exe" (
    set "_BIN=rust-cli\target\release\codegraph.exe"
    goto :found
)
if exist "rust-cli\target\debug\codegraph.exe" (
    set "_BIN=rust-cli\target\debug\codegraph.exe"
    goto :found
)

echo [CodeMap] codegraph binary (%_BIN_NAME%) not found; downloading from GitHub Releases... >&2

set "_DOWNLOAD_URL=https://github.com/%GITHUB_REPO%/releases/latest/download/%_BIN_NAME%"

if not exist "%CODEMAP_BIN_DIR%" mkdir "%CODEMAP_BIN_DIR%"
set "_TARGET=%CODEMAP_BIN_DIR%\%_BIN_NAME%"

where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -fSL --progress-bar -o "%_TARGET%" "%_DOWNLOAD_URL%"
    if %errorlevel% equ 0 (
        if exist "%_TARGET%" (
            echo [CodeMap] Downloaded to %_TARGET% >&2
            set "_BIN=%_TARGET%"
            goto :found
        )
    )
)

where powershell >nul 2>&1
if %errorlevel% equ 0 (
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '%_DOWNLOAD_URL%' -OutFile '%_TARGET%'" 2>nul
    if exist "%_TARGET%" (
        echo [CodeMap] Downloaded to %_TARGET% >&2
        set "_BIN=%_TARGET%"
        goto :found
    )
)

echo [CodeMap] Download failed, please fetch manually: %_DOWNLOAD_URL% >&2
echo [CodeMap] Place it in one of these locations: >&2
echo [CodeMap]   1. %CODEMAP_BIN_DIR%\%_BIN_NAME% >&2
echo [CodeMap]   2. PATH ?????? >&2
exit /b 1

:found
"%_BIN%" %*
