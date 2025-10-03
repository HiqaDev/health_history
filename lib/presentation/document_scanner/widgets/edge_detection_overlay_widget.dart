import 'package:flutter/material.dart';

/// Provides visual overlay guides for optimal document positioning
/// Shows green outline when document edges are properly detected
class EdgeDetectionOverlayWidget extends StatelessWidget {
  final bool isDocumentDetected;
  final bool isStable;
  final bool isWellLit;

  const EdgeDetectionOverlayWidget({
    super.key,
    required this.isDocumentDetected,
    required this.isStable,
    required this.isWellLit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine overlay color based on detection state
    Color overlayColor;
    if (isDocumentDetected && isStable && isWellLit) {
      overlayColor = theme.colorScheme.tertiary; // Success green
    } else if (isDocumentDetected) {
      overlayColor = const Color(0xFFFFE66D); // Warning yellow
    } else {
      overlayColor = theme.colorScheme.error; // Error red
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: overlayColor,
          width: 3.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Corner guides
          ...List.generate(
              4,
              (index) => _buildCornerGuide(
                    context,
                    index,
                    overlayColor,
                  )),

          // Center positioning guide
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: overlayColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDocumentDetected && isStable && isWellLit
                    ? Icons.check
                    : Icons.center_focus_strong,
                color: overlayColor,
                size: 24,
              ),
            ),
          ),

          // Status indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGuide(BuildContext context, int index, Color color) {
    const double cornerSize = 30.0;

    late Alignment alignment;
    late Widget cornerWidget;

    switch (index) {
      case 0: // Top-left
        alignment = Alignment.topLeft;
        cornerWidget = Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 4),
              top: BorderSide(color: color, width: 4),
            ),
          ),
        );
        break;
      case 1: // Top-right
        alignment = Alignment.topRight;
        cornerWidget = Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: color, width: 4),
              top: BorderSide(color: color, width: 4),
            ),
          ),
        );
        break;
      case 2: // Bottom-left
        alignment = Alignment.bottomLeft;
        cornerWidget = Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 4),
              bottom: BorderSide(color: color, width: 4),
            ),
          ),
        );
        break;
      case 3: // Bottom-right
        alignment = Alignment.bottomRight;
        cornerWidget = Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: color, width: 4),
              bottom: BorderSide(color: color, width: 4),
            ),
          ),
        );
        break;
    }

    return Align(
      alignment: alignment,
      child: cornerWidget,
    );
  }

  String _getStatusText() {
    if (isDocumentDetected && isStable && isWellLit) {
      return 'Perfect - Ready to capture';
    } else if (isDocumentDetected && isStable) {
      return 'Adjust lighting';
    } else if (isDocumentDetected) {
      return 'Hold steady';
    } else {
      return 'Position document in frame';
    }
  }
}
