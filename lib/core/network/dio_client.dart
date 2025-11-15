import 'package:dio/dio.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000'),
      // Whisper + LLM can take longer on CPU; increase timeouts
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 180),
      sendTimeout: const Duration(seconds: 60),
    ));
  }
}


