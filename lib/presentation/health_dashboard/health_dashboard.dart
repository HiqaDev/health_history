import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/health_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/emergency_card.dart';
import './widgets/health_metrics_card.dart';
import './widgets/health_trends_card.dart';
import './widgets/medication_adherence_card.dart';
import './widgets/quick_actions_fab.dart';
import './widgets/recent_documents_card.dart';
import './widgets/upcoming_appointments_card.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> healthMetrics = [];
  Map<String, dynamic> dashboardStats = {};
  List<Map<String, dynamic>> recentActivity = [];
  bool _isLoading = true;

  final _healthService = HealthService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!_authService.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/login-screen');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userId = _authService.currentUser!.id;

      // Load user profile
      userProfile = await _authService.getUserProfile();

      // Load health metrics
      final latestMetrics = await _healthService.getLatestMetricsByType(userId);
      healthMetrics = _formatHealthMetrics(latestMetrics);

      // Load dashboard stats
      dashboardStats = await _healthService.getDashboardStats(userId);

      // Load recent activity
      recentActivity = await _healthService.getRecentActivity(userId);

      setState(() => _isLoading = false);
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _formatHealthMetrics(
      List<Map<String, dynamic>> metrics) {
    List<Map<String, dynamic>> formattedMetrics = [];

    for (var metric in metrics) {
      String type = metric['metric_type'];
      IconData icon;
      String title;
      String unit = metric['unit'];
      String value = metric['value'].toString();

      switch (type) {
        case 'blood_pressure':
          icon = Icons.monitor_heart;
          title = 'Blood Pressure';
          // Handle systolic/diastolic formatting
          if (unit.contains('systolic')) {
            title = 'Blood Pressure (Systolic)';
          } else if (unit.contains('diastolic')) {
            title = 'Blood Pressure (Diastolic)';
          }
          break;
        case 'weight':
          icon = Icons.scale;
          title = 'Weight';
          break;
        case 'blood_sugar':
          icon = Icons.water_drop;
          title = 'Blood Sugar';
          break;
        case 'heart_rate':
          icon = Icons.favorite;
          title = 'Heart Rate';
          break;
        case 'temperature':
          icon = Icons.thermostat;
          title = 'Temperature';
          break;
        default:
          icon = Icons.trending_up;
          title = type.replaceAll('_', ' ').toUpperCase();
      }

      formattedMetrics.add({
        'title': title,
        'value': value,
        'unit': unit,
        'trend': 'Normal',
        'trendColor': AppTheme.successLight,
        'icon': icon,
      });
    }

    return formattedMetrics;
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Health data synced successfully'),
          backgroundColor: AppTheme.successLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login-screen',
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Health History',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildRecordsTab(),
                _buildRemindersTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle bottom navigation
        },
      ),
      floatingActionButton:
          _tabController.index == 0 ? const QuickActionsFab() : null,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Records'),
          Tab(text: 'Reminders'),
          Tab(text: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingHeader(),
            SizedBox(height: 3.h),
            const EmergencyCard(),
            SizedBox(height: 3.h),
            _buildHealthMetricsGrid(),
            SizedBox(height: 3.h),
            const UpcomingAppointmentsCard(),
            SizedBox(height: 3.h),
            const MedicationAdherenceCard(),
            SizedBox(height: 3.h),
            const HealthTrendsCard(),
            SizedBox(height: 3.h),
            const RecentDocumentsCard(),
            SizedBox(height: 3.h),
            _buildRecentActivityWidget(),
            SizedBox(height: 10.h), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        if (recentActivity.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'No recent activity',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          ...recentActivity.map((activity) {
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: activity['icon'],
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'],
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (activity['description'].isNotEmpty)
                          Text(
                            activity['description'],
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRecordsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'folder_open',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Medical Records',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Access your complete medical history',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/medical-records-library'),
            child: const Text('View All Records'),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'notifications_active',
            color: AppTheme.warningLight,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Medication Reminders',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Never miss your medications',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminders feature coming soon')),
              );
            },
            child: const Text('Set Reminders'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: userProfile!['profile_picture_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(userProfile!['profile_picture_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: userProfile!['profile_picture_url'] == null
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : null,
            ),
            child: userProfile!['profile_picture_url'] == null
                ? Icon(
                    Icons.person,
                    size: 12.w,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  )
                : null,
          ),
          SizedBox(height: 2.h),
          Text(
            userProfile!['full_name'] ?? 'User',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          if (userProfile!['date_of_birth'] != null)
            Text(
              'Age: ${_calculateAge(DateTime.parse(userProfile!['date_of_birth']))}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          SizedBox(height: 1.h),
          Text(
            'Role: ${userProfile!['role']?.toString().toUpperCase() ?? 'PATIENT'}',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/user-registration'),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: userProfile?['profile_picture_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(userProfile!['profile_picture_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: userProfile?['profile_picture_url'] == null
                  ? Colors.white.withValues(alpha: 0.2)
                  : null,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: userProfile?['profile_picture_url'] == null
                ? Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 8.w,
                  )
                : null,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  userProfile?['full_name'] ?? 'User',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'sync',
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Last sync: ${_formatLastSync()}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'emergency',
              color: Colors.white,
              size: 6.w,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync() {
    final now = DateTime.now();
    final lastSync = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildHealthMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Metrics',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 2.h),
        if (healthMetrics.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'trending_up',
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.5),
                  size: 12.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No Health Metrics',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Start tracking your health by adding your first metric',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 3.w,
            runSpacing: 2.h,
            children: healthMetrics.map((metric) {
              return HealthMetricsCard(
                title: metric["title"] as String,
                value: metric["value"] as String,
                unit: metric["unit"] as String,
                trend: metric["trend"] as String,
                trendColor: metric["trendColor"] as Color,
                icon: metric["icon"] as IconData,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${metric["title"]} details'),
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}