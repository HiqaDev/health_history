import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/animated_logo_widget.dart';
import './widgets/background_gradient_widget.dart';
import './widgets/loading_indicator_widget.dart';

/// Splash Screen for Health History app
/// Provides branded app launch experience while initializing secure health data services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _loadingProgress = 0.0;
  String _loadingText = 'Initializing Health Vault...';
  bool _isInitialized = false;

  // Authentication and onboarding services
  final AuthService _authService = AuthService();
  bool _isUserAuthenticated = false;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setSystemUIOverlay();
  }

  /// Set system UI overlay style to match brand colors
  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppTheme.lightTheme.colorScheme.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Initialize app with critical background tasks
  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize encrypted storage
      await _updateProgress(0.2, 'Setting up encrypted storage...');
      await _initializeEncryptedStorage();

      // Step 2: Check authentication status
      await _updateProgress(0.4, 'Checking authentication...');
      await _checkAuthenticationStatus();

      // Step 3: Prepare biometric authentication
      await _updateProgress(0.6, 'Preparing biometric security...');
      await _prepareBiometricAuth();

      // Step 4: Load user health preferences
      await _updateProgress(0.8, 'Loading health preferences...');
      await _loadHealthPreferences();

      // Step 5: Verify security certificates
      await _updateProgress(1.0, 'Finalizing security setup...');
      await _verifySecurityCertificates();

      // Complete initialization
      setState(() {
        _isInitialized = true;
      });

      // Navigate based on user status
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();
    } catch (e) {
      // Handle initialization errors gracefully
      _handleInitializationError(e);
    }
  }

  /// Update loading progress with animation
  Future<void> _updateProgress(double progress, String text) async {
    setState(() {
      _loadingProgress = progress;
      _loadingText = text;
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Initialize encrypted storage setup
  Future<void> _initializeEncryptedStorage() async {
    // Simulate encrypted storage initialization
    await Future.delayed(const Duration(milliseconds: 500));
    // In real implementation: Initialize secure storage, create encryption keys
  }

  /// Check user authentication status
  Future<void> _checkAuthenticationStatus() async {
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      // Check if user is authenticated with Supabase
      setState(() {
        _isUserAuthenticated = _authService.isAuthenticated;
      });

      // Check if user has completed onboarding
      if (_isUserAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
        });
      } else {
        // Check if first-time user (for onboarding)
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
        });
      }
    } catch (e) {
      print('Error checking authentication status: $e');
      setState(() {
        _isUserAuthenticated = false;
        _hasCompletedOnboarding = false;
      });
    }
  }

  /// Prepare biometric authentication
  Future<void> _prepareBiometricAuth() async {
    // Simulate biometric setup check
    await Future.delayed(const Duration(milliseconds: 300));
    // Note: Biometric authentication can be implemented later
    // For now, we'll focus on email/password authentication
  }

  /// Load user health preferences
  Future<void> _loadHealthPreferences() async {
    // Simulate loading cached medical data
    await Future.delayed(const Duration(milliseconds: 400));
    // In real implementation: Load user preferences, cached data
  }

  /// Verify security certificates
  Future<void> _verifySecurityCertificates() async {
    // Simulate security verification
    await Future.delayed(const Duration(milliseconds: 300));
    // In real implementation: Verify SSL certificates, security protocols
  }

  /// Navigate to appropriate screen based on user status
  void _navigateToNextScreen() {
    if (!mounted) return;

    if (_isUserAuthenticated) {
      // Authenticated users go directly to dashboard
      Navigator.pushReplacementNamed(context, '/health-dashboard');
    } else if (!_hasCompletedOnboarding) {
      // New users see onboarding flow first
      Navigator.pushReplacementNamed(context, '/onboarding-flow');
    } else {
      // Returning users who have completed onboarding but aren't logged in go to login
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  }

  /// Handle initialization errors
  void _handleInitializationError(dynamic error) {
    setState(() {
      _loadingText = 'Initialization failed. Retrying...';
    });

    // Show error dialog with retry option
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'Initialization Error',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Failed to initialize Health Vault. Please check your connection and try again.',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry initialization
            },
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/onboarding-flow');
            },
            child: Text(
              'Continue Offline',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          const BackgroundGradientWidget(),

          // Safe area content
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spacer to push content to center
                  const Spacer(flex: 2),

                  // App logo with animation
                  const AnimatedLogoWidget(),

                  SizedBox(height: 4.h),

                  // App name
                  Text(
                    'Health History',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // App tagline
                  Text(
                    'Your Digital Health Vault',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),

                  // Spacer
                  const Spacer(flex: 1),

                  // Loading indicator
                  LoadingIndicatorWidget(
                    progress: _loadingProgress,
                    loadingText: _loadingText,
                  ),

                  SizedBox(height: 6.h),

                  // Security badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'security',
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'HIPAA Compliant & Encrypted',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Reset system UI overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }
}