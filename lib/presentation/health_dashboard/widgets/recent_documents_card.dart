import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentDocumentsCard extends StatelessWidget {
  const RecentDocumentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> documents = [
      {
        "id": 1,
        "title": "Blood Test Results",
        "type": "Lab Report",
        "date": "2025-01-08",
        "doctor": "Dr. Sarah Johnson",
        "hospital": "City Medical Center",
        "icon": "description",
        "color": AppTheme.lightTheme.colorScheme.primary,
      },
      {
        "id": 2,
        "title": "Chest X-Ray",
        "type": "Imaging",
        "date": "2025-01-05",
        "doctor": "Dr. Michael Chen",
        "hospital": "Wellness Clinic",
        "icon": "medical_services",
        "color": AppTheme.successLight,
      },
      {
        "id": 3,
        "title": "Prescription - Lisinopril",
        "type": "Prescription",
        "date": "2025-01-03",
        "doctor": "Dr. Sarah Johnson",
        "hospital": "City Medical Center",
        "icon": "local_pharmacy",
        "color": AppTheme.warningLight,
      },
    ];

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
                'Recent Documents',
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
          ...documents
              .map((document) => _buildDocumentItem(context, document))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      BuildContext context, Map<String, dynamic> document) {
    final Color documentColor = document["color"] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: documentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: documentColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: documentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: document["icon"] as String,
                color: documentColor,
                size: 6.w,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document["title"] as String,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  document["type"] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: documentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${document["doctor"]} • ${document["date"]}',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'arrow_forward_ios',
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.4),
            size: 4.w,
          ),
        ],
      ),
    );
  }
}
