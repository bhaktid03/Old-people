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

  Future<Map<String, dynamic>> putJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_enableLogging) {
      // Request log
      print('[ApiClient] PUT $url');
      if (headers != null && headers.isNotEmpty) {
        print('[ApiClient] Headers: ${jsonEncode(headers)}');
      }
      print('[ApiClient] Request body: ${jsonEncode(body)}');
    }

    final HttpClientRequest request = await _httpClient.putUrl(Uri.parse(url));
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

  Future<Map<String, dynamic>> getJson({
    required String url,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    // Build URL with query parameters
    Uri uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
    }

    if (_enableLogging) {
      print('[ApiClient] GET $uri');
      if (headers != null && headers.isNotEmpty) {
        print('[ApiClient] Headers: ${jsonEncode(headers)}');
      }
    }

    final HttpClientRequest request = await _httpClient.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (headers != null) {
      headers.forEach(request.headers.set);
    }

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
    throw HttpException(message, uri: uri);
  }

  Future<Map<String, dynamic>> putMultipart({
    required String url,
    required Map<String, String> fields,
    required File imageFile,
    String fileFieldName = 'image',
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_enableLogging) {
      print('[ApiClient] PUT (multipart) $url');
      print('[ApiClient] Fields: ${jsonEncode(fields)}');
      print('[ApiClient] Image file: ${imageFile.path}');
    }

    final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    final HttpClientRequest request = await _httpClient.putUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
    if (headers != null) {
      headers.forEach(request.headers.set);
    }

    // Build multipart body
    final List<int> bodyBytes = <int>[];
    
    // Add fields
    fields.forEach((key, value) {
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="$key"\r\n\r\n'));
      bodyBytes.addAll(utf8.encode('$value\r\n'));
    });

    // Add file
    final String fileName = imageFile.path.split(Platform.pathSeparator).last;
    final String contentType = _getContentType(fileName);
    bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="$fileFieldName"; filename="$fileName"\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    
    final fileBytes = await imageFile.readAsBytes();
    bodyBytes.addAll(fileBytes);
    bodyBytes.addAll(utf8.encode('\r\n'));
    bodyBytes.addAll(utf8.encode('--$boundary--\r\n'));

    request.add(bodyBytes);
    request.contentLength = bodyBytes.length;

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

  Future<Map<String, dynamic>> postMultipart({
    required String url,
    required Map<String, String> fields,
    required File file,
    String fileFieldName = 'file',
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_enableLogging) {
      print('[ApiClient] POST (multipart) $url');
      print('[ApiClient] Fields: ${jsonEncode(fields)}');
      print('[ApiClient] File: ${file.path}');
    }

    final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    
    // Build multipart body first to calculate content length
    final List<int> bodyBytes = <int>[];
    
    // Add fields
    fields.forEach((key, value) {
      if (value.isNotEmpty) {
        bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
        bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="$key"\r\n\r\n'));
        bodyBytes.addAll(utf8.encode('$value\r\n'));
      }
    });

    // Add file
    final String fileName = file.path.split(Platform.pathSeparator).last;
    final String contentType = _getContentType(fileName);
    bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="$fileFieldName"; filename="$fileName"\r\n'));
    bodyBytes.addAll(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    
    final fileBytes = await file.readAsBytes();
    bodyBytes.addAll(fileBytes);
    bodyBytes.addAll(utf8.encode('\r\n'));
    bodyBytes.addAll(utf8.encode('--$boundary--\r\n'));

    // Now create request and set headers with content length
    final HttpClientRequest request = await _httpClient.postUrl(Uri.parse(url));
    request.contentLength = bodyBytes.length;
    request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
    if (headers != null && headers.isNotEmpty) {
      headers.forEach((key, value) {
        if (key.toLowerCase() != HttpHeaders.contentTypeHeader.toLowerCase()) {
          request.headers.set(key, value);
        }
      });
    }

    // Add body after headers are set
    request.add(bodyBytes);

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

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp3':
      case 'mpeg':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}

