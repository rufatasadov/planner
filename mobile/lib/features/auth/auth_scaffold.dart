import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prefs.dart';
import '../../theme.dart';

class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const _PrefsBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        28 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(
      0xFF6366F1,
    ).withValues(alpha: dark ? 0.42 : 0.22);
    final accent = const Color(
      0xFFEC4899,
    ).withValues(alpha: dark ? 0.22 : 0.12);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _Glow(size: 320, color: primary),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: _Glow(size: 300, color: accent),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _PrefsBar extends ConsumerWidget {
  const _PrefsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF121933) : Colors.white).withValues(
              alpha: 0.92,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: authBorder(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              for (final code in supportedLanguageCodes)
                TextButton(
                  onPressed:
                      () => ref
                          .read(prefsProvider.notifier)
                          .setLocale(Locale(code)),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        prefs.locale.languageCode == code
                            ? Theme.of(context).colorScheme.primary
                            : mutedColor(context),
                    minimumSize: const Size(40, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    code.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  final next = dark ? ThemeMode.light : ThemeMode.dark;
                  ref.read(prefsProvider.notifier).setThemeMode(next);
                },
                tooltip:
                    Theme.of(context).brightness == Brightness.dark
                        ? 'Light'
                        : 'Dark',
                icon: Icon(
                  dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color authBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
