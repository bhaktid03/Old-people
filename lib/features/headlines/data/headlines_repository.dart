import 'headline_model.dart';

/// Abstraction for fetching headlines (API-backed later)
abstract class HeadlinesRepository {
  Future<List<Headline>> getHeadlines({
    String? source,
    int limit = 20,
    String? categories,
    String? userId,
  });
}


