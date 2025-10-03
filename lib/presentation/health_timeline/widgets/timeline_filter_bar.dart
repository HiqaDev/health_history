import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TimelineFilterBar extends StatefulWidget {
  final String selectedFilter;
  final DateTimeRange? selectedDateRange;
  final String selectedProvider;
  final String searchQuery;
  final List<String> eventTypes;
  final List<String> providers;
  final Function(String) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function(String) onProviderChanged;
  final Function(String) onSearchChanged;
  final VoidCallback onClearFilters;

  const TimelineFilterBar({
    super.key,
    required this.selectedFilter,
    required this.selectedDateRange,
    required this.selectedProvider,
    required this.searchQuery,
    required this.eventTypes,
    required this.providers,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
    required this.onProviderChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
  });

  @override
  State<TimelineFilterBar> createState() => _TimelineFilterBarState();
}

class _TimelineFilterBarState extends State<TimelineFilterBar> {
  bool _isExpanded = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Always visible: Search bar and toggle button
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search timeline...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.lightTheme.colorScheme.surface,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
                SizedBox(width: 3.w),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.tune,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          // Expandable filters section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child:
                _isExpanded ? _buildFiltersSection() : const SizedBox.shrink(),
          ),
          // Active filters chips (always visible when filters are applied)
          if (_hasActiveFilters()) _buildActiveFiltersChips(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w).copyWith(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event type filter
          Text(
            'Event Type',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: widget.eventTypes.map((type) {
              final isSelected = widget.selectedFilter == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  widget.onFilterChanged(selected ? type : 'All');
                },
                selectedColor:
                    AppTheme.lightTheme.colorScheme.primary.withAlpha(26),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),

          // Date range filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date Range',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.selectedDateRange != null)
                TextButton(
                  onPressed: () => widget.onDateRangeChanged(null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          OutlinedButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            label: Text(
              widget.selectedDateRange != null
                  ? '${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}'
                  : 'Select Date Range',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
          SizedBox(height: 2.h),

          // Provider filter
          Text(
            'Healthcare Provider',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: widget.selectedProvider,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
            items: widget.providers.map((provider) {
              return DropdownMenuItem(
                value: provider,
                child: Text(provider),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onProviderChanged(value);
              }
            },
          ),
          SizedBox(height: 2.h),

          // Clear filters button
          if (_hasActiveFilters())
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorLight,
                  side: BorderSide(color: AppTheme.errorLight),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withAlpha(13),
      ),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 0.5.h,
        children: [
          if (widget.selectedFilter != 'All')
            _buildActiveFilterChip(
              'Type: ${widget.selectedFilter}',
              () => widget.onFilterChanged('All'),
            ),
          if (widget.selectedDateRange != null)
            _buildActiveFilterChip(
              'Date: ${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}',
              () => widget.onDateRangeChanged(null),
            ),
          if (widget.selectedProvider != 'All Providers')
            _buildActiveFilterChip(
              'Provider: ${widget.selectedProvider}',
              () => widget.onProviderChanged('All Providers'),
            ),
          if (widget.searchQuery.isNotEmpty)
            _buildActiveFilterChip(
              'Search: "${widget.searchQuery}"',
              () {
                _searchController.clear();
                widget.onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: AppTheme.lightTheme.textTheme.labelSmall,
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 3.w,
      ),
      onDeleted: onRemove,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary.withAlpha(26),
      deleteIconColor: AppTheme.lightTheme.colorScheme.primary,
    );
  }

  bool _hasActiveFilters() {
    return widget.selectedFilter != 'All' ||
        widget.selectedDateRange != null ||
        widget.selectedProvider != 'All Providers' ||
        widget.searchQuery.isNotEmpty;
  }

  void _showDateRangePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate:
          DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 years ago
      lastDate: DateTime.now(),
      initialDateRange: widget.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.lightTheme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      widget.onDateRangeChanged(dateRange);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
