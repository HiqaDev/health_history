import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentUploadFab extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onDocumentUploaded;

  const DocumentUploadFab({
    super.key,
    this.onDocumentUploaded,
  });

  @override
  State<DocumentUploadFab> createState() => _DocumentUploadFabState();
}

class _DocumentUploadFabState extends State<DocumentUploadFab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isExpanded = false;
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          _buildUploadOption(
            context,
            'Scan Document',
            Icons.camera_alt,
            AppTheme.primaryLight,
            _scanDocument,
          ),
          SizedBox(height: 2.h),
          _buildUploadOption(
            context,
            'Take Photo',
            Icons.photo_camera,
            AppTheme.secondaryLight,
            _takePhoto,
          ),
          SizedBox(height: 2.h),
          _buildUploadOption(
            context,
            'Choose File',
            Icons.folder,
            AppTheme.successLight,
            _chooseFile,
          ),
          SizedBox(height: 2.h),
        ],
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: colorScheme.primary,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: CustomIconWidget(
                  iconName: _isExpanded ? 'close' : 'add',
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _scanDocument() async {
    _toggleExpanded();

    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage(
            'Camera permission is required to scan documents');
        return;
      }

      await _initializeCamera();
      if (_cameraController == null) {
        _showErrorMessage('Failed to initialize camera');
        return;
      }

      final XFile? image = await _cameraController!.takePicture();
      if (image != null) {
        _processUploadedDocument({
          'type': 'scan',
          'path': image.path,
          'name': 'Scanned Document ${DateTime.now().millisecondsSinceEpoch}',
          'mimeType': 'image/jpeg',
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to scan document: ${e.toString()}');
    } finally {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  Future<void> _takePhoto() async {
    _toggleExpanded();

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        _processUploadedDocument({
          'type': 'photo',
          'path': image.path,
          'name': 'Photo ${DateTime.now().millisecondsSinceEpoch}',
          'mimeType': 'image/jpeg',
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _chooseFile() async {
    _toggleExpanded();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _processUploadedDocument({
          'type': 'file',
          'path': file.path,
          'name': file.name,
          'size': file.size,
          'mimeType': _getMimeType(file.extension ?? ''),
          'bytes': kIsWeb ? file.bytes : null,
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to select file: ${e.toString()}');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = kIsWeb
          ? _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras!.first,
            )
          : _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras!.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      // Apply camera settings (skip unsupported features on web)
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        // Focus mode not supported, continue
      }

      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          // Flash not supported, continue
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize camera: ${e.toString()}');
    }
  }

  void _processUploadedDocument(Map<String, dynamic> documentData) {
    // Simulate document processing and categorization
    final processedDocument = {
      ...documentData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'uploadDate': DateTime.now().toIso8601String(),
      'category': _categorizeDocument(documentData['name'] as String),
      'status': 'processing',
    };

    widget.onDocumentUploaded?.call(processedDocument);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'cloud_upload',
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text('Document uploaded: ${documentData['name']}'),
            ),
          ],
        ),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to document preview
          },
        ),
      ),
    );
  }

  String _categorizeDocument(String fileName) {
    final name = fileName.toLowerCase();

    if (name.contains('prescription') || name.contains('rx')) {
      return 'Prescription';
    } else if (name.contains('lab') ||
        name.contains('test') ||
        name.contains('blood')) {
      return 'Lab Report';
    } else if (name.contains('xray') ||
        name.contains('mri') ||
        name.contains('scan')) {
      return 'Imaging';
    } else if (name.contains('bill') ||
        name.contains('invoice') ||
        name.contains('receipt')) {
      return 'Bill';
    } else if (name.contains('insurance') || name.contains('claim')) {
      return 'Insurance';
    } else if (name.contains('vaccine') || name.contains('vaccination')) {
      return 'Vaccination';
    } else {
      return 'Document';
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  void _showPermissionDeniedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
      ),
    );
  }
}
