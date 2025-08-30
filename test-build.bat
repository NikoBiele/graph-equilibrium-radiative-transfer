@echo off
setlocal EnableDelayedExpansion

REM ======== CONFIG ========
set "PKG_NAME=RayTraceHeatTransfer"
set "PKG_REMOTE_URL=https://github.com/NikoBiele/RayTraceHeatTransfer.jl"
set "PKG_REMOTE_REV=main"
REM ========================

echo ========================================
echo TESTING QUARTO BUILD BEFORE COMMIT
echo ========================================

REM Close Quarto bits that can hold locks (leave Julia alone)
for %%P in (quarto.exe deno.exe) do taskkill /f /im "%%P" >NUL 2>&1
timeout /t 1 /nobreak >NUL

REM Light cleanup (don't delete while Quarto still running)
echo Cleaned previous build files...
echo.

REM Use local profile = no freeze / no cache
set "QUARTO_PROFILE=local"

echo Preparing Julia environment...
REM Ensure deps + track package main branch
julia --project=. -e "using Pkg; \
    Pkg.activate(pwd()); \
    Pkg.add([PackageSpec(name=\"IJulia\"), PackageSpec(name=\"CairoMakie\")]); \
    Pkg.add(PackageSpec(name=\"%PKG_NAME%\", url=\"%PKG_REMOTE_URL%\", rev=\"%PKG_REMOTE_REV%\")); \
    Pkg.instantiate(); Pkg.precompile();" || goto :fail

REM Stubborn-cache remover (with retries) via PowerShell
powershell -NoProfile -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "function Remove-Path([string]$p){ if(Test-Path $p){ for($i=1;$i -le 5;$i++){ try{ Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds (300*$i) } } } };" ^
  "Remove-Path '.quarto\_freeze'; Remove-Path '_freeze';" ^
  "Get-ChildItem -Recurse -Filter 'execute-results' -Directory | ForEach-Object { Remove-Path $_.FullName }" >NUL 2>&1

echo.
echo Rendering book (profile=local)...
quarto render --profile local
if errorlevel 1 (
  echo Render failed, trying once more after deep clean...
  powershell -NoProfile -Command ^
    "$ErrorActionPreference='SilentlyContinue';" ^
    "Get-Process -Name 'deno','quarto' -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Milliseconds 700;" ^
    "function Remove-Path([string]$p){ if(Test-Path $p){ Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue } };" ^
    "Remove-Path '.quarto'; Remove-Path '_freeze'; Remove-Path '.ipynb_checkpoints';" ^
    "Get-ChildItem -Recurse -Filter 'execute-results' -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue" >NUL 2>&1

  quarto render --profile local || goto :fail
)

echo.
echo ========================================
echo SUCCESS: Book compiled successfully!
echo ========================================
start "" "_book\index.html"
echo.
echo SAFE TO COMMIT AND PUSH
goto :end

:fail
echo.
echo ========================================
echo ERROR: Build failed!
echo ========================================
echo DO NOT COMMIT - FIX ERRORS FIRST
echo.
pause
:end
endlocal