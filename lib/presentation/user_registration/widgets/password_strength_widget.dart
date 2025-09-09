import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PasswordStrengthWidget extends StatelessWidget {
  final String password;

  const PasswordStrengthWidget({
    super.key,
    required this.password,
  });

  PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Common patterns penalty
    if (password.toLowerCase().contains('password') ||
        password.toLowerCase().contains('123456') ||
        password.toLowerCase().contains('qwerty')) {
      score = score > 1 ? score - 2 : 0;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  List<String> _getRequirements(String password) {
    List<String> requirements = [];

    if (password.length < 8) {
      requirements.add('At least 8 characters');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('One lowercase letter');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('One uppercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('One number');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      requirements.add('One special character');
    }

    return requirements;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final requirements = _getRequirements(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                strength.label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: strength.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: strength.strengthIndex >= 1
                        ? strength.color
                        : AppTheme.lightTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Container(
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: strength.strengthIndex >= 2
                        ? strength.color
                        : AppTheme.lightTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Container(
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: strength.strengthIndex >= 3
                        ? strength.color
                        : AppTheme.lightTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          if (requirements.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              'Requirements:',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            ...requirements.map((requirement) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'radio_button_unchecked',
                        size: 3.w,
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        requirement,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

enum PasswordStrength {
  none(0, 'None', Colors.grey),
  weak(1, 'Weak', Color(0xFFFF6B6B)),
  medium(2, 'Medium', Color(0xFFFFE66D)),
  strong(3, 'Strong', Color(0xFF4ECDC4));

  const PasswordStrength(this.strengthIndex, this.label, this.color);

  final int strengthIndex;
  final String label;
  final Color color;
}