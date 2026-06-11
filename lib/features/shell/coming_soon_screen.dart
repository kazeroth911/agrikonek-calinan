import 'package:flutter/material.dart';

/// Navigation target for features whose full flow lands in a later
/// sprint (bidding/barter in Sprint 3, messaging in Sprint 4). Keeps
/// the Sprint 2 detail-screen buttons honest: they navigate, but tell
/// the tester exactly when the flow arrives.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.sprintLabel,
  });

  final String title;
  final String sprintLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 64),
              const SizedBox(height: 16),
              Text(
                '$title is coming in $sprintLabel.\n'
                'Padayon lang — under construction pa ni!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
