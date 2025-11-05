import '../../../api/headlines/headlines_api.dart';
import 'headline_model.dart';
import 'headlines_repository.dart';

class ApiHeadlinesRepository implements HeadlinesRepository {
  ApiHeadlinesRepository({HeadlinesApi? headlinesApi})
      : _headlinesApi = headlinesApi ?? HeadlinesApi();

  final HeadlinesApi _headlinesApi;

  @override
  Future<List<Headline>> getHeadlines({
    String? source,
    int limit = 20,
    String? categories,
    String? userId,
  }) async {
    try {
      final response = await _headlinesApi.getNews(
        source: source,
        limit: limit,
        categories: categories,
        userId: userId,
      );

      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      return data.map((json) => Headline.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Handle error - could log or rethrow
      print('Error fetching headlines: $e');
      rethrow;
    }
  }
}
