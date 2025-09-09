import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<String> activeFilters;
  final ValueChanged<String> onFilterRemoved;
  final VoidCallback? onClearAll;

  const FilterChipsWidget({
    super.key,
    required this.activeFilters,
    required this.onFilterRemoved,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (activeFilters.length > 1)
                GestureDetector(
                  onTap: onClearAll,
                  child: Text(
                    'Clear All',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: activeFilters.map((filter) {
              return _buildFilterChip(context, filter);
            }).toList(),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filterData = _getFilterData(filter);

    return Container(
      decoration: BoxDecoration(
        color: filterData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filterData['color'].withValues(alpha: 0.3),
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 3.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: filterData['icon'],
                    color: filterData['color'],
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    filterData['label'],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: filterData['color'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onFilterRemoved(filter),
              child: Container(
                margin: EdgeInsets.only(left: 1.w),
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: filterData['color'].withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: filterData['color'],
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getFilterData(String filter) {
    switch (filter.toLowerCase()) {
      case 'prescriptions':
        return {
          'label': 'Prescriptions',
          'icon': 'medication',
          'color': AppTheme.primaryLight,
        };
      case 'lab reports':
        return {
          'label': 'Lab Reports',
          'icon': 'science',
          'color': AppTheme.successLight,
        };
      case 'imaging':
        return {
          'label': 'Imaging',
          'icon': 'medical_services',
          'color': AppTheme.secondaryLight,
        };
      case 'bills':
        return {
          'label': 'Bills',
          'icon': 'receipt',
          'color': AppTheme.warningLight,
        };
      case 'insurance':
        return {
          'label': 'Insurance',
          'icon': 'shield',
          'color': AppTheme.primaryVariantLight,
        };
      case 'vaccination':
        return {
          'label': 'Vaccination',
          'icon': 'vaccines',
          'color': AppTheme.accentLight,
        };
      case 'recent':
        return {
          'label': 'Recent',
          'icon': 'schedule',
          'color': AppTheme.textSecondaryLight,
        };
      case 'favorites':
        return {
          'label': 'Favorites',
          'icon': 'favorite',
          'color': AppTheme.warningLight,
        };
      default:
        return {
          'label': filter,
          'icon': 'label',
          'color': AppTheme.textSecondaryLight,
        };
    }
  }
}
