import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentActivityTimeline extends StatefulWidget {
  const RecentActivityTimeline({super.key});

  @override
  State<RecentActivityTimeline> createState() => _RecentActivityTimelineState();
}

class _RecentActivityTimelineState extends State<RecentActivityTimeline> {
  final List<int> expandedItems = [];

  final List<Map<String, dynamic>> activities = [
    {
      "id": 1,
      "title": "Blood Test Completed",
      "description": "Complete blood count and lipid panel results available",
      "details":
          "Results show normal white blood cell count (7,200/μL), hemoglobin levels within normal range (14.2 g/dL), and cholesterol levels slightly elevated (210 mg/dL). Follow-up recommended in 3 months.",
      "date": "2025-01-08",
      "time": "10:30 AM",
      "type": "lab",
      "icon": "science",
      "color": AppTheme.lightTheme.colorScheme.primary,
      "doctor": "Dr. Sarah Johnson",
      "location": "City Medical Center",
    },
    {
      "id": 2,
      "title": "Medication Taken",
      "description": "Lisinopril 10mg - Morning dose",
      "details":
          "Blood pressure medication taken as prescribed. Current adherence rate: 95% this week. Next dose scheduled for tomorrow at 8:00 AM.",
      "date": "2025-01-08",
      "time": "8:00 AM",
      "type": "medication",
      "icon": "local_pharmacy",
      "color": AppTheme.successLight,
    },
    {
      "id": 3,
      "title": "Vitals Recorded",
      "description": "Blood pressure: 118/78 mmHg, Weight: 74.5 kg",
      "details":
          "Blood pressure reading shows improvement from last week (122/82 mmHg). Weight decreased by 0.3 kg since last measurement. Continue current medication and lifestyle modifications.",
      "date": "2025-01-07",
      "time": "7:45 AM",
      "type": "vitals",
      "icon": "monitor_heart",
      "color": AppTheme.warningLight,
    },
    {
      "id": 4,
      "title": "Appointment Scheduled",
      "description": "Follow-up with Dr. Michael Chen - Dermatology",
      "details":
          "Routine skin examination scheduled for January 15th at 2:15 PM. Please arrive 15 minutes early for check-in. Bring list of current medications and any skin concerns.",
      "date": "2025-01-05",
      "time": "2:30 PM",
      "type": "appointment",
      "icon": "event",
      "color": AppTheme.lightTheme.colorScheme.secondary,
      "doctor": "Dr. Michael Chen",
      "location": "Wellness Clinic",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/medical-records-library'),
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return _buildTimelineItem(
                context, activity, index, index == activities.length - 1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Map<String, dynamic> activity,
      int index, bool isLast) {
    final Color activityColor = activity["color"] as Color;
    final bool isExpanded = expandedItems.contains(activity["id"]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: activityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activityColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: activity["icon"] as String,
                  color: activityColor,
                  size: 5.w,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 8.h,
                margin: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedItems.remove(activity["id"]);
                } else {
                  expandedItems.add(activity["id"] as int);
                }
              });
            },
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: activityColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activityColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity["title"] as String,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${activity["date"]} ${activity["time"]}',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName:
                                isExpanded ? 'expand_less' : 'expand_more',
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                            size: 4.w,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    activity["description"] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  if (activity["doctor"] != null) ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'person',
                          color: activityColor,
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          activity["doctor"] as String,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: activityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activity["location"] != null) ...[
                          Text(
                            ' • ${activity["location"]}',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (isExpanded) ...[
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        activity["details"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
