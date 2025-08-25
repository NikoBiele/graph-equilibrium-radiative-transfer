@echo off
echo ========================================
echo TESTING QUARTO BUILD BEFORE COMMIT
echo ========================================

REM Kill any lingering processes that might be locking files
taskkill /f /im "quarto.exe" 2>nul
taskkill /f /im "deno.exe" 2>nul

REM Wait a moment for processes to fully terminate
timeout /t 2 /nobreak >nul

REM Clean build directories (suppress prompts and errors)
if exist "_book" rmdir /s /q "_book" 2>nul
if exist ".quarto" rmdir /s /q ".quarto" 2>nul

echo Cleaned previous build files...
echo.

REM First attempt (silent) - clears any remaining file locks
echo First build attempt (clearing locks)...
quarto render >nul 2>nul

REM Wait a moment
timeout /t 1 /nobreak >nul

REM Second attempt (with output) - should succeed
echo.
echo Final build attempt...
quarto render

REM Check if render was successful by looking for the main output file
if exist "_book\index.html" (
    echo.
    echo ========================================
    echo SUCCESS: Book compiled successfully!
    echo ========================================
    echo Opening book in browser...
    start _book\index.html
    echo.
    echo SAFE TO COMMIT AND PUSH
) else (
    echo.
    echo ========================================
    echo ERROR: Build failed on both attempts!
    echo ========================================
    echo DO NOT COMMIT - FIX ERRORS FIRST
    echo Check the output above for error messages.
)

echo.
pause