import 'dart:io';
import 'package:dio/dio.dart';

class VoiceInterpretService {
  VoiceInterpretService._();
  static final VoiceInterpretService _instance = VoiceInterpretService._();
  factory VoiceInterpretService() => _instance;

  Future<Map<String, dynamic>> uploadAndInterpret({
    required String filePath,
    required String language,
  }) async {
    // Use a dedicated base URL for the LLM/STT server to avoid conflicts
    // with the main application API base URL.
    final dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'LLM_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 60),
    ));
    final file = File(filePath);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      'language': language,
    });
    final resp = await dio.post('/voice/interpret', data: form,
        options: Options(contentType: 'multipart/form-data'));
    if (resp.statusCode != 200) {
      throw Exception('Interpret failed: ${resp.statusCode}');
    }
    return Map<String, dynamic>.from(resp.data as Map);
  }
}


