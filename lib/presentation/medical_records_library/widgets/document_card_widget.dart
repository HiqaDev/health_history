import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentCardWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveToFolder;
  final bool isSelected;
  final bool isMultiSelectMode;
  final ValueChanged<bool>? onSelectionChanged;

  const DocumentCardWidget({
    super.key,
    required this.document,
    this.onTap,
    this.onShare,
    this.onFavorite,
    this.onDelete,
    this.onMoveToFolder,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(document['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onShare?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (_) => onFavorite?.call(),
              backgroundColor: AppTheme.warningLight,
              foregroundColor: Colors.white,
              icon: (document['isFavorite'] as bool? ?? false)
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: 'Favorite',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (_) => onMoveToFolder?.call(),
              backgroundColor: AppTheme.successLight,
              foregroundColor: Colors.white,
              icon: Icons.folder,
              label: 'Move',
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showDeleteConfirmation(context),
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: isMultiSelectMode
              ? () => onSelectionChanged?.call(!isSelected)
              : onTap,
          onLongPress: () => onSelectionChanged?.call(!isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  if (isMultiSelectMode)
                    Container(
                      margin: EdgeInsets.only(right: 3.w),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            onSelectionChanged?.call(value ?? false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  _buildDocumentThumbnail(),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                document['title'] as String? ??
                                    'Untitled Document',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (document['isFavorite'] as bool? ?? false)
                              CustomIconWidget(
                                iconName: 'favorite',
                                color: AppTheme.warningLight,
                                size: 16,
                              ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: _getDocumentTypeIcon(),
                              color: _getDocumentTypeColor(),
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              document['type'] as String? ?? 'Document',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getDocumentTypeColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'calendar_today',
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              _formatDate(document['date'] as String? ?? ''),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            if (document['provider'] != null) ...[
                              CustomIconWidget(
                                iconName: 'local_hospital',
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  document['provider'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (document['tags'] != null &&
                            (document['tags'] as List).isNotEmpty) ...[
                          SizedBox(height: 1.h),
                          Wrap(
                            spacing: 1.w,
                            runSpacing: 0.5.h,
                            children:
                                (document['tags'] as List).take(3).map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag as String,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (document['syncStatus'] != null) ...[
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: _getSyncStatusIcon(),
                                color: _getSyncStatusColor(),
                                size: 12,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                _getSyncStatusText(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getSyncStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (document['size'] != null)
                        Text(
                          _formatFileSize(document['size'] as int? ?? 0),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      SizedBox(height: 1.h),
                      CustomIconWidget(
                        iconName: 'chevron_right',
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail() {
    final documentType = document['type'] as String? ?? 'document';

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: _getDocumentTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: document['thumbnailUrl'] != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImageWidget(
                imageUrl: document['thumbnailUrl'] as String,
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: CustomIconWidget(
                iconName: _getDocumentTypeIcon(),
                color: _getDocumentTypeColor(),
                size: 24,
              ),
            ),
    );
  }

  String _getDocumentTypeIcon() {
    final type = document['type'] as String? ?? 'document';
    switch (type.toLowerCase()) {
      case 'prescription':
        return 'medication';
      case 'lab report':
        return 'science';
      case 'imaging':
      case 'x-ray':
      case 'mri':
        return 'medical_services';
      case 'bill':
      case 'invoice':
        return 'receipt';
      case 'insurance':
        return 'shield';
      case 'vaccination':
        return 'vaccines';
      default:
        return 'description';
    }
  }

  Color _getDocumentTypeColor() {
    final type = document['type'] as String? ?? 'document';
    switch (type.toLowerCase()) {
      case 'prescription':
        return AppTheme.primaryLight;
      case 'lab report':
        return AppTheme.successLight;
      case 'imaging':
      case 'x-ray':
      case 'mri':
        return AppTheme.secondaryLight;
      case 'bill':
      case 'invoice':
        return AppTheme.warningLight;
      case 'insurance':
        return AppTheme.primaryVariantLight;
      case 'vaccination':
        return AppTheme.accentLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  String _getSyncStatusIcon() {
    final status = document['syncStatus'] as String? ?? 'synced';
    switch (status) {
      case 'syncing':
        return 'sync';
      case 'offline':
        return 'cloud_off';
      case 'error':
        return 'sync_problem';
      default:
        return 'cloud_done';
    }
  }

  Color _getSyncStatusColor() {
    final status = document['syncStatus'] as String? ?? 'synced';
    switch (status) {
      case 'syncing':
        return AppTheme.warningLight;
      case 'offline':
        return AppTheme.textSecondaryLight;
      case 'error':
        return AppTheme.errorLight;
      default:
        return AppTheme.successLight;
    }
  }

  String _getSyncStatusText() {
    final status = document['syncStatus'] as String? ?? 'synced';
    switch (status) {
      case 'syncing':
        return 'Syncing...';
      case 'offline':
        return 'Offline';
      case 'error':
        return 'Sync Error';
      default:
        return 'Synced';
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
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
    } catch (e) {
      return dateString;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.errorLight,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('Delete Document'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${document['title']}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}