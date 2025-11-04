import 'headline_model.dart';

/// Abstraction for fetching headlines (API-backed later)
abstract class HeadlinesRepository {
  Future<List<Headline>> getHeadlines({required String source, int limit = 5});
}


