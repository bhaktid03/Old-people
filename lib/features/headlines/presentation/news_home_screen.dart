import 'package:flutter/material.dart';
import '../../../app/theme/spacing.dart';
import '../../../widgets/headline_card.dart';
import '../data/headlines_repository.dart';
import '../data/fake_headlines_repository.dart';
import '../data/headline_model.dart';
import 'news_detail_screen.dart';
import '../../../core/localization/l10n.dart';

class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  double _textScale = 1.0; // adjustable text scale for accessibility

  final List<String> _newspapers = const [
    'The Indian Express',
    'The Hindu',
    'Times of India',
    'Hindustan Times',
    'Dainik Jagran',
  ];

  String _selectedPaper = 'The Indian Express';

  late final HeadlinesRepository _repo = FakeHeadlinesRepository();
  Future<List<Headline>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getHeadlines(source: _selectedPaper, limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    // Apply text scale to the whole page for consistent sizing
    final scaledMedia = MediaQuery.of(context).copyWith(
      textScaleFactor: _textScale,
    );

    return MediaQuery(
      data: scaledMedia,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            L10n.goodMorning,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          toolbarHeight: 72,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _HeaderControls(
                  newspapers: _newspapers,
                  selected: _selectedPaper,
                  onChanged: (v) => setState(() {
                    _selectedPaper = v;
                    _future = _repo.getHeadlines(source: _selectedPaper, limit: 5);
                  }),
                  textScale: _textScale,
                  onIncrease: () => setState(() => _textScale = (_textScale + 0.1).clamp(0.9, 1.8)),
                  onDecrease: () => setState(() => _textScale = (_textScale - 0.1).clamp(0.9, 1.8)),
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<List<Headline>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(L10n.failedToLoad,
                          style: Theme.of(context).textTheme.bodyLarge),
                    );
                  }
                  final data = snapshot.data ?? const <Headline>[];
                  if (data.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(L10n.noHeadlines,
                          style: Theme.of(context).textTheme.bodyLarge),
                    );
                  }
                  return Column(
                    children: data
                        .map((h) => HeadlineCard(
                              title: h.title,
                              summary: h.summary,
                              source: h.source,
                              onListen: () => _announce(context, 'Playing headline'),
                              onOpen: () => _announce(context, 'Opening ${h.source} article'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NewsDetailScreen(headline: h),
                                  ),
                                );
                              },
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        // Share Your Thoughts FAB removed as requested
      ),
    );
  }

  void _announce(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textScaleFactor: 1.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({
    required this.newspapers,
    required this.selected,
    required this.onChanged,
    required this.textScale,
    required this.onIncrease,
    required this.onDecrease,
  });

  final List<String> newspapers;
  final String selected;
  final ValueChanged<String> onChanged;
  final double textScale;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: L10n.chooseNewspaper,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: newspapers
                    .map((n) => DropdownMenuItem<String>(
                          value: n,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              n,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        _ScaleButton(label: 'A−', onPressed: onDecrease),
        const SizedBox(width: Spacing.sm),
        _ScaleButton(label: 'A+', onPressed: onIncrease),
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 48),
        side: const BorderSide(width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}


