import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Camera capture controls with haptic feedback and animations
/// Provides capture button, flash toggle, and camera switch functionality
class CaptureControlsWidget extends StatefulWidget {
  final VoidCallback onCapture;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraSwitch;
  final bool isFlashOn;
  final bool canSwitchCamera;
  final bool isAutoCapturing;
  final bool canCapture;

  const CaptureControlsWidget({
    super.key,
    required this.onCapture,
    required this.onFlashToggle,
    required this.onCameraSwitch,
    required this.isFlashOn,
    required this.canSwitchCamera,
    this.isAutoCapturing = false,
    this.canCapture = true,
  });

  @override
  State<CaptureControlsWidget> createState() => _CaptureControlsWidgetState();
}

class _CaptureControlsWidgetState extends State<CaptureControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _captureAnimationController;
  late AnimationController _autoCapureAnimationController;
  late Animation<double> _captureScaleAnimation;
  late Animation<double> _autoCapturePulseAnimation;

  @override
  void initState() {
    super.initState();

    // Capture button animation
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _captureScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _captureAnimationController,
      curve: Curves.easeInOut,
    ));

    // Auto-capture pulse animation
    _autoCapureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _autoCapturePulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _autoCapureAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CaptureControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start pulse animation for auto-capture mode
    if (widget.isAutoCapturing && !oldWidget.isAutoCapturing) {
      _autoCapureAnimationController.repeat(reverse: true);
    } else if (!widget.isAutoCapturing && oldWidget.isAutoCapturing) {
      _autoCapureAnimationController.stop();
      _autoCapureAnimationController.reset();
    }
  }

  @override
  void dispose() {
    _captureAnimationController.dispose();
    _autoCapureAnimationController.dispose();
    super.dispose();
  }

  void _handleCapture() {
    if (!widget.canCapture) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Animate button
    _captureAnimationController.forward().then((_) {
      _captureAnimationController.reverse();
    });

    widget.onCapture();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(179),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Flash toggle button
          _buildControlButton(
            icon: widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
            onTap: widget.onFlashToggle,
            isActive: widget.isFlashOn,
          ),

          // Capture button
          AnimatedBuilder(
            animation: widget.isAutoCapturing
                ? _autoCapturePulseAnimation
                : _captureScaleAnimation,
            builder: (context, child) {
              final scale = widget.isAutoCapturing
                  ? _autoCapturePulseAnimation.value
                  : _captureScaleAnimation.value;

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: _handleCapture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.canCapture
                          ? (widget.isAutoCapturing
                              ? theme.colorScheme.tertiary
                              : Colors.white)
                          : Colors.grey,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isAutoCapturing
                        ? Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 32,
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.canCapture
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),

          // Camera switch button
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            onTap: widget.canSwitchCamera ? widget.onCameraSwitch : null,
            isActive: false,
            enabled: widget.canSwitchCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isActive,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.black.withAlpha(128),
          border: Border.all(
            color: Colors.white.withAlpha(128),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color:
              isActive ? Colors.black : (enabled ? Colors.white : Colors.grey),
          size: 24,
        ),
      ),
    );
  }
}
