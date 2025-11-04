import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> start() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted');
    }
    final Directory dir = await getApplicationDocumentsDirectory();
    final String filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
  }

  Future<String?> stop() async {
    return _recorder.stop();
  }
}


