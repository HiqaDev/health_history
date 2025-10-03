import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../services/secure_sharing_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';

class SecureSharingScreen extends StatefulWidget {
  const SecureSharingScreen({Key? key}) : super(key: key);

  @override
  State<SecureSharingScreen> createState() => _SecureSharingScreenState();
}

class _SecureSharingScreenState extends State<SecureSharingScreen>
    with TickerProviderStateMixin {
  final SecureSharingService _sharingService = SecureSharingService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  List<Map<String, dynamic>> _myShares = [];
  List<Map<String, dynamic>> _sharedWithMe = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _sharingService.getMyShares(),
        _sharingService.getSharedWithMe(),
        _sharingService.getSharingStats(),
      ]);

      setState(() {
        _myShares = results[0] as List<Map<String, dynamic>>;
        _sharedWithMe = results[1] as List<Map<String, dynamic>>;
        _stats = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load sharing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Secure Sharing',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showCreateShareDialog,
            tooltip: 'Create New Share',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMySharesTab(),
                      _buildSharedWithMeTab(),
                      _buildAccessSharedTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Shares',
              _stats['totalShares']?.toString() ?? '0',
              Icons.share_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Active Shares',
              _stats['activeShares']?.toString() ?? '0',
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Access',
              _stats['totalAccess']?.toString() ?? '0',
              Icons.visibility_outlined,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        tabs: const [
          Tab(text: 'My Shares'),
          Tab(text: 'Shared with Me'),
          Tab(text: 'Access Share'),
        ],
      ),
    );
  }

  Widget _buildMySharesTab() {
    if (_myShares.isEmpty) {
      return _buildEmptyState(
        'No Shares Yet',
        'Create your first secure share to share medical records with doctors, family, or insurance providers.',
        Icons.share_outlined,
        _showCreateShareDialog,
        'Create Share',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myShares.length,
        itemBuilder: (context, index) {
          final share = _myShares[index];
          return _buildShareCard(share, isOwner: true);
        },
      ),
    );
  }

  Widget _buildSharedWithMeTab() {
    if (_sharedWithMe.isEmpty) {
      return _buildEmptyState(
        'No Shared Items',
        'Items shared with you by others will appear here.',
        Icons.inbox_outlined,
        null,
        null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sharedWithMe.length,
        itemBuilder: (context, index) {
          final share = _sharedWithMe[index];
          return _buildShareCard(share, isOwner: false);
        },
      ),
    );
  }

  Widget _buildAccessSharedTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppTheme.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan a QR code shared by someone to access their medical records.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scanQRCode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, color: AppTheme.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Access Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter an 8-character access code to view shared medical records.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onFieldSubmitted: (code) => _accessWithCode(code),
                    decoration: InputDecoration(
                      hintText: 'Enter access code (e.g., ABC12345)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          // Get text from field and access
                        },
                      ),
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

  Widget _buildShareCard(Map<String, dynamic> share, {required bool isOwner}) {
    final isExpired = share['expires_at'] != null &&
        DateTime.parse(share['expires_at']).isBefore(DateTime.now());
    final isActive = share['is_active'] == true && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getResourceTypeColor(share['resource_type']),
                  child: Icon(
                    _getResourceTypeIcon(share['resource_type']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getResourceTypeTitle(share['resource_type']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isOwner
                            ? 'Shared with: ${share['share_with_email']}'
                            : 'Shared by: ${share['shared_by_profile']?['full_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isActive, isExpired),
              ],
            ),
            if (share['message'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  share['message'],
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(share['created_at'])}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (share['expires_at'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${_formatDate(share['expires_at'])}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            if (isOwner && share['access_count'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Accessed ${share['access_count']} times',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (isOwner) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showShareDetails(share),
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('QR Code'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareLink(share),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showShareOptions(share),
                    icon: const Icon(Icons.more_vert),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isActive
                          ? () => _accessSharedResource(share['access_code'])
                          : null,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, bool isExpired) {
    Color color;
    String label;
    IconData icon;

    if (isExpired) {
      color = Colors.red;
      label = 'Expired';
      icon = Icons.access_time_filled;
    } else if (isActive) {
      color = Colors.green;
      label = 'Active';
      icon = Icons.check_circle;
    } else {
      color = Colors.orange;
      label = 'Inactive';
      icon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String message,
    IconData icon,
    VoidCallback? onAction,
    String? actionLabel,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods for resource types
  Color _getResourceTypeColor(String resourceType) {
    switch (resourceType) {
      case 'medical_document':
        return Colors.blue;
      case 'health_event':
        return Colors.green;
      case 'medication':
        return Colors.orange;
      case 'timeline_event':
        return Colors.purple;
      case 'doctor_note':
        return Colors.teal;
      case 'health_summary':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceTypeIcon(String resourceType) {
    switch (resourceType) {
      case 'medical_document':
        return Icons.description;
      case 'health_event':
        return Icons.event_note;
      case 'medication':
        return Icons.medication;
      case 'timeline_event':
        return Icons.timeline;
      case 'doctor_note':
        return Icons.note_alt;
      case 'health_summary':
        return Icons.summarize;
      default:
        return Icons.share;
    }
  }

  String _getResourceTypeTitle(String resourceType) {
    switch (resourceType) {
      case 'medical_document':
        return 'Medical Document';
      case 'health_event':
        return 'Health Event';
      case 'medication':
        return 'Medication';
      case 'timeline_event':
        return 'Timeline Event';
      case 'doctor_note':
        return 'Doctor Note';
      case 'health_summary':
        return 'Health Summary';
      default:
        return 'Shared Item';
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  void _showCreateShareDialog() {
    // TODO: Implement create share dialog
    _showError('Create share feature will be implemented in the next update');
  }

  void _showShareDetails(Map<String, dynamic> share) {
    // TODO: Implement share details dialog
    _showError('Share details feature will be implemented in the next update');
  }

  void _shareLink(Map<String, dynamic> share) {
    final shareLink = 'https://healthhistory.app/share/${share['access_code']}';
    Share.share(
      'Access my medical records securely: $shareLink\n\nAccess Code: ${share['access_code']}\n\nThis link will ${share['expires_at'] != null ? 'expire on ${_formatDate(share['expires_at'])}' : 'never expire'}.',
      subject: 'Secure Health Records Access',
    );
  }

  void _showShareOptions(Map<String, dynamic> share) {
    // TODO: Implement share options bottom sheet
    _showError('Share options feature will be implemented in the next update');
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning
    _showError('QR Code scanning will be implemented in the next update');
  }

  void _accessWithCode(String code) async {
    if (code.trim().isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _sharingService.accessSharedResource(code.trim().toUpperCase());
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // TODO: Show shared resource viewer
      _showError('Resource viewing will be implemented in the next update');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showError('Failed to access shared resource: $e');
    }
  }

  void _accessSharedResource(String accessCode) {
    _accessWithCode(accessCode);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}