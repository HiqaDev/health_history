import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/timeline_service.dart';
import '../../services/auth_service.dart';
import './widgets/add_event_fab.dart';
import './widgets/health_trends_chart.dart';
import './widgets/timeline_event_card.dart';
import './widgets/timeline_filter_bar.dart';
import './widgets/year_marker_widget.dart';
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
  final _timelineService = TimelineService();
  final _authService = AuthService();
  
  late ScrollController _scrollController;
  late AnimationController _animationController;

  bool _isLoading = true;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  String _selectedProvider = 'All Providers';
  String _searchQuery = '';
  bool _showChart = false;
  List<String> _selectedEventTypes = [];

  // Real timeline data
  List<Map<String, dynamic>> _allTimelineEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  Map<String, dynamic>? _statistics;
  
  // Dynamic filters based on actual data
  List<String> _eventTypes = ['All'];
  List<String> _providers = ['All Providers'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    try {
      setState(() => _isLoading = true);
      
      if (!_authService.isAuthenticated) return;
      
      final userId = _authService.currentUser!.id;
      
      // Load timeline data and statistics in parallel
      final results = await Future.wait([
        _timelineService.getCompleteTimeline(userId),
        _timelineService.getTimelineStatistics(userId),
      ]);
      
      final timelineEvents = results[0] as List<Map<String, dynamic>>;
      final statistics = results[1] as Map<String, dynamic>;
      
      // Extract unique event types and providers for filters
      Set<String> eventTypes = {'All'};
      Set<String> providers = {'All Providers'};
      
      for (final event in timelineEvents) {
        if (event['event_type'] != null) {
          eventTypes.add(_formatEventType(event['event_type']));
        }
        if (event['doctor_name'] != null) {
          providers.add(event['doctor_name']);
        }
        if (event['hospital_name'] != null) {
          providers.add(event['hospital_name']);
        }
      }
      
      setState(() {
        _allTimelineEvents = timelineEvents;
        _filteredEvents = timelineEvents;
        _statistics = statistics;
        _eventTypes = eventTypes.toList();
        _providers = providers.toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timeline: $error')),
        );
      }
    }
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'diagnosis':
        return 'Diagnosis';
      case 'treatment':
        return 'Treatment';
      case 'surgery':
        return 'Surgery';
      case 'test':
        return 'Tests';
      case 'vaccination':
        return 'Vaccinations';
      case 'hospital_visit':
        return 'Hospital Visit';
      case 'prescription':
        return 'Prescriptions';
      case 'symptom':
        return 'Symptoms';
      case 'appointment':
        return 'Appointments';
      case 'medication_start':
        return 'Medications';
      case 'health_metric':
        return 'Health Metrics';
      default:
        return eventType.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allTimelineEvents.where((event) {
        // Filter by type
        final eventTypeFormatted = _formatEventType(event['event_type'] ?? '');
        if (_selectedFilter != 'All' && eventTypeFormatted != _selectedFilter) {
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

        // Filter by provider
        if (_selectedProvider != 'All Providers') {
          final doctorName = event['doctor_name'] as String?;
          final hospitalName = event['hospital_name'] as String?;
          if (doctorName != _selectedProvider && hospitalName != _selectedProvider) {
            return false;
          }
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final title = (event['title'] as String? ?? '').toLowerCase();
          final description = (event['description'] as String? ?? '').toLowerCase();
          final tags = (event['tags'] as List<String>? ?? []).join(' ').toLowerCase();
          final query = _searchQuery.toLowerCase();

          if (!title.contains(query) &&
              !description.contains(query) &&
              !tags.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList()
        ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    });
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
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
              _applyFilters();
            },
            onDateRangeChanged: (range) {
              setState(() => _selectedDateRange = range);
              _applyFilters();
            },
            onProviderChanged: (provider) {
              setState(() => _selectedProvider = provider);
              _applyFilters();
            },
            onSearchChanged: (query) {
              setState(() => _searchQuery = query);
              _applyFilters();
            },
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
    await _loadTimelineData();

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
    _applyFilters();
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
                _allTimelineEvents.removeWhere((e) => e['id'] == event['id']);
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
