import 'package:agrikonek_calinan/core/l10n/app_language.dart';
import 'package:agrikonek_calinan/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The full AgriKonekApp needs Firebase, so this test builds only the
// sign-in screen, wrapped the same way app.dart wraps every screen.
// Unit tests live in test/models/ and test/services/.
void main() {
  testWidgets('the sign-in screen switches between English and Cebuano',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: Consumer(builder: (context, ref, _) {
        final language = ref.watch(languageProvider);
        return MaterialApp(
          builder: (context, child) =>
              LanguageScope(language: language, child: child!),
          home: const LoginScreen(),
        );
      }),
    ));

    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('MO-LOGIN'), findsNothing);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cebuano (Bisaya)').last);
    await tester.pumpAndSettle();

    expect(find.text('MO-LOGIN'), findsOneWidget);
    expect(find.text('SIGN IN'), findsNothing);
    expect(prefs.getString('app_language'), 'ceb');
  });
}
