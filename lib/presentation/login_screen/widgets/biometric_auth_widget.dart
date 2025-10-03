import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BiometricAuthWidget extends StatefulWidget {
  final VoidCallback? onBiometricSuccess;
  final VoidCallback? onBiometricError;

  const BiometricAuthWidget({
    super.key,
    this.onBiometricSuccess,
    this.onBiometricError,
  });

  @override
  State<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticating = false;
  bool _isBiometricAvailable = false;
  String _biometricType = 'fingerprint';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkBiometricAvailability();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // Simulate biometric availability check
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isBiometricAvailable = true;
          // Simulate different biometric types based on platform
          _biometricType = Theme.of(context).platform == TargetPlatform.iOS
              ? 'face_id'
              : 'fingerprint';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_isBiometricAvailable || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success (80% success rate for demo)
      final isSuccess = DateTime.now().millisecond % 10 < 8;

      if (isSuccess) {
        HapticFeedback.heavyImpact();
        widget.onBiometricSuccess?.call();
      } else {
        HapticFeedback.vibrate();
        widget.onBiometricError?.call();
      }
    } catch (e) {
      HapticFeedback.vibrate();
      widget.onBiometricError?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  IconData _getBiometricIcon() {
    switch (_biometricType) {
      case 'face_id':
        return Icons.face;
      case 'fingerprint':
        return Icons.fingerprint;
      default:
        return Icons.security;
    }
  }

  String _getBiometricLabel() {
    switch (_biometricType) {
      case 'face_id':
        return 'Face ID';
      case 'fingerprint':
        return 'Fingerprint';
      default:
        return 'Biometric';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBiometricAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          // Biometric authentication button
          GestureDetector(
            onTap: _authenticateWithBiometrics,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isAuthenticating ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightTheme.colorScheme.primary,
                          AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isAuthenticating
                          ? SizedBox(
                              width: 8.w,
                              height: 8.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : CustomIconWidget(
                              iconName:
                                  _getBiometricIcon().codePoint.toString(),
                              color: Colors.white,
                              size: 8.w,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 1.h),

          // Biometric label
          Text(
            _isAuthenticating
                ? 'Authenticating...'
                : 'Use ${_getBiometricLabel()}',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 0.5.h),

          // Security message
          Text(
            'Secure access to your health data',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}