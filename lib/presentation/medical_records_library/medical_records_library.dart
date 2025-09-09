import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/advanced_filter_modal.dart';
import './widgets/document_card_widget.dart';
import './widgets/document_upload_fab.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/search_bar_widget.dart';
import 'widgets/advanced_filter_modal.dart';
import 'widgets/document_card_widget.dart';
import 'widgets/document_upload_fab.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/filter_chips_widget.dart';
import 'widgets/search_bar_widget.dart';

class MedicalRecordsLibrary extends StatefulWidget {
  const MedicalRecordsLibrary({super.key});

  @override
  State<MedicalRecordsLibrary> createState() => _MedicalRecordsLibraryState();
}

class _MedicalRecordsLibraryState extends State<MedicalRecordsLibrary>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;

  String _searchQuery = '';
  List<String> _activeFilters = [];
  Map<String, dynamic> _advancedFilters = {};
  bool _isMultiSelectMode = false;
  Set<String> _selectedDocuments = {};
  bool _isFabVisible = true;

  // Mock data for medical documents
  final List<Map<String, dynamic>> _allDocuments = [
    {
      'id': '1',
      'title': 'Blood Test Results - Complete Blood Count',
      'type': 'Lab Report',
      'date': '2025-01-05T10:30:00.000Z',
      'provider': 'City General Hospital',
      'size': 2048576,
      'thumbnailUrl':
          'https://images.pexels.com/photos/4386467/pexels-photo-4386467.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isFavorite': true,
      'tags': ['Blood Work', 'Routine', 'Annual Checkup'],
      'syncStatus': 'synced',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '2',
      'title': 'Prescription - Hypertension Medication',
      'type': 'Prescription',
      'date': '2025-01-03T14:15:00.000Z',
      'provider': 'Dr. Sarah Johnson',
      'size': 512000,
      'isFavorite': false,
      'tags': ['Hypertension', 'Daily Medication'],
      'syncStatus': 'synced',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '3',
      'title': 'Chest X-Ray Report',
      'type': 'Imaging',
      'date': '2024-12-28T09:00:00.000Z',
      'provider': 'Metro Medical Center',
      'size': 8192000,
      'thumbnailUrl':
          'https://images.pexels.com/photos/7089020/pexels-photo-7089020.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isFavorite': false,
      'tags': ['Chest', 'Routine Screening'],
      'syncStatus': 'syncing',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '4',
      'title': 'Hospital Bill - Emergency Visit',
      'type': 'Bill',
      'date': '2024-12-20T16:45:00.000Z',
      'provider': 'Emergency Care Center',
      'size': 1024000,
      'isFavorite': false,
      'tags': ['Emergency', 'Insurance Claim'],
      'syncStatus': 'offline',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '5',
      'title': 'COVID-19 Vaccination Certificate',
      'type': 'Vaccination',
      'date': '2024-12-15T11:30:00.000Z',
      'provider': 'HealthCare Plus Clinic',
      'size': 256000,
      'isFavorite': true,
      'tags': ['COVID-19', 'Vaccination', 'Certificate'],
      'syncStatus': 'synced',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '6',
      'title': 'MRI Scan - Brain',
      'type': 'Imaging',
      'date': '2024-12-10T13:20:00.000Z',
      'provider': 'Advanced Diagnostics Lab',
      'size': 15728640,
      'thumbnailUrl':
          'https://images.pexels.com/photos/7089020/pexels-photo-7089020.jpeg?auto=compress&cs=tinysrgb&w=400',
      'isFavorite': false,
      'tags': ['Brain', 'MRI', 'Neurological'],
      'syncStatus': 'error',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
    {
      'id': '7',
      'title': 'Insurance Claim Form',
      'type': 'Insurance',
      'date': '2024-12-05T10:00:00.000Z',
      'provider': 'Wellness Medical Group',
      'size': 768000,
      'isFavorite': false,
      'tags': ['Insurance', 'Claim', 'Reimbursement'],
      'syncStatus': 'synced',
      'fileUrl':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    },
  ];

  List<Map<String, dynamic>> _filteredDocuments = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filteredDocuments = List.from(_allDocuments);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrollingDown = _scrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final shouldHideFab = isScrollingDown && _scrollController.offset > 100;

    if (shouldHideFab != !_isFabVisible) {
      setState(() {
        _isFabVisible = !shouldHideFab;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Medical Records',
        centerTitle: false,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onFilterTap: _showAdvancedFilters,
            filterCount: _getActiveFilterCount(),
            hintText: 'Search medical records...',
          ),
          FilterChipsWidget(
            activeFilters: _activeFilters,
            onFilterRemoved: _removeFilter,
            onClearAll: _clearAllFilters,
          ),
          if (_isMultiSelectMode) _buildMultiSelectHeader(context),
          Expanded(
            child: _filteredDocuments.isEmpty
                ? _buildEmptyState(context)
                : _buildDocumentsList(context),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: DocumentUploadFab(
            onDocumentUploaded: _onDocumentUploaded,
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildMultiSelectHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedDocuments.length} selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _shareSelectedDocuments,
            icon: CustomIconWidget(
              iconName: 'share',
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _deleteSelectedDocuments,
            icon: CustomIconWidget(
              iconName: 'delete',
              color: AppTheme.errorLight,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _exitMultiSelectMode,
            icon: CustomIconWidget(
              iconName: 'close',
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (_searchQuery.isNotEmpty || _activeFilters.isNotEmpty) {
      return EmptyStateWidget(
        title: 'No Documents Found',
        subtitle:
            'Try adjusting your search terms or filters to find what you\'re looking for.',
        actionText: 'Clear Filters',
        onActionPressed: () {
          setState(() {
            _searchQuery = '';
            _activeFilters.clear();
            _advancedFilters.clear();
            _applyFilters();
          });
        },
      );
    }

    return EmptyStateWidget(
      title: 'No Medical Records Yet',
      subtitle:
          'Start building your digital health vault by uploading your first medical document.',
      actionText: 'Upload Document',
      showTutorial: true,
      onActionPressed: () {
        // Trigger FAB action
      },
    );
  }

  Widget _buildDocumentsList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 20.h),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = _filteredDocuments[index];
        final isSelected = _selectedDocuments.contains(document['id']);

        return DocumentCardWidget(
          document: document,
          onTap: () => _onDocumentTap(document),
          onShare: () => _shareDocument(document),
          onFavorite: () => _toggleFavorite(document),
          onDelete: () => _deleteDocument(document),
          onMoveToFolder: () => _moveToFolder(document),
          isSelected: isSelected,
          isMultiSelectMode: _isMultiSelectMode,
          onSelectionChanged: (selected) =>
              _onDocumentSelectionChanged(document['id'], selected),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredDocuments = _allDocuments.where((document) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final titleMatch =
              (document['title'] as String).toLowerCase().contains(searchLower);
          final typeMatch =
              (document['type'] as String).toLowerCase().contains(searchLower);
          final providerMatch = (document['provider'] as String? ?? '')
              .toLowerCase()
              .contains(searchLower);
          final tagsMatch = (document['tags'] as List<String>? ?? [])
              .any((tag) => tag.toLowerCase().contains(searchLower));

          if (!titleMatch && !typeMatch && !providerMatch && !tagsMatch) {
            return false;
          }
        }

        // Active filters
        for (final filter in _activeFilters) {
          switch (filter.toLowerCase()) {
            case 'prescriptions':
              if (document['type'] != 'Prescription') return false;
              break;
            case 'lab reports':
              if (document['type'] != 'Lab Report') return false;
              break;
            case 'imaging':
              if (document['type'] != 'Imaging') return false;
              break;
            case 'bills':
              if (document['type'] != 'Bill') return false;
              break;
            case 'insurance':
              if (document['type'] != 'Insurance') return false;
              break;
            case 'vaccination':
              if (document['type'] != 'Vaccination') return false;
              break;
            case 'favorites':
              if (!(document['isFavorite'] as bool? ?? false)) return false;
              break;
          }
        }

        // Advanced filters
        if (_advancedFilters['documentTypes'] != null) {
          final types = _advancedFilters['documentTypes'] as List<String>;
          if (types.isNotEmpty && !types.contains(document['type'])) {
            return false;
          }
        }

        if (_advancedFilters['providers'] != null) {
          final providers = _advancedFilters['providers'] as List<String>;
          if (providers.isNotEmpty &&
              !providers.contains(document['provider'])) {
            return false;
          }
        }

        if (_advancedFilters['dateRange'] != null) {
          final range = _advancedFilters['dateRange'] as Map<String, String>;
          final docDate = DateTime.parse(document['date'] as String);
          final startDate = DateTime.parse(range['start']!);
          final endDate = DateTime.parse(range['end']!);

          if (docDate.isBefore(startDate) || docDate.isAfter(endDate)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      final sortBy = _advancedFilters['sortBy'] as String? ?? 'date_desc';
      _filteredDocuments.sort((a, b) {
        switch (sortBy) {
          case 'date_asc':
            return DateTime.parse(a['date'])
                .compareTo(DateTime.parse(b['date']));
          case 'name_asc':
            return (a['title'] as String).compareTo(b['title'] as String);
          case 'name_desc':
            return (b['title'] as String).compareTo(a['title'] as String);
          case 'type':
            return (a['type'] as String).compareTo(b['type'] as String);
          case 'provider':
            return (a['provider'] as String).compareTo(b['provider'] as String);
          default: // date_desc
            return DateTime.parse(b['date'])
                .compareTo(DateTime.parse(a['date']));
        }
      });
    });
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterModal(
        currentFilters: _advancedFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _advancedFilters = filters;
            _updateActiveFilters();
          });
          _applyFilters();
        },
      ),
    );
  }

  void _updateActiveFilters() {
    final newFilters = <String>[];

    if (_advancedFilters['documentTypes'] != null) {
      final types = _advancedFilters['documentTypes'] as List<String>;
      newFilters.addAll(types);
    }

    if (_advancedFilters['dateRange'] != null) {
      newFilters.add('Date Range');
    }

    setState(() {
      _activeFilters = newFilters;
    });
  }

  void _removeFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);

      // Remove from advanced filters
      if (_advancedFilters['documentTypes'] != null) {
        final types =
            (_advancedFilters['documentTypes'] as List<String>).toList();
        types.remove(filter);
        _advancedFilters['documentTypes'] = types;
      }
    });
    _applyFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
      _advancedFilters.clear();
    });
    _applyFilters();
  }

  int _getActiveFilterCount() {
    int count = _activeFilters.length;
    if (_advancedFilters['dateRange'] != null) count++;
    if (_advancedFilters['providers'] != null &&
        (_advancedFilters['providers'] as List).isNotEmpty) count++;
    if (_advancedFilters['customTags'] != null &&
        (_advancedFilters['customTags'] as List).isNotEmpty) count++;
    return count;
  }

  void _onDocumentTap(Map<String, dynamic> document) {
    if (_isMultiSelectMode) {
      _onDocumentSelectionChanged(
          document['id'], !_selectedDocuments.contains(document['id']));
    } else {
      _previewDocument(document);
    }
  }

  void _previewDocument(Map<String, dynamic> document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DocumentPreviewScreen(document: document),
      ),
    );
  }

  void _onDocumentSelectionChanged(String documentId, bool selected) {
    setState(() {
      if (selected) {
        _selectedDocuments.add(documentId);
        if (!_isMultiSelectMode) {
          _isMultiSelectMode = true;
        }
      } else {
        _selectedDocuments.remove(documentId);
        if (_selectedDocuments.isEmpty) {
          _isMultiSelectMode = false;
        }
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedDocuments.clear();
    });
  }

  void _shareDocument(Map<String, dynamic> document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${document['title']}'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  void _shareSelectedDocuments() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${_selectedDocuments.length} documents'),
        backgroundColor: AppTheme.successLight,
      ),
    );
    _exitMultiSelectMode();
  }

  void _toggleFavorite(Map<String, dynamic> document) {
    setState(() {
      document['isFavorite'] = !(document['isFavorite'] as bool? ?? false);
    });

    final isFavorite = document['isFavorite'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        backgroundColor:
            isFavorite ? AppTheme.successLight : AppTheme.textSecondaryLight,
      ),
    );
  }

  void _deleteDocument(Map<String, dynamic> document) {
    setState(() {
      _allDocuments.removeWhere((doc) => doc['id'] == document['id']);
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted: ${document['title']}'),
        backgroundColor: AppTheme.errorLight,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _allDocuments.add(document);
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  void _deleteSelectedDocuments() {
    final count = _selectedDocuments.length;
    setState(() {
      _allDocuments
          .removeWhere((doc) => _selectedDocuments.contains(doc['id']));
      _applyFilters();
    });
    _exitMultiSelectMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted $count documents'),
        backgroundColor: AppTheme.errorLight,
      ),
    );
  }

  void _moveToFolder(Map<String, dynamic> document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Move to folder: ${document['title']}'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _onDocumentUploaded(Map<String, dynamic> document) {
    setState(() {
      _allDocuments.insert(0, document);
      _applyFilters();
    });
  }
}

class _DocumentPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentPreviewScreen({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: document['title'] as String,
        actions: [
          IconButton(
            onPressed: () => _shareDocument(context),
            icon: CustomIconWidget(
              iconName: 'share',
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => _downloadDocument(context),
            icon: CustomIconWidget(
              iconName: 'download',
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _getDocumentTypeIcon(document['type'] as String),
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['type'] as String,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        document['provider'] as String? ?? 'Unknown Provider',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(document['date'] as String),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: document['fileUrl'] != null
                ? SfPdfViewer.network(
                    document['fileUrl'] as String,
                    onDocumentLoadFailed: (details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to load document: ${details.error}'),
                          backgroundColor: AppTheme.errorLight,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'description',
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Document preview not available',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return 'medication';
      case 'lab report':
        return 'science';
      case 'imaging':
        return 'medical_services';
      case 'bill':
        return 'receipt';
      case 'insurance':
        return 'shield';
      case 'vaccination':
        return 'vaccines';
      default:
        return 'description';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _shareDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${document['title']}'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  void _downloadDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading: ${document['title']}'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }
}