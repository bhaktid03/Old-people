import 'dart:async';
import 'headline_model.dart';
import 'headlines_repository.dart';

class FakeHeadlinesRepository implements HeadlinesRepository {
  FakeHeadlinesRepository();

  static final List<Headline> _all = <Headline>[
    Headline(
      id: '1',
      title: 'Headline',
      summary:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non efficitur tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut consequat lacus id mi volutpat, rhoncus consequat ipsum gravida.',
      source: 'The Indian Express',
    ),
    Headline(
      id: '2',
      title: 'Headline',
      summary:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non efficitur tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut consequat lacus id mi volutpat, rhoncus consequat ipsum gravida.',
      source: 'The Hindu',
    ),
    Headline(
      id: '3',
      title: 'Headline',
      summary:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non efficitur tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut consequat lacus id mi volutpat, rhoncus consequat ipsum gravida.',
      source: 'Times of India',
    ),
    Headline(
      id: '4',
      title: 'Headline',
      summary:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non efficitur tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut consequat lacus id mi volutpat, rhoncus consequat ipsum gravida.',
      source: 'Hindustan Times',
    ),
    Headline(
      id: '5',
      title: 'Headline',
      summary:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non efficitur tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut consequat lacus id mi volutpat, rhoncus consequat ipsum gravida.',
      source: 'Dainik Jagran',
    ),
  ];

  @override
  Future<List<Headline>> getHeadlines({required String source, int limit = 5}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _all.where((h) => h.source == source).take(limit).toList();
  }
}


