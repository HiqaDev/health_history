import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/health_dashboard/health_dashboard.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/medical_records_library/medical_records_library.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String healthDashboard = '/health-dashboard';
  static const String userRegistration = '/user-registration';
  static const String medicalRecordsLibrary = '/medical-records-library';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    healthDashboard: (context) => const HealthDashboard(),
    userRegistration: (context) => const UserRegistration(),
    medicalRecordsLibrary: (context) => const MedicalRecordsLibrary(),
    // TODO: Add your other routes here
  };
}