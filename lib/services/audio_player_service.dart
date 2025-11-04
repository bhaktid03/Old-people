import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService._internal();
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentId;

  String? get currentId => _currentId;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> togglePlay({required String id, required String sourcePath}) async {
    if (_currentId == id && _player.playing) {
      await _player.pause();
      return;
    }
    _currentId = id;
    await _player.setFilePath(sourcePath);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentId = null;
  }
}


