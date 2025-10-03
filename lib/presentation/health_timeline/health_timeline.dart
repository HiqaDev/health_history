import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/add_event_fab.dart';
import './widgets/health_trends_chart.dart';
import './widgets/timeline_event_card.dart';
import './widgets/timeline_filter_bar.dart';
import './widgets/year_marker_widget.dart';

class HealthTimeline extends StatefulWidget {
  const HealthTimeline({super.key});

  @override
  State<HealthTimeline> createState() => _HealthTimelineState();
}

class _HealthTimelineState extends State<HealthTimeline>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  bool _isLoading = false;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  String _selectedProvider = 'All Providers';
  String _searchQuery = '';
  bool _showChart = false;
  List<String> _selectedEventTypes = [];

  final List<String> _eventTypes = [
    'All',
    'Appointments',
    'Medications',
    'Lab Results',
    'Procedures',
    'Symptoms',
    'Vaccinations'
  ];

  final List<String> _providers = [
    'All Providers',
    'Dr. Smith (Cardiology)',
    'Dr. Johnson (General)',
    'City Hospital',
    'MediLab Testing',
    'Pharmacy Plus'
  ];

  List<Map<String, dynamic>> _timelineEvents = [
    {
      'id': '1',
      'title': 'Annual Checkup',
      'subtitle': 'Dr. Smith - Cardiology',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'type': 'Appointments',
      'description':
          'Routine annual health examination. Blood pressure, heart rate, and general health assessment completed.',
      'attachments': ['ECG_Report.pdf', 'Blood_Test_Results.pdf'],
      'icon': Icons.medical_services,
      'color': AppTheme.primaryLight,
      'hasDocuments': true,
      'notes':
          'Patient shows excellent cardiovascular health. Continue current exercise routine.',
    },
    {
      'id': '2',
      'title': 'Blood Pressure Medication',
      'subtitle': 'Lisinopril 10mg - Daily',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'type': 'Medications',
      'description':
          'Started new blood pressure medication as prescribed by Dr. Smith.',
      'attachments': ['Prescription_Lisinopril.pdf'],
      'icon': Icons.medication,
      'color': AppTheme.successLight,
      'hasDocuments': true,
      'notes':
          'Take once daily in the morning with food. Monitor for dizziness.',
    },
    {
      'id': '3',
      'title': 'Blood Panel Results',
      'subtitle': 'MediLab Testing',
      'date': DateTime.now().subtract(const Duration(days: 21)),
      'type': 'Lab Results',
      'description':
          'Comprehensive metabolic panel and lipid profile completed.',
      'attachments': ['Lab_Results_March2024.pdf', 'Reference_Ranges.pdf'],
      'icon': Icons.science,
      'color': AppTheme.warningLight,
      'hasDocuments': true,
      'notes':
          'Cholesterol levels slightly elevated. Discuss dietary changes at next visit.',
    },
    {
      'id': '4',
      'title': 'Cardiac Catheterization',
      'subtitle': 'City Hospital - Interventional Cardiology',
      'date': DateTime.now().subtract(const Duration(days: 45)),
      'type': 'Procedures',
      'description':
          'Diagnostic cardiac catheterization to evaluate coronary arteries.',
      'attachments': [
        'Catheterization_Report.pdf',
        'Post_Procedure_Instructions.pdf'
      ],
      'icon': Icons.healing,
      'color': AppTheme.accentLight,
      'hasDocuments': true,
      'notes':
          'No significant blockages found. Excellent coronary artery health.',
    },
    {
      'id': '5',
      'title': 'Chest Discomfort',
      'subtitle': 'Self-Reported Symptom',
      'date': DateTime.now().subtract(const Duration(days: 52)),
      'type': 'Symptoms',
      'description':
          'Mild chest discomfort during physical activity. Led to cardiology referral.',
      'attachments': [],
      'icon': Icons.warning,
      'color': AppTheme.errorLight,
      'hasDocuments': false,
      'notes':
          'Resolved after cardiac evaluation. Likely muscle strain from exercise.',
    },
    {
      'id': '6',
      'title': 'COVID-19 Booster',
      'subtitle': 'Pharmacy Plus - Vaccination',
      'date': DateTime.now().subtract(const Duration(days: 120)),
      'type': 'Vaccinations',
      'description':
          'COVID-19 booster vaccination (Pfizer-BioNTech) administered.',
      'attachments': ['Vaccination_Record.pdf'],
      'icon': Icons.vaccines,
      'color': AppTheme.secondaryLight,
      'hasDocuments': true,
      'notes': 'No adverse reactions reported. Next booster due in 6 months.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEvents {
    return _timelineEvents.where((event) {
      // Filter by type
      if (_selectedFilter != 'All' && event['type'] != _selectedFilter) {
        return false;
      }

      // Filter by date range
      if (_selectedDateRange != null) {
        final eventDate = event['date'] as DateTime;
        if (eventDate.isBefore(_selectedDateRange!.start) ||
            eventDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final title = (event['title'] as String).toLowerCase();
        final subtitle = (event['subtitle'] as String).toLowerCase();
        final description = (event['description'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) &&
            !subtitle.contains(query) &&
            !description.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Health Timeline',
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.timeline : Icons.analytics),
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportTimeline,
          ),
        ],
      ),
      body: Column(
        children: [
          TimelineFilterBar(
            selectedFilter: _selectedFilter,
            selectedDateRange: _selectedDateRange,
            selectedProvider: _selectedProvider,
            searchQuery: _searchQuery,
            eventTypes: _eventTypes,
            providers: _providers,
            onFilterChanged: (filter) =>
                setState(() => _selectedFilter = filter),
            onDateRangeChanged: (range) =>
                setState(() => _selectedDateRange = range),
            onProviderChanged: (provider) =>
                setState(() => _selectedProvider = provider),
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onClearFilters: _clearAllFilters,
          ),
          if (_showChart)
            Container(
              height: 30.h,
              margin: EdgeInsets.all(4.w),
              child: const HealthTrendsChart(),
            ),
          Expanded(
            child: _buildTimelineContent(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        onTap: (index) {
          // Handle bottom navigation
        },
      ),
      floatingActionButton: AddEventFab(
        onPressed: _showAddEventDialog,
      ),
    );
  }

  Widget _buildTimelineContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    final filteredEvents = _filteredEvents;

    if (filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshTimeline,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: filteredEvents.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredEvents.length) {
            return SizedBox(height: 10.h); // Space for FAB
          }

          final event = filteredEvents[index];
          final isLast = index == filteredEvents.length - 1;
          final eventDate = event['date'] as DateTime;

          // Show year marker if this is first event of year
          bool showYearMarker = false;
          if (index == 0 ||
              (index > 0 &&
                  (filteredEvents[index - 1]['date'] as DateTime).year !=
                      eventDate.year)) {
            showYearMarker = true;
          }

          return Column(
            children: [
              if (showYearMarker) YearMarkerWidget(year: eventDate.year),
              TimelineEventCard(
                event: event,
                isLast: isLast,
                onTap: () => _showEventDetails(event),
                onLongPress: () => _showEventOptions(event),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.primary.withAlpha(26),
            ),
            child: Icon(
              Icons.timeline,
              size: 15.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Timeline Events',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your health timeline will appear here.\nStart by adding your first medical event.',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTimeline() async {
    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Timeline updated successfully'),
          backgroundColor: AppTheme.successLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = 'All';
      _selectedDateRange = null;
      _selectedProvider = 'All Providers';
      _searchQuery = '';
      _selectedEventTypes.clear();
    });
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEventDetailSheet(event),
    );
  }

  void _showEventOptions(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildEventOptionsSheet(event),
    );
  }

  Widget _buildEventDetailSheet(Map<String, dynamic> event) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: (event['color'] as Color).withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          event['icon'] as IconData,
                          color: event['color'] as Color,
                          size: 6.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: AppTheme.lightTheme.textTheme.titleLarge,
                            ),
                            Text(
                              event['subtitle'] as String,
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  _buildDetailRow(
                      'Date', _formatEventDate(event['date'] as DateTime)),
                  _buildDetailRow('Type', event['type'] as String),
                  _buildDetailRow(
                      'Description', event['description'] as String),
                  if (event['notes'] != null &&
                      (event['notes'] as String).isNotEmpty)
                    _buildDetailRow('Notes', event['notes'] as String),
                  if (event['attachments'] != null &&
                      (event['attachments'] as List).isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Attachments',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...(event['attachments'] as List<String>).map(
                      (attachment) => ListTile(
                        leading: Icon(
                          Icons.insert_drive_file,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        title: Text(attachment),
                        trailing: Icon(Icons.download, size: 5.w),
                        onTap: () => _downloadAttachment(attachment),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventOptionsSheet(Map<String, dynamic> event) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Event'),
            onTap: () {
              Navigator.pop(context);
              _editEvent(event);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Event'),
            onTap: () {
              Navigator.pop(context);
              _shareEvent(event);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: AppTheme.errorLight),
            title: Text('Delete Event',
                style: TextStyle(color: AppTheme.errorLight)),
            onTap: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddEventDialog() {
    // Implementation for add event dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Event dialog will be implemented'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportTimeline() {
    // Implementation for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timeline export functionality will be implemented'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadAttachment(String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $filename...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editEvent(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${event['title']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareEvent(Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share ${event['title']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timelineEvents.removeWhere((e) => e['id'] == event['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${event['title']} deleted'),
                  backgroundColor: AppTheme.errorLight,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.errorLight)),
          ),
        ],
      ),
    );
  }
}
