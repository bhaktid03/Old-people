import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> start() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted');
    }
    await _recorder.start(const RecordConfig(), path: null);
  }

  Future<String?> stop() async {
    return _recorder.stop();
  }
}


