import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ScanOverlayWidget extends StatefulWidget {
  final String scanMode;
  final bool isProcessing;

  const ScanOverlayWidget({
    super.key,
    required this.scanMode,
    required this.isProcessing,
  });

  @override
  State<ScanOverlayWidget> createState() => _ScanOverlayWidgetState();
}

class _ScanOverlayWidgetState extends State<ScanOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScanOverlayPainter(
        scanMode: widget.scanMode,
        isProcessing: widget.isProcessing,
        animationValue: _animation.value,
      ),
      child: _buildCenterContent(),
    );
  }

  Widget _buildCenterContent() {
    if (widget.isProcessing) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              const Text(
                'Processing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _getScanInstruction(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _getScanInstruction() {
    switch (widget.scanMode) {
      case 'document':
        return 'Position document within the frame\nEnsure all edges are visible';
      case 'id':
        return 'Center ID card in the frame\nMake sure text is clearly visible';
      case 'prescription':
        return 'Capture the entire prescription\nEnsure all text is readable';
      default:
        return 'Position document within the frame';
    }
  }
}

class ScanOverlayPainter extends CustomPainter {
  final String scanMode;
  final bool isProcessing;
  final double animationValue;

  ScanOverlayPainter({
    required this.scanMode,
    required this.isProcessing,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(153)
      ..style = PaintingStyle.fill;

    // Draw overlay background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Calculate frame dimensions based on scan mode
    late double frameWidth, frameHeight;
    switch (scanMode) {
      case 'document':
        frameWidth = size.width * 0.8;
        frameHeight = size.height * 0.6;
        break;
      case 'id':
        frameWidth = size.width * 0.85;
        frameHeight = frameWidth * 0.6; // ID card aspect ratio
        break;
      case 'prescription':
        frameWidth = size.width * 0.9;
        frameHeight = size.height * 0.7;
        break;
      default:
        frameWidth = size.width * 0.8;
        frameHeight = size.height * 0.6;
    }

    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    // Cut out the scanning area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame corners
    _drawFrameCorners(canvas, frameRect);

    // Draw animated scanning line
    if (!isProcessing) {
      _drawScanningLine(canvas, frameRect);
    }
  }

  void _drawFrameCorners(Canvas canvas, Rect frameRect) {
    final cornerPaint = Paint()
      ..color = isProcessing
          ? AppTheme.successLight
          : AppTheme.lightTheme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      frameRect.topLeft,
      frameRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      frameRect.topRight,
      frameRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      frameRect.bottomLeft,
      frameRect.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      frameRect.bottomRight,
      frameRect.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  void _drawScanningLine(Canvas canvas, Rect frameRect) {
    final linePaint = Paint()
      ..color = AppTheme.lightTheme.colorScheme.primary.withAlpha(204)
      ..style = PaintingStyle.fill;

    final lineY = frameRect.top + (frameRect.height * animationValue);
    final lineRect = Rect.fromLTWH(
      frameRect.left,
      lineY - 1,
      frameRect.width,
      2,
    );

    canvas.drawRect(lineRect, linePaint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = AppTheme.lightTheme.colorScheme.primary.withAlpha(77)
      ..style = PaintingStyle.fill;

    final glowRect = Rect.fromLTWH(
      frameRect.left,
      lineY - 10,
      frameRect.width,
      20,
    );

    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
