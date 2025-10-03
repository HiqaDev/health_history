import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import '../../services/qr_code_service.dart';
import '../../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  final QRCodeService _qrService = QRCodeService();
  
  bool _isScanning = true;
  String? _scannedData;
  Map<String, dynamic>? _qrResultData;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      _showError('Camera permission is required to scan QR codes');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(controller.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: _scannedData != null ? _buildResultView() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onQRDetected,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Position the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      Icons.flash_on,
                      'Flash',
                      _toggleFlash,
                    ),
                    _buildControlButton(
                      Icons.image,
                      'Gallery',
                      _scanFromGallery,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!_isScanning)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: Colors.white.withOpacity(0.9),
          child: Icon(icon, color: AppTheme.primaryLight),
        ),
        SizedBox(height: 1.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    if (_qrResultData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final qrType = _qrResultData!['type'];
    final isEmergency = qrType == 'emergency';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isEmergency ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEmergency ? Colors.red.shade200 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isEmergency ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency ? Icons.emergency : Icons.medical_information,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmergency ? 'Emergency Medical Information' : 'Medical Summary',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isEmergency ? Colors.red.shade800 : Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        isEmergency 
                            ? 'Critical health information for emergency response'
                            : 'Comprehensive health summary for medical consultation',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.w),

          // Patient Information
          if (_qrResultData!['patient'] != null) ...[
            _buildSectionCard(
              'Patient Information',
              Icons.person,
              Colors.blue,
              [
                _buildInfoRow('Name', _qrResultData!['patient']['name']),
                if (_qrResultData!['patient']['age'] != null)
                  _buildInfoRow('Age', _qrResultData!['patient']['age'].toString()),
                if (_qrResultData!['patient']['blood_group'] != null)
                  _buildInfoRow('Blood Group', _qrResultData!['patient']['blood_group']),
                if (_qrResultData!['patient']['gender'] != null)
                  _buildInfoRow('Gender', _qrResultData!['patient']['gender']),
              ],
            ),
            SizedBox(height: 4.w),
          ],

          // Emergency Contacts (for emergency QR codes)
          if (isEmergency && _qrResultData!['emergency_contacts'] != null) ...[
            _buildEmergencyContactsCard(_qrResultData!['emergency_contacts']),
            SizedBox(height: 4.w),
          ],

          // Medical Information
          if (_qrResultData!['medical_info'] != null) ...[
            _buildMedicalInfoCard(_qrResultData!['medical_info']),
            SizedBox(height: 4.w),
          ],

          // Insurance Information
          if (_qrResultData!['insurance'] != null) ...[
            _buildInsuranceCard(_qrResultData!['insurance']),
            SizedBox(height: 4.w),
          ],

          // Emergency Instructions (for emergency QR codes)
          if (isEmergency && _qrResultData!['emergency_instructions'] != null) ...[
            _buildEmergencyInstructionsCard(_qrResultData!['emergency_instructions']),
            SizedBox(height: 4.w),
          ],

          // Action Buttons
          _buildActionButtons(isEmergency),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(List<dynamic> contacts) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            ...contacts.map((contact) => _buildEmergencyContactItem(contact)),
            SizedBox(height: 2.w),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.red, size: 4.w),
                  SizedBox(width: 2.w),
                  Text(
                    'Emergency Helpline: 102 (India)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactItem(Map<String, dynamic> contact) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  contact['relationship'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            contact['phone'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(Map<String, dynamic> medicalInfo) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: Colors.orange, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            
            // Allergies
            if (medicalInfo['allergies'] != null && medicalInfo['allergies'].isNotEmpty) ...[
              _buildMedicalSubSection('Allergies', medicalInfo['allergies'], Colors.red),
              SizedBox(height: 3.w),
            ],
            
            // Critical Medications
            if (medicalInfo['critical_medications'] != null && medicalInfo['critical_medications'].isNotEmpty) ...[
              _buildMedicalSubSection('Critical Medications', medicalInfo['critical_medications'], Colors.blue),
              SizedBox(height: 3.w),
            ],
            
            // Medical Alerts
            if (medicalInfo['medical_alerts'] != null && medicalInfo['medical_alerts'].isNotEmpty) ...[
              _buildMedicalSubSection('Medical Alerts', medicalInfo['medical_alerts'], Colors.orange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalSubSection(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: color,
          ),
        ),
        SizedBox(height: 2.w),
        ...items.map((item) => _buildMedicalItem(item, color)),
      ],
    );
  }

  Widget _buildMedicalItem(Map<String, dynamic> item, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'] ?? item['allergen'] ?? item['condition'] ?? 'Unknown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          if (item['severity'] != null) ...[
            Text(
              'Severity: ${item['severity']}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
              ),
            ),
          ],
          if (item['dosage'] != null) ...[
            Text(
              'Dosage: ${item['dosage']}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
              ),
            ),
          ],
          if (item['notes'] != null || item['reaction'] != null || item['purpose'] != null) ...[
            Text(
              item['notes'] ?? item['reaction'] ?? item['purpose'] ?? '',
              style: TextStyle(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceCard(Map<String, dynamic> insurance) {
    return _buildSectionCard(
      'Health Insurance',
      Icons.credit_card,
      Colors.green,
      [
        _buildInfoRow('Provider', insurance['provider'] ?? 'N/A'),
        _buildInfoRow('Policy Number', insurance['policy_number'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildEmergencyInstructionsCard(List<dynamic> instructions) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Emergency Instructions',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            ...instructions.map((instruction) => Padding(
              padding: EdgeInsets.only(bottom: 2.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 1.w, right: 2.w),
                    width: 1.5.w,
                    height: 1.5.w,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction.toString(),
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEmergency) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _scanAnother,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another QR Code'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(4.w),
            ),
          ),
        ),
        if (isEmergency) ...[
          SizedBox(height: 3.w),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _callEmergency,
              icon: const Icon(Icons.emergency),
              label: const Text('Call Emergency (102)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(4.w),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isScanning && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _scannedData = code;
        });
        _processScannedData(code);
      }
    }
  }

  Future<void> _processScannedData(String data) async {
    try {
      // Try to parse as JSON first
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(data);
      } catch (e) {
        // If not JSON, treat as QR code ID
        final result = await _qrService.scanQRCode(data);
        qrData = result;
      }

      setState(() {
        _qrResultData = qrData;
      });
    } catch (e) {
      _showError('Failed to process QR code: $e');
      _scanAnother();
    }
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {});
  }

  void _scanFromGallery() {
    // TODO: Implement gallery scanning
    _showError('Gallery scanning will be implemented in the next update');
  }

  void _scanAnother() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _qrResultData = null;
    });
  }

  void _callEmergency() {
    // TODO: Implement emergency calling
    _showError('Emergency calling will be implemented in the next update');
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