import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/health_service.dart';
import '../../services/document_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class SecureSharing extends StatefulWidget {
  const SecureSharing({Key? key}) : super(key: key);

  @override
  State<SecureSharing> createState() => _SecureSharingState();
}

class _SecureSharingState extends State<SecureSharing> {
  final HealthService _healthService = HealthService();
  final DocumentService _documentService = DocumentService();
  List<Map<String, dynamic>> _sharedDocuments = [];
  List<Map<String, dynamic>> _shareRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharingData();
  }

  Future<void> _loadSharingData() async {
    try {
      setState(() => _isLoading = true);

      // Load shared documents
      _sharedDocuments = await _documentService.getSharedDocuments();

      // Load pending share requests
      _shareRequests = await _documentService.getShareRequests();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sharing data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const CustomAppBar(
        title: 'Secure Sharing',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Share Options
                  _buildQuickShareOptions(),
                  SizedBox(height: 24.sp),

                  // Active Shares
                  _buildActiveShares(),
                  SizedBox(height: 24.sp),

                  // Share Requests
                  _buildShareRequests(),
                  SizedBox(height: 24.sp),

                  // Sharing History
                  _buildSharingHistory(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showShareDialog,
        backgroundColor: AppTheme.primaryLight,
        icon: const Icon(Icons.share, color: Colors.white),
        label:
            const Text('Share Records', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildQuickShareOptions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Share',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            Row(
              children: [
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.local_hospital,
                    label: 'With Doctor',
                    color: AppTheme.primaryLight,
                    onTap: () => _shareWithDoctor(),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.family_restroom,
                    label: 'With Family',
                    color: AppTheme.secondaryLight,
                    onTap: () => _shareWithFamily(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Row(
              children: [
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.business,
                    label: 'Insurance',
                    color: AppTheme.warningLight,
                    onTap: () => _shareWithInsurance(),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    color: AppTheme.successLight,
                    onTap: () => _generateQRCode(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.sp),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShares() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Shares',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full list
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            if (_sharedDocuments.isEmpty)
              Text(
                'No active shares',
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 14.sp,
                ),
              )
            else
              ..._sharedDocuments
                  .take(3)
                  .map((share) => _buildShareItem(share)),
          ],
        ),
      ),
    );
  }

  Widget _buildShareItem(Map<String, dynamic> share) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.sp,
            backgroundColor: AppTheme.primaryLight,
            child: Icon(
              _getShareIcon(share['shared_with'] ?? ''),
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share['shared_with'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  '${share['document_count'] ?? 0} documents • ${share['permission'] ?? 'view'} access',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'revoke') {
                _revokeShare(share);
              } else if (value == 'modify') {
                _modifyShare(share);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'modify',
                child: Text('Modify Access'),
              ),
              const PopupMenuItem(
                value: 'revoke',
                child: Text('Revoke Access'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareRequests() {
    if (_shareRequests.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Requests',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            ..._shareRequests.map((request) => _buildRequestItem(request)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppTheme.warningLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: AppTheme.warningLight.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add,
                color: AppTheme.warningLight,
                size: 20.sp,
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  '${request['requester_name'] ?? 'Unknown'} wants access',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(
            request['message'] ?? 'No message provided',
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 12.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _denyRequest(request),
                child: Text('Deny'),
              ),
              SizedBox(width: 8.sp),
              ElevatedButton(
                onPressed: () => _approveRequest(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successLight,
                ),
                child: Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharingHistory() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            Text(
              'No recent sharing activity',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getShareIcon(String sharedWith) {
    if (sharedWith.toLowerCase().contains('doctor') ||
        sharedWith.toLowerCase().contains('dr')) {
      return Icons.medical_services;
    } else if (sharedWith.toLowerCase().contains('family') ||
        sharedWith.toLowerCase().contains('parent')) {
      return Icons.family_restroom;
    } else if (sharedWith.toLowerCase().contains('insurance')) {
      return Icons.business;
    }
    return Icons.person;
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Medical Records'),
        content: Text('Select documents and recipients to share with'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement sharing functionality
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }

  void _shareWithDoctor() {
    // TODO: Implement doctor sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor sharing feature coming soon')),
    );
  }

  void _shareWithFamily() {
    // TODO: Implement family sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family sharing feature coming soon')),
    );
  }

  void _shareWithInsurance() {
    // TODO: Implement insurance sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Insurance sharing feature coming soon')),
    );
  }

  void _generateQRCode() {
    // TODO: Implement QR code generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code generation feature coming soon')),
    );
  }

  void _revokeShare(Map<String, dynamic> share) {
    // TODO: Implement revoke functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share access revoked')),
    );
  }

  void _modifyShare(Map<String, dynamic> share) {
    // TODO: Implement modify functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modify share feature coming soon')),
    );
  }

  void _approveRequest(Map<String, dynamic> request) {
    // TODO: Implement approve functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share request approved')),
    );
  }

  void _denyRequest(Map<String, dynamic> request) {
    // TODO: Implement deny functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share request denied')),
    );
  }
}
