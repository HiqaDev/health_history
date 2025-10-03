import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TimelineEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TimelineEventCard({
    super.key,
    required this.event,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final eventDate = event['date'] as DateTime;
    final hasDocuments = event['hasDocuments'] as bool;
    final attachmentsCount = (event['attachments'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(bottom: 3.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    color: event['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (event['color'] as Color).withAlpha(77),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 1.5.w,
                      height: 1.5.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 0.5.w,
                    height: 15.h,
                    margin: EdgeInsets.symmetric(vertical: 1.h),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 4.w),
            // Event card
            Expanded(
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        AppTheme.lightTheme.colorScheme.outline.withAlpha(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon and date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: (event['color'] as Color).withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            event['icon'] as IconData,
                            color: event['color'] as Color,
                            size: 5.w,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'] as String,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatEventDate(eventDate),
                                style: AppTheme.lightTheme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildEventTypeChip(),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    // Subtitle
                    Text(
                      event['subtitle'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Description
                    Text(
                      event['description'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasDocuments) ...[
                      SizedBox(height: 2.h),
                      // Attachments indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 3.w,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '$attachmentsCount document${attachmentsCount != 1 ? 's' : ''}',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Notes preview
                    if (event['notes'] != null &&
                        (event['notes'] as String).isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withAlpha(51),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 3.w,
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withAlpha(153),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                event['notes'] as String,
                                style: AppTheme.lightTheme.textTheme.labelMedium
                                    ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withAlpha(179),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChip() {
    final eventType = event['type'] as String;
    Color chipColor;

    switch (eventType) {
      case 'Appointments':
        chipColor = AppTheme.primaryLight;
        break;
      case 'Medications':
        chipColor = AppTheme.successLight;
        break;
      case 'Lab Results':
        chipColor = AppTheme.warningLight;
        break;
      case 'Procedures':
        chipColor = AppTheme.accentLight;
        break;
      case 'Symptoms':
        chipColor = AppTheme.errorLight;
        break;
      case 'Vaccinations':
        chipColor = AppTheme.secondaryLight;
        break;
      default:
        chipColor = AppTheme.lightTheme.colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Text(
        eventType,
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
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
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks != 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
