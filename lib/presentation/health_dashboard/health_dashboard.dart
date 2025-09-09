import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/emergency_card.dart';
import './widgets/health_metrics_card.dart';
import './widgets/health_trends_card.dart';
import './widgets/medication_adherence_card.dart';
import './widgets/quick_actions_fab.dart';
import './widgets/recent_activity_timeline.dart';
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
  bool _isLoading = false;
  DateTime _lastUpdated = DateTime.now();

  final Map<String, dynamic> userProfile = {
    "name": "John Anderson",
    "avatar":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
    "age": 45,
    "lastSync": "2 minutes ago",
  };

  final List<Map<String, dynamic>> healthMetrics = [
    {
      "title": "Blood Pressure",
      "value": "118",
      "unit": "/78 mmHg",
      "trend": "↓ 2%",
      "trendColor": AppTheme.successLight,
      "icon": Icons.monitor_heart,
    },
    {
      "title": "Weight",
      "value": "74.5",
      "unit": "kg",
      "trend": "↓ 0.3kg",
      "trendColor": AppTheme.successLight,
      "icon": Icons.scale,
    },
    {
      "title": "Blood Sugar",
      "value": "94",
      "unit": "mg/dL",
      "trend": "Normal",
      "trendColor": AppTheme.successLight,
      "icon": Icons.water_drop,
    },
    {
      "title": "Heart Rate",
      "value": "72",
      "unit": "bpm",
      "trend": "Resting",
      "trendColor": AppTheme.lightTheme.colorScheme.primary,
      "icon": Icons.favorite,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _lastUpdated = DateTime.now();
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Health History',
        showBackButton: false,
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
            const RecentActivityTimeline(),
            SizedBox(height: 10.h), // Space for FAB
          ],
        ),
      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(userProfile["avatar"] as String),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            userProfile["name"] as String,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Age: ${userProfile["age"]}',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
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
              image: DecorationImage(
                image: NetworkImage(userProfile["avatar"] as String),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
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
                  userProfile["name"] as String,
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
                      'Last sync: ${userProfile["lastSync"]}',
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