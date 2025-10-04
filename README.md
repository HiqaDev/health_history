# Health History - Complete Indian Healthcare Management System

A comprehensive Flutter application for managing personal health records, medical documents, medication tracking, and emergency access through QR codes. Built specifically for the Indian healthcare market with Supabase backend.

## 🏥 Features

### Core Healthcare Management
- **Personal Health Dashboard** - Centralized view of health metrics and recent activities
- **Medical Records Library** - Upload, organize, and manage medical documents (lab reports, prescriptions, images)
- **Medication Reminders** - Smart medication tracking with customizable reminder schedules
- **Health Timeline** - Chronological view of medical events and milestones
- **Document Scanner** - Built-in document scanning functionality
- **User Profile & Settings** - Comprehensive user management

### Emergency & Sharing Features
- **QR Code Generation** - Generate emergency medical QR codes with essential health information
- **QR Code Scanner** - Scan QR codes to access emergency medical data
- **Secure Document Sharing** - Share medical documents with healthcare providers securely
- **Emergency Access** - Quick access to critical health information for first responders

### Advanced Features
- **Smart Reminders** - AI-powered medication and appointment reminders
- **Multi-User Role System** - Support for patients, doctors, caregivers, and administrators
- **Doctor Notes** - Healthcare provider note-taking and patient communication (currently under development)

## 🛠 Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Authentication**: Supabase Auth
- **File Storage**: Supabase Storage
- **QR Code**: qr_flutter, mobile_scanner
- **State Management**: Provider pattern
- **Platform**: Android & iOS
  
  ```sh
  brew install supabase/tap/supabase-beta
  brew link --overwrite supabase-beta
  ```
  
  To upgrade:

  ```sh
  brew upgrade supabase
  ```
</details>

<details>
## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (Latest stable version)
2. **Android Studio** or **VS Code** with Flutter extension
3. **Android device** or emulator for testing
4. **Supabase account** for backend services
5. **Git** for version control

### Installation & Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/HiqaDev/health_history.git
cd health_history
```

#### 2. Install Flutter Dependencies
```bash
flutter pub get
```

#### 3. Supabase Setup

**Important**: This project uses a local Supabase CLI executable (`supabase.exe`) for database management. Make sure the executable is in your project root directory.

##### Database Commands (Working Commands for this Project)

```powershell
# Check Supabase projects
.\supabase.exe projects list

# Check migration status
.\supabase.exe migration list --linked

# Apply pending migrations
.\supabase.exe db push --linked

# Check if database is up to date
.\supabase.exe db push --linked

# Create new migration (if needed)
.\supabase.exe migration new migration_name
```

##### Environment Configuration

Create/Update `env.json` in the project root:
```json
{
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here",
  "OPENAI_API_KEY": "your-openai-api-key-here",
  "GEMINI_API_KEY": "your-gemini-api-key-here",
  "ANTHROPIC_API_KEY": "your-anthropic-api-key-here",
  "PERPLEXITY_API_KEY": "your-perplexity-api-key-here"
}
```

#### 4. Database Schema

The project includes complete database migrations in `supabase/migrations/`:

- `20250103120913_health_history_complete_schema.sql` - Main schema with user profiles, medical documents, medications
- `20250103121000_fix_user_profiles_columns.sql` - User profile fixes
- `20250103135000_qr_code_functions.sql` - QR code functionality
- `20250104120000_enhanced_schema_for_indian_market.sql` - Indian healthcare enhancements
- `20250104130000_safe_enhanced_schema.sql` - Safe schema updates
- `20250104140000_add_increment_access_function.sql` - QR access tracking
- `20251003232520_apply_complete_schema.sql` - Final schema application

**Apply All Migrations:**
```powershell
.\supabase.exe db push --linked
```

#### 5. Build and Run

##### For Android Device
```bash
# Check connected devices
flutter devices

# Run on specific device (replace with your device ID)
flutter run -d YOUR_DEVICE_ID

