import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color? activeColor;
  final Color? inactiveColor;

  const PageIndicatorWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: index == currentPage ? 8.w : 2.w,
          height: 1.h,
          decoration: BoxDecoration(
            color: index == currentPage
                ? (activeColor ?? colorScheme.primary)
                : (inactiveColor ??
                    colorScheme.onSurface.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(0.5.h),
          ),
        ),
      ),
    );
  }
}
