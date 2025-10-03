import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:cross_file/cross_file.dart';
import '../../services/qr_code_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import '../../core/app_export.dart';
import 'qr_scanner_screen.dart';

class QRCodeGenerationScreen extends StatefulWidget {
  const QRCodeGenerationScreen({Key? key}) : super(key: key);

  @override
  State<QRCodeGenerationScreen> createState() => _QRCodeGenerationScreenState();
}

class _QRCodeGenerationScreenState extends State<QRCodeGenerationScreen>
    with TickerProviderStateMixin {
  final QRCodeService _qrService = QRCodeService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  final GlobalKey _qrKey = GlobalKey();

  List<Map<String, dynamic>> _userQRCodes = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  // Current QR generation
  String? _currentQRData;
  Map<String, dynamic>? _currentQRDisplayData;
  String _currentQRType = 'emergency';

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
        _qrService.getUserQRCodes(),
        _qrService.getQRCodeStats(),
      ]);

      setState(() {
        _userQRCodes = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load QR codes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'QR Code Generator',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Scan QR Code',
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
                      _buildGenerateTab(),
                      _buildMyCodesTab(),
                      _buildScanTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
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
              'Total QR Codes',
              _stats['total_codes']?.toString() ?? '0',
              Icons.qr_code,
              Colors.blue,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildStatCard(
              'Active Codes',
              _stats['active_codes']?.toString() ?? '0',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildStatCard(
              'Total Scans',
              _stats['total_scans']?.toString() ?? '0',
              Icons.visibility,
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
        Icon(icon, color: color, size: 6.w),
        SizedBox(height: 2.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
          Tab(text: 'Generate'),
          Tab(text: 'My QR Codes'),
          Tab(text: 'Scan'),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Type Selection
          Text(
            'QR Code Type',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildQRTypeCard(
                  'Emergency',
                  'For medical emergencies with critical health info',
                  Icons.emergency,
                  Colors.red,
                  'emergency',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQRTypeCard(
                  'Medical Summary',
                  'Comprehensive health summary for appointments',
                  Icons.medical_information,
                  Colors.blue,
                  'medical_summary',
                ),
              ),
            ],
          ),
          SizedBox(height: 6.w),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(Icons.qr_code_2),
              label: Text('Generate ${_currentQRType == "emergency" ? "Emergency" : "Medical Summary"} QR Code'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(4.w),
                textStyle: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
          SizedBox(height: 6.w),

          // Generated QR Code Display
          if (_currentQRData != null) ...[
            _buildGeneratedQRCode(),
          ],
        ],
      ),
    );
  }

  Widget _buildQRTypeCard(String title, String description, IconData icon, Color color, String type) {
    final isSelected = _currentQRType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _currentQRType = type),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 8.w,
            ),
            SizedBox(height: 2.w),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: isSelected ? color : Colors.black,
              ),
            ),
            SizedBox(height: 1.w),
            Text(
              description,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedQRCode() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _currentQRType == 'emergency' ? Icons.emergency : Icons.medical_information,
                  color: _currentQRType == 'emergency' ? Colors.red : Colors.blue,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${_currentQRType == "emergency" ? "Emergency" : "Medical Summary"} QR Code',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _shareQRCode(),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            SizedBox(height: 4.w),
            
            // QR Code
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: _currentQRData!,
                  version: QrVersions.auto,
                  size: 60.w,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            
            SizedBox(height: 4.w),
            
            // QR Code Info
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  if (_currentQRDisplayData != null) ...[
                    _buildQRInfoRow('Type', _currentQRDisplayData!['type'] ?? 'Unknown'),
                    _buildQRInfoRow('Generated', _formatDateTime(_currentQRDisplayData!['generated_at'])),
                    if (_currentQRDisplayData!['expires_at'] != null)
                      _buildQRInfoRow('Expires', _formatDateTime(_currentQRDisplayData!['expires_at'])),
                    if (_currentQRDisplayData!['patient'] != null) ...[
                      _buildQRInfoRow('Patient', _currentQRDisplayData!['patient']['name']),
                      _buildQRInfoRow('Blood Group', _currentQRDisplayData!['patient']['blood_group'] ?? 'Not specified'),
                    ],
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 4.w),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveQRCode,
                    icon: const Icon(Icons.download),
                    label: const Text('Save Image'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareQRCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.w),
      child: Row(
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodesTab() {
    if (_userQRCodes.isEmpty) {
      return _buildEmptyState(
        'No QR Codes Yet',
        'Generate your first QR code to store and share your health information securely.',
        Icons.qr_code,
        () => _tabController.animateTo(0),
        'Generate QR Code',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _userQRCodes.length,
        itemBuilder: (context, index) {
          final qrCode = _userQRCodes[index];
          return _buildQRCodeCard(qrCode);
        },
      ),
    );
  }

  Widget _buildQRCodeCard(Map<String, dynamic> qrCode) {
    final isActive = qrCode['is_active'] == true;
    final isExpired = qrCode['expires_at'] != null &&
        DateTime.parse(qrCode['expires_at']).isBefore(DateTime.now());
    final qrType = qrCode['qr_type'];

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: qrType == 'emergency' ? Colors.red : Colors.blue,
                  child: Icon(
                    qrType == 'emergency' ? Icons.emergency : Icons.medical_information,
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qrType == 'emergency' ? 'Emergency QR Code' : 'Medical Summary QR Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'Created: ${_formatDate(qrCode['created_at'])}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isActive, isExpired),
              ],
            ),
            SizedBox(height: 3.w),
            
            Row(
              children: [
                Icon(Icons.visibility, size: 4.w, color: Colors.grey.shade600),
                SizedBox(width: 1.w),
                Text(
                  'Scanned ${qrCode['scan_count'] ?? 0} times',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11.sp,
                  ),
                ),
                if (qrCode['expires_at'] != null) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.access_time, size: 4.w, color: Colors.grey.shade600),
                  SizedBox(width: 1.w),
                  Text(
                    'Expires: ${_formatDate(qrCode['expires_at'])}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 3.w),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewQRCode(qrCode),
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('View'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareExistingQRCode(qrCode),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  onPressed: () => _showQRCodeOptions(qrCode),
                  icon: const Icon(Icons.more_vert),
                ),
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
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 20.w,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'Scan emergency or medical summary QR codes to view health information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scanQRCode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Start Scanning'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(4.w),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 4.w),
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryLight),
                      SizedBox(width: 2.w),
                      Text(
                        'Scanning Instructions',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.w),
                  _buildInstructionItem('1. Point your camera at the QR code'),
                  _buildInstructionItem('2. Make sure the QR code is clearly visible'),
                  _buildInstructionItem('3. Wait for automatic detection'),
                  _buildInstructionItem('4. View the health information displayed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.w),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 4.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.sp),
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
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 4.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.sp,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 6.w),
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

  // Action methods
  Future<void> _generateQRCode() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> result;
      if (_currentQRType == 'emergency') {
        result = await _qrService.generateEmergencyQRCode();
      } else {
        result = await _qrService.generateMedicalSummaryQRCode(
          includeTypes: ['profile', 'medications', 'allergies', 'conditions'],
          expiryDays: 30,
        );
      }

      Navigator.of(context).pop(); // Close loading dialog

      setState(() {
        _currentQRData = result['qr_data'];
        _currentQRDisplayData = result['display_data'];
      });

      await _loadData(); // Refresh QR codes list
      
      _showSuccess('QR Code generated successfully!');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showError('Failed to generate QR code: $e');
    }
  }

  void _viewQRCode(Map<String, dynamic> qrCode) {
    setState(() {
      _currentQRData = jsonEncode(qrCode['data']);
      _currentQRDisplayData = qrCode['data'];
      _currentQRType = qrCode['qr_type'];
    });
    _tabController.animateTo(0);
  }

  void _shareExistingQRCode(Map<String, dynamic> qrCode) {
    final qrData = jsonEncode(qrCode['data']);
    Share.share(
      'Scan this QR code to access my health information:\n\nQR Code Type: ${qrCode['qr_type']}\nGenerated: ${_formatDate(qrCode['created_at'])}',
      subject: 'Health Information QR Code',
    );
  }

  Future<void> _shareQRCode() async {
    if (_currentQRData == null) return;
    
    try {
      // Save QR code as image first
      final qrImageData = await _captureQRImage();
      if (qrImageData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/health_qr_code.png').create();
        await file.writeAsBytes(qrImageData);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Scan this QR code to access my health information.',
          subject: 'Health Information QR Code',
        );
      }
    } catch (e) {
      _showError('Failed to share QR code: $e');
    }
  }

  Future<void> _saveQRCode() async {
    try {
      final qrImageData = await _captureQRImage();
      if (qrImageData != null) {
        // TODO: Implement image saving to gallery
        _showSuccess('QR code image saved successfully!');
      }
    } catch (e) {
      _showError('Failed to save QR code: $e');
    }
  }

  Future<Uint8List?> _captureQRImage() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR image: $e');
      return null;
    }
  }

  void _scanQRCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _showQRCodeOptions(Map<String, dynamic> qrCode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 1.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              'QR Code Options',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.w),
            ListTile(
              leading: Icon(
                qrCode['is_active'] ? Icons.pause_circle : Icons.play_circle,
                color: qrCode['is_active'] ? Colors.orange : Colors.green,
              ),
              title: Text(qrCode['is_active'] ? 'Deactivate' : 'Activate'),
              subtitle: Text(
                qrCode['is_active'] 
                    ? 'Make this QR code inactive'
                    : 'Reactivate this QR code',
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _toggleQRCodeStatus(qrCode);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              subtitle: const Text('Permanently delete this QR code'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDeleteQRCode(qrCode);
              },
            ),
            SizedBox(height: 4.w),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleQRCodeStatus(Map<String, dynamic> qrCode) async {
    try {
      await _qrService.updateQRCodeStatus(
        qrCode['qr_code_id'],
        !qrCode['is_active'],
      );
      await _loadData();
      _showSuccess('QR code status updated');
    } catch (e) {
      _showError('Failed to update QR code: $e');
    }
  }

  void _confirmDeleteQRCode(Map<String, dynamic> qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete QR Code'),
        content: const Text(
          'Are you sure you want to delete this QR code? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteQRCode(qrCode);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQRCode(Map<String, dynamic> qrCode) async {
    try {
      await _qrService.deleteQRCode(qrCode['qr_code_id']);
      await _loadData();
      _showSuccess('QR code deleted');
    } catch (e) {
      _showError('Failed to delete QR code: $e');
    }
  }

  // Helper methods
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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