import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BloodGroupSelectorWidget extends StatelessWidget {
  final String? selectedBloodGroup;
  final Function(String) onBloodGroupSelected;

  const BloodGroupSelectorWidget({
    super.key,
    required this.selectedBloodGroup,
    required this.onBloodGroupSelected,
  });

  static const List<Map<String, dynamic>> bloodGroups = [
    {'type': 'A+', 'color': Color(0xFFE57373), 'icon': 'water_drop'},
    {'type': 'A-', 'color': Color(0xFFEF5350), 'icon': 'water_drop'},
    {'type': 'B+', 'color': Color(0xFF42A5F5), 'icon': 'water_drop'},
    {'type': 'B-', 'color': Color(0xFF2196F3), 'icon': 'water_drop'},
    {'type': 'AB+', 'color': Color(0xFF66BB6A), 'icon': 'water_drop'},
    {'type': 'AB-', 'color': Color(0xFF4CAF50), 'icon': 'water_drop'},
    {'type': 'O+', 'color': Color(0xFFFF7043), 'icon': 'water_drop'},
    {'type': 'O-', 'color': Color(0xFFFF5722), 'icon': 'water_drop'},
  ];

  void _showBloodGroupBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select Blood Group',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 3.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 1.2,
              ),
              itemCount: bloodGroups.length,
              itemBuilder: (context, index) {
                final bloodGroup = bloodGroups[index];
                final isSelected = selectedBloodGroup == bloodGroup['type'];

                return GestureDetector(
                  onTap: () {
                    onBloodGroupSelected(bloodGroup['type']);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? bloodGroup['color'].withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? bloodGroup['color']
                            : AppTheme.lightTheme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: bloodGroup['icon'],
                          size: 6.w,
                          color: bloodGroup['color'],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          bloodGroup['type'],
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? bloodGroup['color']
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBloodGroupBottomSheet(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.lightTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (selectedBloodGroup != null) ...[
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: _getBloodGroupColor(selectedBloodGroup!)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'water_drop',
                    size: 4.w,
                    color: _getBloodGroupColor(selectedBloodGroup!),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  selectedBloodGroup!,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select Blood Group',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
            CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              size: 5.w,
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBloodGroupColor(String bloodGroup) {
    final group = bloodGroups.firstWhere(
      (bg) => bg['type'] == bloodGroup,
      orElse: () => bloodGroups[0],
    );
    return group['color'];
  }
}
