import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DocumentGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final Function(Map<String, dynamic>) onDocumentTap;
  final Function(String) onDocumentDelete;

  const DocumentGridWidget({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    required this.onDocumentDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 3.w,
        childAspectRatio: 0.75,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return _buildDocumentCard(context, document);
      },
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, Map<String, dynamic> document) {
    return GestureDetector(
      onTap: () => onDocumentTap(document),
      onLongPress: () => _showDocumentOptions(context, document),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withAlpha(26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withAlpha(26),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getDocumentIcon(document['scanMode'] as String),
                      size: 12.w,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getScanModeColor(document['scanMode'] as String)
                            .withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _getScanModeColor(document['scanMode'] as String)
                                  .withAlpha(77),
                        ),
                      ),
                      child: Text(
                        (document['scanMode'] as String).toUpperCase(),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color:
                              _getScanModeColor(document['scanMode'] as String),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Document info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['title'] as String,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _formatDate(document['dateScanned'] as DateTime),
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withAlpha(153),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          document['fileSize'] as String,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withAlpha(153),
                          ),
                        ),
                        Icon(
                          document['source'] == 'camera'
                              ? Icons.camera_alt
                              : Icons.photo_library,
                          size: 3.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withAlpha(102),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String scanMode) {
    switch (scanMode) {
      case 'document':
        return Icons.description;
      case 'id':
        return Icons.credit_card;
      case 'prescription':
        return Icons.medical_services;
      default:
        return Icons.document_scanner;
    }
  }

  Color _getScanModeColor(String scanMode) {
    switch (scanMode) {
      case 'document':
        return AppTheme.primaryLight;
      case 'id':
        return AppTheme.secondaryLight;
      case 'prescription':
        return AppTheme.successLight;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  void _showDocumentOptions(
      BuildContext context, Map<String, dynamic> document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Document'),
              onTap: () {
                Navigator.pop(context);
                onDocumentTap(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument(context, document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameDocument(context, document);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.errorLight),
              title:
                  Text('Delete', style: TextStyle(color: AppTheme.errorLight)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, document);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareDocument(BuildContext context, Map<String, dynamic> document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${document['title']}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _renameDocument(BuildContext context, Map<String, dynamic> document) {
    final TextEditingController controller = TextEditingController(
      text: document['title'] as String,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Update document title in the actual implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document renamed successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content:
            Text('Are you sure you want to delete "${document['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDocumentDelete(document['id'] as String);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${document['title']} deleted'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
