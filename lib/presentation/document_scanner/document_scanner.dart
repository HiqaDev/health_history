import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/document_grid_widget.dart';
import './widgets/scan_controls_widget.dart';
import './widgets/scan_overlay_widget.dart';

class DocumentScanner extends StatefulWidget {
  const DocumentScanner({super.key});

  @override
  State<DocumentScanner> createState() => _DocumentScannerState();
}

class _DocumentScannerState extends State<DocumentScanner>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  String _scanMode = 'document'; // document, id, prescription

  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _scannedDocuments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Apply camera settings (skip unsupported features on web)
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
        if (!kIsWeb) {
          await _cameraController!.setFlashMode(FlashMode.auto);
        }
      } catch (e) {
        // Ignore unsupported features on web
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Document Scanner',
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _showScannedDocuments,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuSelection,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline),
                        SizedBox(width: 8),
                        Text('Scanning Tips'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isCameraInitialized) {
      return _buildLoadingScreen();
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreviewWidget(controller: _cameraController!),
        ),

        // Scan overlay
        Positioned.fill(
          child: ScanOverlayWidget(
            scanMode: _scanMode,
            isProcessing: _isProcessing,
          ),
        ),

        // Top controls
        Positioned(top: 2.h, left: 4.w, right: 4.w, child: _buildTopControls()),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ScanControlsWidget(
            isFlashOn: _isFlashOn,
            scanMode: _scanMode,
            isProcessing: _isProcessing,
            onFlashToggle: _toggleFlash,
            onScanModeChanged: _changeScanMode,
            onCapturePressed: _captureDocument,
            onGalleryPressed: _pickFromGallery,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            const Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(153),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getScanModeTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(153),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${_scannedDocuments.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _getScanModeTitle() {
    switch (_scanMode) {
      case 'document':
        return 'Document Mode';
      case 'id':
        return 'ID Card Mode';
      case 'prescription':
        return 'Prescription Mode';
      default:
        return 'Document Mode';
    }
  }

  void _toggleFlash() async {
    if (!kIsWeb && _cameraController != null) {
      try {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
        await _cameraController!.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      } catch (e) {
        setState(() {
          _isFlashOn = !_isFlashOn; // Revert state
        });
      }
    }
  }

  void _changeScanMode(String mode) {
    setState(() {
      _scanMode = mode;
    });
  }

  Future<void> _captureDocument() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processScannedImage(photo.path, 'camera');
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        await _processScannedImage(image.path, 'gallery');
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processScannedImage(String imagePath, String source) async {
    // Simulate document processing
    await Future.delayed(const Duration(seconds: 2));

    final document = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _generateDocumentTitle(),
      'imagePath': imagePath,
      'scanMode': _scanMode,
      'source': source,
      'dateScanned': DateTime.now(),
      'fileSize': '2.1 MB',
      'extractedText': _getSimulatedExtractedText(),
    };

    setState(() {
      _scannedDocuments.insert(0, document);
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document scanned successfully'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showScannedDocuments(),
        ),
      ),
    );
  }

  String _generateDocumentTitle() {
    final timestamp = DateTime.now();
    switch (_scanMode) {
      case 'document':
        return 'Document_${timestamp.day}${timestamp.month}_${timestamp.hour}${timestamp.minute}';
      case 'id':
        return 'ID_Card_${timestamp.day}${timestamp.month}_${timestamp.hour}${timestamp.minute}';
      case 'prescription':
        return 'Prescription_${timestamp.day}${timestamp.month}_${timestamp.hour}${timestamp.minute}';
      default:
        return 'Scan_${timestamp.day}${timestamp.month}_${timestamp.hour}${timestamp.minute}';
    }
  }

  String _getSimulatedExtractedText() {
    switch (_scanMode) {
      case 'document':
        return 'Medical Report\nPatient: John Anderson\nDate: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\nDiagnosis: Routine health checkup completed successfully.';
      case 'id':
        return 'Health Insurance Card\nName: John Anderson\nPolicy Number: HC123456789\nExpiry: 12/2025';
      case 'prescription':
        return 'Prescription\nDr. Smith - Cardiology\nLisinopril 10mg - Take once daily\nQuantity: 30 tablets\nRefills: 2';
      default:
        return 'Document text extracted successfully.';
    }
  }

  void _showScannedDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _ScannedDocumentsScreen(
              documents: _scannedDocuments,
              onDocumentDeleted: (id) {
                setState(() {
                  _scannedDocuments.removeWhere((doc) => doc['id'] == id);
                });
              },
            ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'help':
        _showScanningTips();
        break;
      case 'settings':
        _showScannerSettings();
        break;
    }
  }

  void _showScanningTips() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scanning Tips'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📄 Document Mode:'),
                Text('• Ensure good lighting'),
                Text('• Keep document flat'),
                Text('• Fill the frame completely\n'),
                Text('🆔 ID Card Mode:'),
                Text('• Center the ID in frame'),
                Text('• Avoid glare and shadows\n'),
                Text('💊 Prescription Mode:'),
                Text('• Capture the entire prescription'),
                Text('• Ensure text is clearly visible'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showScannerSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scanner settings will be available in the next update'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ScannedDocumentsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final Function(String) onDocumentDeleted;

  const _ScannedDocumentsScreen({
    required this.documents,
    required this.onDocumentDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'Scanned Documents'),
      body:
          documents.isEmpty
              ? _buildEmptyState(context)
              : DocumentGridWidget(
                documents: documents,
                onDocumentTap:
                    (document) => _showDocumentDetails(context, document),
                onDocumentDelete: onDocumentDeleted,
              ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.primary.withAlpha(128),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Scanned Documents',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start scanning to see your documents here',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetails(
    BuildContext context,
    Map<String, dynamic> document,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 10.w,
                  height: 0.5.h,
                  margin: EdgeInsets.only(top: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description,
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 6.w,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document['title'] as String,
                                    style:
                                        AppTheme
                                            .lightTheme
                                            .textTheme
                                            .titleLarge,
                                  ),
                                  Text(
                                    'Scanned ${_formatDate(document['dateScanned'] as DateTime)}',
                                    style: AppTheme
                                        .lightTheme
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(179),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Extracted Text',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withAlpha(51),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            document['extractedText'] as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
