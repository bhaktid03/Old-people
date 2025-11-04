import 'dart:io';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';

class VoiceInterpretService {
  VoiceInterpretService._();
  static final VoiceInterpretService _instance = VoiceInterpretService._();
  factory VoiceInterpretService() => _instance;

  Future<Map<String, dynamic>> uploadAndInterpret({
    required String filePath,
    required String language,
  }) async {
    final dio = DioClient().dio;
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


