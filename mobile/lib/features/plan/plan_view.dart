import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prefs.dart';

enum PlanViewMode { strip, column, fit }

PlanViewMode planViewFromName(String? name) {
  return switch (name) {
    'strip' => PlanViewMode.strip,
    'fit' => PlanViewMode.fit,
    _ => PlanViewMode.column,
  };
}

final planViewModeProvider = NotifierProvider<PlanViewController, PlanViewMode>(
  PlanViewController.new,
);

class PlanViewController extends Notifier<PlanViewMode> {
  static const _key = 'plan_view';

  @override
  PlanViewMode build() =>
      planViewFromName(ref.watch(sharedPreferencesProvider).getString(_key));

  Future<void> setMode(PlanViewMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}
