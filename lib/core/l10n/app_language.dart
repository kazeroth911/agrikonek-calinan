import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two languages of the app (paper §3.5.5: English and Cebuano).
enum AppLanguage {
  english('en', 'English'),
  cebuano('ceb', 'Cebuano (Bisaya)');

  const AppLanguage(this.code, this.displayName);

  /// Stored on the phone and on the device-token record, so pushes can be
  /// sent in the same language.
  final String code;
  final String displayName;

  static AppLanguage fromCode(String? code) =>
      code == AppLanguage.cebuano.code ? AppLanguage.cebuano : AppLanguage.english;
}

/// Picks the text for [language]. Use this outside widgets; inside
/// widgets use `context.tr(english, cebuano)`.
String tr(AppLanguage language, String english, String cebuano) =>
    language == AppLanguage.cebuano ? cebuano : english;

/// Set in main() after SharedPreferences loads, so the saved language is
/// known before the first screen draws.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

class LanguageController extends StateNotifier<AppLanguage> {
  LanguageController(this._prefs)
      : super(AppLanguage.fromCode(_prefs.getString(_key)));

  static const _key = 'app_language';
  final SharedPreferences _prefs;

  Future<void> set(AppLanguage language) async {
    state = language;
    await _prefs.setString(_key, language.code);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageController, AppLanguage>(
  (ref) => LanguageController(ref.watch(sharedPreferencesProvider)),
);

/// Makes the chosen language available to every screen below it
/// (installed once, in MaterialApp.builder).
class LanguageScope extends InheritedWidget {
  const LanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.language ??
      AppLanguage.english;

  @override
  bool updateShouldNotify(LanguageScope oldWidget) =>
      oldWidget.language != language;
}

extension LanguageContext on BuildContext {
  AppLanguage get language => LanguageScope.of(this);

  /// `context.tr('Send', 'Ipadala')`: the text in the chosen language.
  String tr(String english, String cebuano) => language == AppLanguage.cebuano
      ? cebuano
      : english;
}
