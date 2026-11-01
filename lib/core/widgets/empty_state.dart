import 'package:flutter/material.dart';

/// Friendly message for empty lists and load errors: a large icon in a
/// soft circle, then the text, then an optional button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final Widget? action;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isError ? scheme.errorContainer : scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 44,
                  color: isError
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
