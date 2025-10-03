import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

/// Post-capture editing interface with crop, brightness, contrast, and rotation
/// Allows users to adjust document capture before saving
class PostCaptureEditorWidget extends StatefulWidget {
  final String imagePath;
  final VoidCallback onSave;
  final VoidCallback onRetake;

  const PostCaptureEditorWidget({
    super.key,
    required this.imagePath,
    required this.onSave,
    required this.onRetake,
  });

  @override
  State<PostCaptureEditorWidget> createState() =>
      _PostCaptureEditorWidgetState();
}

class _PostCaptureEditorWidgetState extends State<PostCaptureEditorWidget> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  int _rotation = 0;
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Edit Document',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.onSave,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image display with transformations
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Center(
                child: Transform.rotate(
                  angle: _rotation * 90 * 3.14159 / 180,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      _contrast,
                      0,
                      0,
                      0,
                      _brightness * 255,
                      0,
                      _contrast,
                      0,
                      0,
                      _brightness * 255,
                      0,
                      0,
                      _contrast,
                      0,
                      _brightness * 255,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls overlay
          if (_showControls) ...[
            // Top controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(179),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(
                    top: 100, left: 16, right: 16, bottom: 20),
                child: Row(
                  children: [
                    _buildControlIcon(
                      icon: Icons.rotate_left,
                      onTap: () =>
                          setState(() => _rotation = (_rotation - 1) % 4),
                      label: 'Rotate',
                    ),
                    const Spacer(),
                    _buildControlIcon(
                      icon: Icons.crop,
                      onTap: () => _showCropDialog(context),
                      label: 'Crop',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(230),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brightness control
                    _buildSliderControl(
                      label: 'Brightness',
                      value: _brightness,
                      min: -0.5,
                      max: 0.5,
                      onChanged: (value) => setState(() => _brightness = value),
                      icon: Icons.brightness_6,
                    ),

                    const SizedBox(height: 16),

                    // Contrast control
                    _buildSliderControl(
                      label: 'Contrast',
                      value: _contrast,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (value) => setState(() => _contrast = value),
                      icon: Icons.contrast,
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onRetake,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: widget.onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Save Document'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(153),
              border: Border.all(color: Colors.white.withAlpha(77)),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withAlpha(51),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showCropDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Document'),
        content: const Text('Drag the corner handles to adjust the crop area.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply crop logic here
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