# Build APK for distribution
flutter build apk --debug
```

##### For Development
```bash
# Hot reload development
flutter run
```

## 📱 App Structure

```
lib/
├── core/                    # Core utilities and exports
├── presentation/            # UI screens and widgets
│   ├── splash_screen/
│   ├── login_screen/
│   ├── onboarding_flow/
│   ├── health_dashboard/
│   ├── medical_records_library/
│   ├── medication_reminders/
│   ├── health_timeline/
│   ├── document_scanner/
│   ├── emergency_access/
│   ├── secure_sharing/
│   ├── qr_code_generation/  # QR Code system
│   ├── user_profile_settings/
│   └── user_registration/
├── routes/                  # App navigation
├── services/                # Backend services
│   ├── auth_service.dart
│   ├── supabase_service.dart
│   ├── health_service.dart
│   ├── document_service.dart
│   └── qr_code_service.dart  # QR functionality
├── theme/                   # App theming
└── widgets/                 # Reusable widgets
```

## 🗄 Database Schema

### Core Tables
- **user_profiles** - User information and preferences
- **medical_documents** - Document storage and metadata
- **medications** - Medication tracking and reminders
- **health_metrics** - Vital signs and health measurements
- **appointments** - Healthcare appointments
- **health_events** - Medical timeline events
- **emergency_contacts** - Emergency contact information
- **document_shares** - Secure document sharing

### Security Features
- Row Level Security (RLS) on all tables
- User-based access policies
- Secure file storage with access controls
- Authentication triggers for user management

## 🔧 Troubleshooting

### Common Issues

1. **Build Errors**: Ensure all dependencies are installed with `flutter pub get`
2. **Database Connection**: Verify Supabase credentials in `env.json`
3. **Migration Issues**: Use `.\supabase.exe db push --linked` to apply pending migrations
4. **Android Build**: Ensure Android SDK and build tools are properly configured
5. **Permission Errors**: Grant camera permissions for QR scanning functionality

### Development Tips

1. **Hot Reload**: Use `r` in the terminal during `flutter run` for hot reload
2. **Full Restart**: Use `R` for hot restart when needed
3. **Debug Mode**: Use Flutter DevTools for debugging
4. **Database Inspection**: Use Supabase dashboard for database management

## 📊 Current Status

### Completed Features ✅
- QR Code Generation & Scanning System
- Medical Records Management
- User Authentication & Profiles
- Health Dashboard
- Medication Reminders
- Document Scanner
- Emergency Access
- Secure Sharing
- Database Schema & Migrations

### In Development 🔄
- Doctor Notes System
- Smart Reminders with AI
- Multi-User Role System Enhancement

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue in this repository
- Contact: [Your Contact Information]

---

**Note**: This application is designed specifically for the Indian healthcare market with localized features and compliance considerations.
</details>

<details>
  <summary><b>Other Platforms</b></summary>

  You can also install the CLI via [go modules](https://go.dev/ref/mod#go-install) without the help of package managers.

  ```sh
  go install github.com/supabase/cli@latest
  ```

  Add a symlink to the binary in `$PATH` for easier access:

  ```sh
  ln -s "$(go env GOPATH)/bin/cli" /usr/bin/supabase
  ```

  This works on other non-standard Linux distros.
</details>

<details>
  <summary><b>Community Maintained Packages</b></summary>

  Available via [pkgx](https://pkgx.sh/). Package script [here](https://github.com/pkgxdev/pantry/blob/main/projects/supabase.com/cli/package.yml).
  To install in your working directory:

  ```bash
  pkgx install supabase
  ```

  Available via [Nixpkgs](https://nixos.org/). Package script [here](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/supabase-cli/default.nix).
</details>

### Run the CLI

```bash
supabase bootstrap
```

Or using npx:

```bash
npx supabase bootstrap
```

The bootstrap command will guide you through the process of setting up a Supabase project using one of the [starter](https://github.com/supabase-community/supabase-samples/blob/main/samples.json) templates.

## Docs

Command & config reference can be found [here](https://supabase.com/docs/reference/cli/about).

## Breaking changes

We follow semantic versioning for changes that directly impact CLI commands, flags, and configurations.

However, due to dependencies on other service images, we cannot guarantee that schema migrations, seed.sql, and generated types will always work for the same CLI major version. If you need such guarantees, we encourage you to pin a specific version of CLI in package.json.

## Developing

To run from source:

```sh
# Go >= 1.22
go run . help
```
