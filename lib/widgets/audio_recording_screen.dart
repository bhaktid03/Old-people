import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';
import '../services/audio_recorder.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  final AudioRecorderService _recorder = AudioRecorderService();
  Timer? _timer;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _transcript = '';
  String? _speechLocaleId;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      // Pick locale based on current app language
      final lang = L10n.locale.value; // 'en' or 'hi'
      _speechLocaleId = lang == 'hi' ? 'hi-IN' : 'en-IN';

      await _recorder.start();
      // Start on-device speech recognition (best-effort)
      final hasSpeech = await _speech.initialize(
        onStatus: (s) {},
        onError: (e) {},
      );
      if (hasSpeech) {
        await _speech.listen(
          localeId: _speechLocaleId,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          onResult: (res) {
          if (!mounted) return;
          setState(() {
            _transcript = res.recognizedWords;
          });
          },
        );
      }
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed: $e')),
      );
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _speech.stop();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      // ignore and close
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });
    Navigator.of(context).pop({'path': path ?? '', 'transcript': _transcript});
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _speech.stop();
    try {
      await _recorder.stop();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
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

