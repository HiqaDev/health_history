import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/health_dashboard/health_dashboard.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/medical_records_library/medical_records_library.dart';
import '../presentation/document_scanner/document_scanner.dart';
import '../presentation/medication_reminders/medication_reminders.dart';
import '../presentation/health_timeline/health_timeline.dart';
import '../presentation/emergency_access/emergency_access.dart';
import '../presentation/secure_sharing/secure_sharing.dart';
import '../presentation/user_profile_settings/user_profile_settings.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String healthDashboard = '/health-dashboard';
  static const String userRegistration = '/user-registration';
  static const String medicalRecordsLibrary = '/medical-records-library';
  static const String documentScanner = '/document-scanner';
  static const String medicationReminders = '/medication-reminders';
  static const String healthTimeline = '/health-timeline';
  static const String emergencyAccess = '/emergency-access';
  static const String secureSharing = '/secure-sharing';
  static const String userProfileSettings = '/user-profile-settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    healthDashboard: (context) => const HealthDashboard(),
    userRegistration: (context) => const UserRegistration(),
    medicalRecordsLibrary: (context) => const MedicalRecordsLibrary(),
    documentScanner: (context) => const DocumentScanner(),
    medicationReminders: (context) => const MedicationReminders(),
    healthTimeline: (context) => const HealthTimeline(),
    emergencyAccess: (context) => const EmergencyAccess(),
    secureSharing: (context) => const SecureSharing(),
    userProfileSettings: (context) => const UserProfileSettings(),
  };
}
