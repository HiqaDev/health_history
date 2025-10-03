# 🏥 Health History App

A comprehensive Flutter-based mobile health application for managing medical records, medications, and health data with secure authentication and emergency access features.

## 📋 Prerequisites

- **Flutter SDK** (^3.35.3)
- **Dart SDK** 
- **Android Studio** / **VS Code** with Flutter extensions
- **Android SDK** / **Xcode** (for iOS development)
- **Chrome Browser** (for web development)
- **Supabase Account** (for backend services)

## � Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/HiqaDev/health_history.git
cd health_history
flutter pub get
```

### 2. Environment Configuration
Create an `env.json` file in the project root with your Supabase credentials:
```json
{
  "SUPABASE_URL": "your_supabase_url",
  "SUPABASE_ANON_KEY": "your_supabase_anon_key"
}
```

## 🧪 Testing & Running the App

### Option 1: Web Development (Recommended for Development) ⚡
**Fastest iteration with hot reload**

```bash
# Enable web support (run once)
flutter config --enable-web

# Run on Chrome for instant development
flutter run -d chrome
```

**Benefits:**
- ⚡ Hot reload in < 1 second
- 🔧 Chrome DevTools for debugging
- 💻 No emulator needed
- 🔄 Instant UI updates

**Hot Reload Commands:**
- `r` - Hot reload (instant UI updates)
- `R` - Hot restart (full app restart)
- `q` - Quit

### Option 2: Android Emulator 📱

```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_id>

# Run app on emulator
flutter run
```

### Option 3: Physical Device 📲

1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging**
3. **Connect via USB**
4. **Run the app:**
```bash
flutter run
```

### Option 4: Production APK Testing 📦

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Install on connected device
flutter install
```

## 🔐 Authentication Flow Testing

### First Time User Journey:
1. **Splash Screen** → Loading and initialization
2. **Onboarding Flow** → Health app introduction (5 screens)
3. **Login Screen** → User authentication
4. **Registration** → If new user
5. **Health Dashboard** → Main app interface

### Returning User Journey:
1. **Splash Screen** → Check authentication
2. **Login Screen** → If logged out
3. **Health Dashboard** → If logged in

### Test Cases:
- ✅ **New User**: Onboarding → Login → Registration → Dashboard
- ✅ **Returning User**: Login → Dashboard  
- ✅ **Logged In User**: Dashboard (persisted login)
- ✅ **Logout**: Dashboard → Login

## 🖼️ Profile Image Testing

### Test the Fixed Image Upload:
1. **Navigate** to User Profile Settings
2. **Tap** "Add Photo" or "Change Photo"
3. **Select** Camera or Gallery
4. **Verify** image appears in profile circle
5. **Test** remove functionality

### Features:
- ✅ Camera/Gallery selection dialog
- ✅ Image preview and cropping
- ✅ Error handling (no crashes)
- ✅ Remove image option

## 🧩 Key Features to Test

### 🏠 Health Dashboard
- Medical records overview
- Medication reminders
- Emergency access QR code
- Health timeline

### 📋 Medical Records Library
- Document upload and categorization
- Search and filter functionality
- Secure document viewing

### 📱 Document Scanner
- Camera integration
- Image processing and OCR
- Document categorization

### 💊 Medication Management
- Reminder scheduling
- Adherence tracking
- Dosage management

### 🆘 Emergency Access
- QR code generation
- Critical health info sharing
- Emergency contact management

### 👤 User Profile
- Personal information management
- Health data configuration
- Profile image upload/change

## 🔧 Development Commands

```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run tests
flutter test

# Clean build cache
flutter clean

# Generate build
flutter build apk --debug
```

## 📁 Project Structure

```
health_history/
├── android/                    # Android configuration
├── ios/                        # iOS configuration  
├── web/                        # Web platform files
├── lib/
│   ├── core/                   # Core utilities
│   ├── models/                 # Data models
│   ├── presentation/           # UI screens
│   │   ├── splash_screen/      # App initialization
│   │   ├── onboarding_flow/    # User onboarding
│   │   ├── login_screen/       # Authentication
│   │   ├── health_dashboard/   # Main dashboard
│   │   ├── user_profile_settings/ # Profile management
│   │   └── ...                 # Other screens
│   ├── routes/                 # App navigation
│   ├── services/               # Backend services
│   │   ├── auth_service.dart   # Supabase authentication
│   │   ├── health_service.dart # Health data management
│   │   └── supabase_service.dart # Database service
│   ├── theme/                  # App theming
│   ├── widgets/                # Reusable components
│   └── main.dart              # App entry point
├── assets/                     # Images and assets
├── supabase/                   # Database migrations
├── pubspec.yaml               # Dependencies
└── env.json                   # Environment variables
```

## 🌐 Supabase Backend Setup

### Database Tables:
- `user_profiles` - User information and health data
- `medical_records` - Document storage and metadata  
- `medications` - Medication and reminder data
- `health_timeline` - Health event tracking

### Authentication:
- Email/password authentication
- Persistent login sessions
- Secure user data access

## 🎨 UI/UX Features

### Design System:
- **Material Design 3** components
- **Responsive layout** with Sizer package
- **Light/Dark theme** support
- **Custom health-focused** color scheme

### Accessibility:
- Screen reader support
- High contrast colors
- Scalable font sizes
- Touch target optimization

## 🚨 Troubleshooting

### Common Issues:

**Flutter not found:**
```bash
# Add Flutter to PATH or use full path
C:\flutter\bin\flutter.bat run -d chrome
```

**Supabase connection issues:**
- Verify `env.json` credentials
- Check network connectivity
- Validate Supabase project settings

**Build failures:**
```bash
flutter clean
flutter pub get
flutter analyze
```

**Emulator issues:**
- Ensure Android SDK is properly installed
- Check available system resources
- Try web development as alternative

## 📱 Live Development Tips

### Fastest Development Workflow:
1. **Use web development** (`flutter run -d chrome`)
2. **Make code changes** in VS Code
3. **Save file** (auto hot reload) or press `r`
4. **See changes instantly** in browser
5. **Test on device** periodically for platform-specific features

### Debugging:
- **Chrome DevTools** for web debugging
- **Flutter Inspector** in VS Code
- **Print statements** for logic debugging
- **Breakpoints** for step-through debugging

## � Security Features

- **Encrypted health data** storage
- **Secure authentication** with Supabase
- **Local data protection**
- **Emergency access** without compromising security
- **HIPAA-compliant** design principles

## 📈 Performance Optimization

- **Lazy loading** for large datasets
- **Image optimization** and caching
- **Efficient state management**
- **Memory-conscious** data handling

## 🎯 Testing Checklist

### Before Release:
- [ ] Authentication flow works end-to-end
- [ ] Profile image upload/change functions
- [ ] All navigation routes accessible  
- [ ] Data persistence after app restart
- [ ] Emergency access QR generation
- [ ] Medication reminders trigger
- [ ] Document upload and viewing
- [ ] Responsive design on different screen sizes
- [ ] Performance on target devices

## � Support

For issues or questions:
- Check this README for common solutions
- Review Flutter documentation
- Check Supabase integration guides
- Create GitHub issues for bugs

---

Built with ❤️ using **Flutter** • **Supabase** • **Material Design**
