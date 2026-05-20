@echo off
REM ============================================================
REM PUSH THESIS TO GITHUB
REM Double-click this file to push the thesis to GitHub
REM Prerequisites: Git installed, GitHub repo created
REM ============================================================

echo === THESIS GITHUB PUSH ===
echo.

REM Step 1: Check git is installed
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Git not found. Install from https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Step 2: Go to thesis folder
cd /d "%~dp0"
echo Working directory: %CD%

REM Step 3: Check if remote exists
git remote get-url origin >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo No git remote configured.
    echo.
    echo FIRST: Create a GitHub repo at https://github.com/new
    echo   Name: thesis-intl-students-dutch-wages
    echo   Do NOT initialize with README
    echo.
    echo Then enter your GitHub username:
    set /p GH_USER="GitHub username: "
    git remote add origin https://github.com/%GH_USER%/thesis-intl-students-dutch-wages.git
    echo Remote added.
)

REM Step 4: Stage all thesis files
echo.
echo Staging files...
git add thesis_complete.Rmd data_preparation.R build_instrument.py ^
       instrument_values.csv cbs_field_shares.csv herkomst_visa_rates.csv ^
       country_crosswalk.csv references.bib apa.csl README.md .gitignore

REM Step 5: Commit
echo.
echo Committing...
git commit -m "Complete thesis: field-level shift-share IV with visa acceptance rates" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo (No new changes to commit, or commit already exists)
)

REM Step 6: Push
echo.
echo Pushing to GitHub...
echo You may be prompted for your GitHub username and password/token.
echo.
git push -u origin master 2>&1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Thesis pushed to GitHub.
    echo ========================================
) else (
    echo.
    echo Push failed. You may need to:
    echo   1. Create a Personal Access Token at https://github.com/settings/tokens
    echo   2. Use the token as your password when prompted
    echo   3. Or run: git push -u origin master
)

pause
