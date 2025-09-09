import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MedicationAdherenceCard extends StatelessWidget {
  const MedicationAdherenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> medications = [
      {
        "id": 1,
        "name": "Lisinopril",
        "dosage": "10mg",
        "frequency": "Once daily",
        "taken": 6,
        "total": 7,
        "nextDose": "8:00 AM",
        "color": AppTheme.lightTheme.colorScheme.primary,
      },
      {
        "id": 2,
        "name": "Metformin",
        "dosage": "500mg",
        "frequency": "Twice daily",
        "taken": 12,
        "total": 14,
        "nextDose": "6:00 PM",
        "color": AppTheme.successLight,
      },
      {
        "id": 3,
        "name": "Vitamin D3",
        "dosage": "1000 IU",
        "frequency": "Once daily",
        "taken": 5,
        "total": 7,
        "nextDose": "9:00 AM",
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
                'Medication Adherence',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '85% This Week',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ...medications
              .map((medication) => _buildMedicationItem(context, medication))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(
      BuildContext context, Map<String, dynamic> medication) {
    final double progress =
        (medication["taken"] as int) / (medication["total"] as int);
    final Color medicationColor = medication["color"] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${medication["name"]} ${medication["dosage"]}',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      medication["frequency"] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${medication["taken"]}/${medication["total"]}',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: medicationColor,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Next: ${medication["nextDose"]}',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            height: 0.8.h,
            decoration: BoxDecoration(
              color: medicationColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: medicationColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
