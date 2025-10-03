import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';
import './widgets/permission_card_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  final int _totalPages = 5;

  // Permission states
  bool _cameraPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _biometricSetupCompleted = false;

  // Onboarding data
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Secure Health Records',
      'description':
          'Store all your medical documents, prescriptions, and lab reports in one secure, encrypted digital vault accessible anytime, anywhere.',
      'iconName': 'security',
      'backgroundColor': const Color(0xFF2E7D8F),
    },
    {
      'title': 'Emergency Access',
      'description':
          'Generate QR codes for instant access to critical medical information during emergencies. Share vital health data with first responders.',
      'iconName': 'qr_code_scanner',
      'backgroundColor': const Color(0xFFFF6B6B),
    },
    {
      'title': 'Smart Reminders',
      'description':
          'Never miss medications, appointments, or lab tests with intelligent notifications tailored to your health schedule.',
      'iconName': 'notifications_active',
      'backgroundColor': const Color(0xFFFFE66D),
    },
    {
      'title': 'Doctor Collaboration',
      'description':
          'Securely share your complete medical history with healthcare providers. Enable doctors to add notes and track your progress.',
      'iconName': 'people',
      'backgroundColor': const Color(0xFF4ECDC4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _cameraPermissionGranted = cameraStatus.isGranted;
      _notificationPermissionGranted = notificationStatus.isGranted;
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() async {
    HapticFeedback.mediumImpact();
    
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-screen',
      (route) => false,
    );
  }

  void _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-screen',
      (route) => false,
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      HapticFeedback.lightImpact();
    }
  }

  void _setupBiometric() {
    setState(() {
      _biometricSetupCompleted = true;
    });
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Biometric authentication enabled'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }

  Widget _buildPermissionsPage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              // Header
              Text(
                'Setup Permissions',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 1.h),

              Text(
                'Enable these features to get the most out of Health History',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              SizedBox(height: 4.h),

              // Permission Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PermissionCardWidget(
                        title: 'Camera Access',
                        description:
                            'Scan and capture medical documents, prescriptions, and lab reports',
                        iconName: 'camera_alt',
                        isGranted: _cameraPermissionGranted,
                        onTap: _requestCameraPermission,
                      ),

                      PermissionCardWidget(
                        title: 'Notifications',
                        description:
                            'Receive medication reminders and appointment alerts',
                        iconName: 'notifications',
                        isGranted: _notificationPermissionGranted,
                        onTap: _requestNotificationPermission,
                      ),

                      PermissionCardWidget(
                        title: 'Biometric Security',
                        description:
                            'Secure your health data with fingerprint or face recognition',
                        iconName: 'fingerprint',
                        isGranted: _biometricSetupCompleted,
                        onTap: _setupBiometric,
                      ),

                      SizedBox(height: 4.h),

                      // Emergency Access Demo
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.w),
                          border: Border.all(
                            color: AppTheme.errorLight.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'emergency',
                                  color: AppTheme.errorLight,
                                  size: 6.w,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  'Emergency QR Code',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorLight,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Your medical information will be accessible via QR code during emergencies, even when your phone is locked.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2.w),
                                border: Border.all(
                                  color: AppTheme.errorLight
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'qr_code',
                                  color: AppTheme.errorLight,
                                  size: 15.w,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Page View
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                HapticFeedback.selectionClick();
              },
              children: [
                // Onboarding Pages
                ..._onboardingData.map((data) => OnboardingPageWidget(
                      title: data['title'],
                      description: data['description'],
                      iconName: data['iconName'],
                      backgroundColor: data['backgroundColor'],
                      iconColor: data['backgroundColor'],
                    )),

                // Permissions Page
                _buildPermissionsPage(),
              ],
            ),

            // Skip Button
            if (_currentPage < _totalPages - 1)
              Positioned(
                top: 8.h,
                right: 6.w,
                child: SafeArea(
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page Indicator
                      PageIndicatorWidget(
                        currentPage: _currentPage,
                        totalPages: _totalPages,
                        activeColor: colorScheme.primary,
                        inactiveColor:
                            colorScheme.onSurface.withValues(alpha: 0.3),
                      ),

                      SizedBox(height: 3.h),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor:
                                colorScheme.shadow.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3.h),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _totalPages - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentPage < _totalPages - 1) ...[
                                SizedBox(width: 2.w),
                                CustomIconWidget(
                                  iconName: 'arrow_forward',
                                  color: Colors.white,
                                  size: 5.w,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}