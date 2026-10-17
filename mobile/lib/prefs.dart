import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLanguageCodes = ['az', 'en', 'ru'];

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main()');
});

class Prefs {
  const Prefs({required this.locale, required this.themeMode});

  final Locale locale;
  final ThemeMode themeMode;

  Prefs copyWith({Locale? locale, ThemeMode? themeMode}) {
    return Prefs(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final prefsProvider = NotifierProvider<PrefsController, Prefs>(
  PrefsController.new,
);

class PrefsController extends Notifier<Prefs> {
  static const _localeKey = 'locale';
  static const _themeKey = 'theme';

  @override
  Prefs build() {
    final stored = ref.watch(sharedPreferencesProvider);
    return Prefs(locale: _locale(stored), themeMode: _theme(stored));
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  static Locale _locale(SharedPreferences prefs) {
    final saved = prefs.getString(_localeKey);
    if (supportedLanguageCodes.contains(saved)) return Locale(saved!);
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(supportedLanguageCodes.contains(device) ? device : 'az');
  }

  static ThemeMode _theme(SharedPreferences prefs) {
    return switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
