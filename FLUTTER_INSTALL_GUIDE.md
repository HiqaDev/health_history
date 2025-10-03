# Flutter Installation - Quick Manual Steps

## Problem: Flutter is not installed on your system

## SOLUTION: Install Flutter SDK

### OPTION 1: Quick Installation (Recommended)

1. **Download Flutter SDK:**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Click "Download Flutter SDK" 
   - Download the zip file (~1GB)

2. **Extract and Install:**
   - Extract the zip to `C:\flutter` (or any permanent location)
   - The flutter.exe should be at `C:\flutter\bin\flutter.exe`

3. **Add to PATH:**
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\flutter\bin`
   - Click OK to save

4. **Verify Installation:**
   - Open a NEW PowerShell window
   - Run: `flutter doctor`

### OPTION 2: Alternative - Use Package Manager

```powershell
# Using Chocolatey (if you have it)
choco install flutter

# Using Scoop (if you have it)  
scoop install flutter
```

### OPTION 3: Use VS Code for Flutter Development

1. Install VS Code: https://code.visualstudio.com/
2. Install Flutter extension in VS Code
3. VS Code will help you install Flutter SDK automatically

## After Installation:

1. **Open NEW terminal** (restart PowerShell)
2. **Navigate to your project:**
   ```powershell
   cd "C:\Users\mensl\OneDrive\Documents\GitHub\health_history"
   ```
3. **Run Flutter commands:**
   ```powershell
   flutter doctor
   flutter pub get
   flutter build apk  # (for Android)
   ```

## Additional Requirements for Building:

- **For Android:** Install Android Studio
- **For iOS:** Xcode (macOS only)
- **For Web:** Chrome browser

Your app's code issues are already fixed - you just need Flutter installed to build it!