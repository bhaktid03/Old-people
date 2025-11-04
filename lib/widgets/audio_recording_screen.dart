import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  bool _isRecording = false;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
    });
    // TODO: Start actual audio recording
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Stop actual audio recording
    // For now, return a placeholder audio URL
    Navigator.of(context).pop('audio_placeholder');
  }

  void _cancel() {
    // TODO: Cancel recording and cleanup
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.recordAudio),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                _isRecording ? L10n.recording : L10n.stopRecording,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                _formatDuration(_duration),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Spacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.md,
                      ),
                    ),
                    child: Text(L10n.cancel),
                  ),
                  const SizedBox(width: Spacing.md),
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.md,
                      ),
                    ),
                    child: Text(L10n.stopRecording),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

