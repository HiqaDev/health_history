import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final int filterCount;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFilterTap,
    this.filterCount = 0,
    this.hintText = 'Search medical records...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                          child: Padding(
                            padding: EdgeInsets.all(2.w),
                            child: CustomIconWidget(
                              iconName: 'clear',
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTapDown: (_) => _startVoiceRecording(),
                        onTapUp: (_) => _stopVoiceRecording(),
                        onTapCancel: () => _stopVoiceRecording(),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            margin: EdgeInsets.only(right: 2.w),
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? AppTheme.errorLight.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: _isRecording ? 'mic' : 'mic_none',
                              color: _isRecording
                                  ? AppTheme.errorLight
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 3.w,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: widget.filterCount > 0
                    ? colorScheme.primary
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.filterCount > 0
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  CustomIconWidget(
                    iconName: 'tune',
                    color: widget.filterCount > 0
                        ? Colors.white
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  if (widget.filterCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Text(
                          widget.filterCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    try {
      // Request microphone permission
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage();
        return;
      }

      setState(() {
        _isRecording = true;
        _isListening = true;
      });

      _animationController.forward();

      // Start recording
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: 'voice_input.wav',
          );
        } else {
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/voice_input_${DateTime.now().millisecondsSinceEpoch}.wav';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: filePath,
          );
        }

        // Show recording feedback
        _showRecordingFeedback();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isListening = false;
      });
      _animationController.reverse();
      _showErrorMessage('Failed to start voice recording');
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isRecording = false;
        _isListening = false;
      });

      _animationController.reverse();

      // Stop recording
      final path = await _audioRecorder.stop();

      if (path != null) {
        // In a real implementation, you would process the audio file
        // and convert it to text using speech-to-text service
        _processVoiceInput(path);
      }
    } catch (e) {
      _showErrorMessage('Failed to process voice recording');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _processVoiceInput(String audioPath) {
    // Simulate voice-to-text conversion
    // In a real app, you would use a speech-to-text service
    final simulatedText = 'prescription blood test';

    _searchController.text = simulatedText;
    widget.onSearchChanged(simulatedText);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice search: "$simulatedText"'),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRecordingFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'mic',
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 2.w),
            const Text('Listening... Release to search'),
          ],
        ),
        backgroundColor: AppTheme.primaryLight,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Microphone permission is required for voice search'),
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