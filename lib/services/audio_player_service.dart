import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService._internal();
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentId;

  String? get currentId => _currentId;
  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;

  Future<void> togglePlay({required String id, required String sourcePath}) async {
    try {
      if (_currentId == id && _player.playing) {
        await _player.pause();
        _currentId = null;
        return;
      }

      // Stop any currently playing audio if switching tracks
      if (_currentId != null && _currentId != id) {
        await _player.stop();
      }

      _currentId = id;

      // Stream URLs vs local files
      if (sourcePath.startsWith('http://') || sourcePath.startsWith('https://')) {
        await _player.setUrl(sourcePath);
      } else {
        await _player.setFilePath(sourcePath);
      }

      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentId = null;
  }
}


