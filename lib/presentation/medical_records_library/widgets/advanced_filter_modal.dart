import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AdvancedFilterModal extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;

  const AdvancedFilterModal({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFilterModal> createState() => _AdvancedFilterModalState();
}

class _AdvancedFilterModalState extends State<AdvancedFilterModal> {
  late Map<String, dynamic> _filters;
  DateTimeRange? _dateRange;

  final List<String> _documentTypes = [
    'Prescriptions',
    'Lab Reports',
    'Imaging',
    'Bills',
    'Insurance',
    'Vaccination',
    'Consultation Notes',
    'Discharge Summary',
  ];

  final List<String> _providers = [
    'City General Hospital',
    'Metro Medical Center',
    'Dr. Sarah Johnson',
    'HealthCare Plus Clinic',
    'Advanced Diagnostics Lab',
    'Wellness Medical Group',
    'Emergency Care Center',
    'Specialty Heart Institute',
  ];

  final List<String> _customTags = [
    'Urgent',
    'Follow-up Required',
    'Chronic Condition',
    'Emergency',
    'Routine Checkup',
    'Specialist Referral',
    'Insurance Claim',
    'Second Opinion',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);

    if (_filters['dateRange'] != null) {
      final range = _filters['dateRange'] as Map<String, String>;
      _dateRange = DateTimeRange(
        start: DateTime.parse(range['start']!),
        end: DateTime.parse(range['end']!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSection(context),
                  SizedBox(height: 3.h),
                  _buildDocumentTypesSection(context),
                  SizedBox(height: 3.h),
                  _buildProvidersSection(context),
                  SizedBox(height: 3.h),
                  _buildCustomTagsSection(context),
                  SizedBox(height: 3.h),
                  _buildSortingSection(context),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: CustomIconWidget(
              iconName: 'close',
              color: colorScheme.onSurface,
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Advanced Filters',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Text(
              'Clear All',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'date_range',
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : 'Select date range',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _dateRange != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTypesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Types',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _documentTypes.map((type) {
            final isSelected =
                (_filters['documentTypes'] as List<String>? ?? [])
                    .contains(type);
            return _buildFilterChip(context, type, isSelected, (selected) {
              setState(() {
                final types =
                    (_filters['documentTypes'] as List<String>? ?? []).toList();
                if (selected) {
                  types.add(type);
                } else {
                  types.remove(type);
                }
                _filters['documentTypes'] = types;
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProvidersSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Healthcare Providers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _providers.map((provider) {
            final isSelected = (_filters['providers'] as List<String>? ?? [])
                .contains(provider);
            return _buildFilterChip(context, provider, isSelected, (selected) {
              setState(() {
                final providers =
                    (_filters['providers'] as List<String>? ?? []).toList();
                if (selected) {
                  providers.add(provider);
                } else {
                  providers.remove(provider);
                }
                _filters['providers'] = providers;
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomTagsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Tags',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _customTags.map((tag) {
            final isSelected =
                (_filters['customTags'] as List<String>? ?? []).contains(tag);
            return _buildFilterChip(context, tag, isSelected, (selected) {
              setState(() {
                final tags =
                    (_filters['customTags'] as List<String>? ?? []).toList();
                if (selected) {
                  tags.add(tag);
                } else {
                  tags.remove(tag);
                }
                _filters['customTags'] = tags;
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sortOptions = [
      {'value': 'date_desc', 'label': 'Newest First'},
      {'value': 'date_asc', 'label': 'Oldest First'},
      {'value': 'name_asc', 'label': 'Name A-Z'},
      {'value': 'name_desc', 'label': 'Name Z-A'},
      {'value': 'type', 'label': 'Document Type'},
      {'value': 'provider', 'label': 'Healthcare Provider'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...sortOptions.map((option) {
          final isSelected = _filters['sortBy'] == option['value'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _filters['sortBy'] = option['value'];
              });
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: isSelected
                        ? 'radio_button_checked'
                        : 'radio_button_unchecked',
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    option['label'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryLight,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filters['dateRange'] = {
          'start': picked.start.toIso8601String(),
          'end': picked.end.toIso8601String(),
        };
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
      _dateRange = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
