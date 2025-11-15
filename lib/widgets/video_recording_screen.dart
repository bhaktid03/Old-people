import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';
import '../core/localization/l10n.dart';

class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  bool _launched = false;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_launched) {
      _launched = true;
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: const Duration(minutes: 5),
      );
      if (!mounted) return;
      if (pickedFile == null) {
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _saving = true;
      });

      final savedPath = await _saveToAppDirectory(File(pickedFile.path));
      if (!mounted) return;
      Navigator.of(context).pop(savedPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Future<String> _generateFileName() async {
    final now = DateTime.now();
    return 'video_${now.millisecondsSinceEpoch}.mp4';
  }

  Future<String> _saveToAppDirectory(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(p.join(dir.path, 'videos'));
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    final fileName = await _generateFileName();
    final targetPath = p.join(videosDir.path, fileName);
    final saved = await source.copy(targetPath);
    return saved.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.recordVideo),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    size: 64,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                if (_saving) ...[
                  Text(
                    L10n.recording,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  const CircularProgressIndicator(),
                ] else if (_error != null) ...[
                  Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.lg),
                  ElevatedButton(
                    onPressed: _startRecording,
                    child: Text(L10n.record),
                  ),
                ] else ...[
                  Text(
                    L10n.recordVideo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  ElevatedButton(
                    onPressed: _startRecording,
                    child: Text(L10n.record),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(L10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


