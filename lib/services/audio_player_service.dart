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
    try {
      if (_currentId == id && _player.playing) {
        await _player.pause();
        return;
      }
      _currentId = id;
      
      print('[AudioPlayerService] Playing: id=$id, sourcePath=$sourcePath');
      
      // Check if it's a URL (starts with http:// or https://) or a local file path
      if (sourcePath.startsWith('http://') || sourcePath.startsWith('https://')) {
        // Use setUrl for streaming from HTTP/HTTPS URLs
        // setUrl can accept both String and Uri
        print('[AudioPlayerService] Using setUrl for streaming: $sourcePath');
        await _player.setUrl(sourcePath);
      } else {
        // Use setFilePath for local files
        print('[AudioPlayerService] Using setFilePath for local file: $sourcePath');
        await _player.setFilePath(sourcePath);
      }
      
      await _player.play();
      print('[AudioPlayerService] Play started successfully');
    } catch (e, stackTrace) {
      print('[AudioPlayerService] Error playing audio: $e');
      print('[AudioPlayerService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentId = null;
  }
}


