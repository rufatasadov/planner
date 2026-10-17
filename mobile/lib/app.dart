import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_controller.dart';
import 'l10n/app_localizations.dart';
import 'prefs.dart';
import 'router.dart';
import 'theme.dart';
import 'widgets/logo.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final auth = ref.watch(authControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        if (auth.isLoading) {
          return const ColoredBox(
            color: Color(0xFF0B1020),
            child: Center(child: AppLogo(size: 72)),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
