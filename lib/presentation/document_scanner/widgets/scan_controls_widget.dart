import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ScanControlsWidget extends StatelessWidget {
  final bool isFlashOn;
  final String scanMode;
  final bool isProcessing;
  final VoidCallback onFlashToggle;
  final Function(String) onScanModeChanged;
  final VoidCallback onCapturePressed;
  final VoidCallback onGalleryPressed;

  const ScanControlsWidget({
    super.key,
    required this.isFlashOn,
    required this.scanMode,
    required this.isProcessing,
    required this.onFlashToggle,
    required this.onScanModeChanged,
    required this.onCapturePressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(179),
            Colors.black.withAlpha(230),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan mode selector
          _buildScanModeSelector(),
          SizedBox(height: 4.h),

          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _buildControlButton(
                icon: Icons.photo_library,
                onPressed: isProcessing ? null : onGalleryPressed,
              ),

              // Capture button
              GestureDetector(
                onTap: isProcessing ? null : onCapturePressed,
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isProcessing
                        ? Colors.grey
                        : AppTheme.lightTheme.colorScheme.primary,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: isProcessing
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Icon(
                          scanMode == 'document'
                              ? Icons.camera_alt
                              : scanMode == 'id'
                                  ? Icons.credit_card
                                  : Icons.medical_services,
                          color: Colors.white,
                          size: 8.w,
                        ),
                ),
              ),

              // Flash button
              _buildControlButton(
                icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                onPressed: isProcessing ? null : onFlashToggle,
                isActive: isFlashOn,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanModeSelector() {
    const modes = [
      {'key': 'document', 'label': 'Document', 'icon': Icons.description},
      {'key': 'id', 'label': 'ID Card', 'icon': Icons.credit_card},
      {
        'key': 'prescription',
        'label': 'Prescription',
        'icon': Icons.medical_services
      },
    ];

    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isSelected = scanMode == mode['key'];
          return GestureDetector(
            onTap: isProcessing
                ? null
                : () => onScanModeChanged(mode['key'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode['icon'] as IconData,
                    color: Colors.white,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    mode['label'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppTheme.lightTheme.colorScheme.primary
              : Colors.black.withAlpha(153),
          border: Border.all(
            color: Colors.white.withAlpha(77),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 6.w,
        ),
      ),
    );
  }
}
