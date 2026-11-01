import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_language.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/shell/home_shell.dart';
import 'services/push_notification_service.dart';

class AgriKonekApp extends ConsumerWidget {
  const AgriKonekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final pushService = PushNotificationService.instance;
    final language = ref.watch(languageProvider);
    // Pushes are written in the language this phone uses.
    pushService.setLanguage(language.code);

    return MaterialApp(
      title: 'AgriKonek Calinan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: pushService.navigatorKey,
      scaffoldMessengerKey: pushService.scaffoldMessengerKey,
      builder: (context, child) =>
          LanguageScope(language: language, child: child ?? const SizedBox()),
      routes: {
        '/notifications': (context) => const NotificationsScreen(),
      },
      home: authState.when(
        data: (user) => user == null ? const LoginScreen() : const HomeShell(),
        loading: () => const _SplashScreen(),
        error: (e, _) => _ErrorScreen(message: e.toString()),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong:\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
