@echo off
echo Flutter Installation Guide for Windows
echo =====================================
echo.
echo STEP 1: Download Flutter SDK
echo ---------------------------
echo 1. Go to: https://docs.flutter.dev/get-started/install/windows
echo 2. Download the latest stable Flutter SDK (zip file)
echo 3. Extract to a permanent location (e.g., C:\flutter)
echo.
echo STEP 2: Add Flutter to PATH
echo ---------------------------
echo 1. Open System Properties:
echo    - Press Win + X, select "System"
echo    - Click "Advanced system settings"
echo    - Click "Environment Variables"
echo.
echo 2. Edit PATH variable:
echo    - In "User variables", find "Path" and click "Edit"
echo    - Click "New" and add: C:\flutter\bin
echo    - Click "OK" to save
echo.
echo STEP 3: Install Dependencies
echo ----------------------------
echo Run these commands in a NEW PowerShell window:
echo.
echo flutter doctor
echo flutter doctor --android-licenses  (if you have Android Studio)
echo.
echo STEP 4: Install Android Studio (Required)
echo ----------------------------------------
echo 1. Download from: https://developer.android.com/studio
echo 2. Install with default settings
echo 3. Install Flutter and Dart plugins in Android Studio
echo.
echo STEP 5: Verify Installation
echo ---------------------------
echo flutter doctor
echo flutter create test_app
echo cd test_app
echo flutter run
echo.
echo ALTERNATIVE: Use Flutter with VS Code
echo ------------------------------------
echo 1. Install VS Code: https://code.visualstudio.com/
echo 2. Install Flutter extension in VS Code
echo 3. Install Dart extension in VS Code
echo.
echo After installation, restart your terminal and run:
echo flutter doctor
echo.
pause