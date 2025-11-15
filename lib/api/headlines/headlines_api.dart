import '../client/api_client.dart';
import '../common/endpoints.dart';

class HeadlinesApi {
  HeadlinesApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(enableLogging: true);

  final ApiClient _apiClient;

  /// Fetch news articles from various sources with optional filtering
  /// 
  /// Parameters:
  /// - source: News source provider (e.g., indian_express, bbc_hindi, ndtv, toi, the_hindu)
  /// - limit: Maximum number of articles to return (default: 20)
  /// - categories: Filter by one or more categories (comma-separated)
  /// - userId: User ID for personalized language preference
  /// - xUserId: User ID from header (alternative to query param)
  Future<Map<String, dynamic>> getNews({
    String? source,
    int? limit,
    String? categories,
    String? userId,
    String? xUserId,
  }) async {
    final Map<String, String> queryParams = {};
    if (source != null) queryParams['source'] = source;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (categories != null) queryParams['categories'] = categories;
    if (userId != null) queryParams['userId'] = userId;

    final Map<String, String> headers = {};
    if (xUserId != null) headers['x-user-id'] = xUserId;

    return await _apiClient.getJson(
      url: Endpoints.getNews(),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      headers: headers.isNotEmpty ? headers : null,
    );
  }
}
