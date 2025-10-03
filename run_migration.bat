@echo off
echo Running Supabase migration to fix user_profiles table...

REM Check if supabase CLI is installed
supabase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Supabase CLI is not installed or not in PATH
    echo Please install it first: npm install -g supabase
    pause
    exit /b 1
)

REM Check if supabase is linked to a project
if not exist ".supabase" (
    echo Error: This project is not linked to a Supabase project
    echo Please run: supabase link --project-ref YOUR_PROJECT_REF
    pause
    exit /b 1
)

REM Run the migration
echo Applying migration to add missing columns to user_profiles table...
supabase db push

if %errorlevel% equ 0 (
    echo Migration applied successfully!
) else (
    echo Migration failed. Please check your Supabase connection and try again.
)

pause