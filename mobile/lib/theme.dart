import 'package:flutter/material.dart';

const _bg = Color(0xFF0B1020);
const _surface = Color(0xFF121933);
const _surface2 = Color(0xFF19223F);
const _text = Color(0xFFE6E9F5);
const _muted = Color(0xFF8B94B8);
const _primary = Color(0xFF6366F1);
const _primary2 = Color(0xFF8B5CF6);

const _lightBg = Color(0xFFF4F6FB);
const _lightSurface = Color(0xFFFFFFFF);
const _lightText = Color(0xFF0F172A);
const _lightMuted = Color(0xFF64748B);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: brightness,
    primary: _primary,
    secondary: _primary2,
    surface: dark ? _surface : _lightSurface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? _bg : _lightBg,
    textTheme: Typography.material2021(
      platform: TargetPlatform.iOS,
    ).black.apply(
      bodyColor: dark ? _text : _lightText,
      displayColor: dark ? _text : _lightText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? _bg : _lightBg,
      foregroundColor: dark ? _text : _lightText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? _surface : _lightSurface,
      indicatorColor: _primary.withValues(alpha: 0.25),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? _surface2 : const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: dark ? _muted : _lightMuted),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return _primary;
        return dark ? _muted : _lightMuted;
      }),
      suffixIconColor: dark ? _muted : _lightMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color:
              dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? _surface : _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

Color mutedColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _muted : _lightMuted;
