import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Very small HTTP client using dart:io so we avoid extra dependencies.
class ApiClient {
  ApiClient({HttpClient? httpClient, bool enableLogging = false})
      : _httpClient = httpClient ?? HttpClient(),
        _enableLogging = enableLogging;

  final HttpClient _httpClient;
  final bool _enableLogging;

  Future<Map<String, dynamic>> postJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_enableLogging) {
      // Request log
      print('[ApiClient] POST $url');
      if (headers != null && headers.isNotEmpty) {
        print('[ApiClient] Headers: ${jsonEncode(headers)}');
      }
      print('[ApiClient] Request body: ${jsonEncode(body)}');
    }

    final HttpClientRequest request = await _httpClient.postUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (headers != null) {
      headers.forEach(request.headers.set);
    }
    final String encodedBody = jsonEncode(body);
    request.add(utf8.encode(encodedBody));

    final HttpClientResponse response = await request.close().timeout(timeout);
    final String responseBody = await response.transform(utf8.decoder).join();

    if (_enableLogging) {
      print('[ApiClient] Status: ${response.statusCode}');
      print('[ApiClient] Response body: ${responseBody.isEmpty ? '<empty>' : responseBody}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return <String, dynamic>{};
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    }

    // Try to extract server error message
    String message = 'HTTP ${response.statusCode}';
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // ignore
    }
    throw HttpException(message, uri: Uri.parse(url));
  }
}

