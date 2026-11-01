import 'package:flutter/material.dart';

/// Educational module placeholder (paper Limitation 11 and Table 4.1).
/// Its content waits for the analysis of the Digital Access and Learning
/// Needs Questionnaire, which decides the topics, format and language.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Learn / Kat-onan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.school_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Lessons are coming soon. / Umaabot pa ang mga leksyon.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'This section will teach how to use AgriKonek and how to sell '
            'safely online. Its topics, format and language will follow what '
            'Calinan farmers said they need in the study\'s learning-needs '
            'questionnaire.\n\n'
            'Kini nga bahin magtudlo unsaon paggamit sa AgriKonek ug unsaon '
            'pagbaligya nga luwas online, sumala sa gikinahanglan sa mga '
            'mag-uuma sa Calinan.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
