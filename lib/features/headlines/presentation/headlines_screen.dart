import 'package:flutter/material.dart';

class HeadlinesScreen extends StatelessWidget {
  const HeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chaupal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HeadlineCard(
            title: 'Sample Headline',
            summary: 'A brief, readable summary in large text for elders.',
          ),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final String title;
  final String summary;
  const _HeadlineCard({required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Listen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


