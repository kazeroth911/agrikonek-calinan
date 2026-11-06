import 'package:agrikonek_calinan/core/l10n/app_language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tr picks one language, never both', () {
    expect(tr(AppLanguage.english, 'Send', 'Ipadala'), 'Send');
    expect(tr(AppLanguage.cebuano, 'Send', 'Ipadala'), 'Ipadala');
  });

  test('codes match what the push sender expects', () {
    expect(AppLanguage.english.code, 'en');
    expect(AppLanguage.cebuano.code, 'ceb');
    expect(AppLanguage.fromCode('ceb'), AppLanguage.cebuano);
    expect(AppLanguage.fromCode(null), AppLanguage.english);
    expect(AppLanguage.fromCode('fil'), AppLanguage.english);
  });

  test('the chosen language is saved on the phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    expect(container.read(languageProvider), AppLanguage.english);
    await container.read(languageProvider.notifier).set(AppLanguage.cebuano);
    expect(container.read(languageProvider), AppLanguage.cebuano);

    // A fresh start reads the saved choice back.
    final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(restarted.dispose);
    expect(restarted.read(languageProvider), AppLanguage.cebuano);
  });
}
