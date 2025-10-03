# Flutter Auto-Installer for Windows
# Run this script as Administrator for best results

Write-Host "Flutter Auto-Installer for Windows" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "Warning: Not running as Administrator. Some steps may require manual intervention." -ForegroundColor Yellow
}

# Define Flutter installation directory
$flutterDir = "C:\flutter"
$flutterBin = "$flutterDir\bin"

Write-Host "`nStep 1: Checking if Flutter is already installed..." -ForegroundColor Cyan

# Check if Flutter is already in PATH
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Flutter is already installed!" -ForegroundColor Green
        flutter doctor
        exit 0
    }
} catch {
    Write-Host "Flutter not found in PATH. Proceeding with installation..." -ForegroundColor Yellow
}

Write-Host "`nStep 2: Downloading Flutter SDK..." -ForegroundColor Cyan

# Create flutter directory if it doesn't exist
if (-not (Test-Path $flutterDir)) {
    New-Item -ItemType Directory -Path $flutterDir -Force | Out-Null
}

# Download Flutter SDK
$flutterZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
$flutterZipPath = "$env:TEMP\flutter_windows_stable.zip"

try {
    Write-Host "Downloading Flutter SDK (this may take a few minutes)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $flutterZipUrl -OutFile $flutterZipPath -UseBasicParsing
    Write-Host "Download completed!" -ForegroundColor Green
} catch {
    Write-Host "Error downloading Flutter SDK: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download manually from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nStep 3: Extracting Flutter SDK..." -ForegroundColor Cyan

try {
    # Extract Flutter SDK
    Expand-Archive -Path $flutterZipPath -DestinationPath "C:\" -Force
    Write-Host "Flutter SDK extracted to $flutterDir" -ForegroundColor Green
} catch {
    Write-Host "Error extracting Flutter SDK: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nStep 4: Adding Flutter to PATH..." -ForegroundColor Cyan

# Add Flutter to user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterBin*") {
    $newPath = "$currentPath;$flutterBin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Flutter added to PATH!" -ForegroundColor Green
} else {
    Write-Host "Flutter already in PATH!" -ForegroundColor Green
}

# Refresh PATH for current session
$env:Path += ";$flutterBin"

Write-Host "`nStep 5: Running Flutter Doctor..." -ForegroundColor Cyan

try {
    & "$flutterBin\flutter.bat" doctor
} catch {
    Write-Host "Error running flutter doctor. Try opening a new terminal window." -ForegroundColor Red
}

Write-Host "`nInstallation Summary:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "✅ Flutter SDK downloaded and extracted" -ForegroundColor Green
Write-Host "✅ Flutter added to PATH" -ForegroundColor Green
Write-Host "" 
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Close this terminal and open a new PowerShell window" -ForegroundColor White
Write-Host "2. Run: flutter doctor" -ForegroundColor White
Write-Host "3. Install Android Studio if you plan to develop for Android" -ForegroundColor White
Write-Host "4. Navigate to your project and run: flutter pub get" -ForegroundColor White

# Clean up
Remove-Item $flutterZipPath -Force -ErrorAction SilentlyContinue

Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")