import 'package:dio/dio.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));
  }
}


