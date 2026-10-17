import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../billing/store_billing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan.dart';
import '../../models/user.dart';
import '../../prefs.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../../widgets/logo.dart';
import '../billing/paywall_sheet.dart';
import '../plan/plan_controller.dart';
import '../plan/plan_repository.dart';
import '../plan/plan_time.dart';
import '../plan/plan_view.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final prefs = ref.watch(prefsProvider);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            l10n.tabSettings,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (user != null) _Subscription(user: user),
          _section(context, l10n.settingsAppearance, [
            Text(
              l10n.language,
              style: TextStyle(color: mutedColor(context), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final code in const ['az', 'en', 'ru']) ...[
                  if (code != 'az') const SizedBox(width: 8),
                  Expanded(
                    child: _pick(
                      context,
                      label: code.toUpperCase(),
                      selected: prefs.locale.languageCode == code,
                      onTap:
                          () => ref
                              .read(prefsProvider.notifier)
                              .setLocale(Locale(code)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.theme,
              style: TextStyle(color: mutedColor(context), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _pick(
                    context,
                    label: l10n.themeLight,
                    icon: Icons.light_mode_outlined,
                    selected: Theme.of(context).brightness == Brightness.light,
                    onTap:
                        () => ref
                            .read(prefsProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pick(
                    context,
                    label: l10n.themeDark,
                    icon: Icons.dark_mode_outlined,
                    selected: Theme.of(context).brightness == Brightness.dark,
                    onTap:
                        () => ref
                            .read(prefsProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ]),
          const _ScheduleView(),
          const _Preferences(),
          _section(context, l10n.aboutTitle, [
            const AppLogo(size: 36),
            const SizedBox(height: 10),
            Text(
              l10n.aboutMission,
              style: TextStyle(color: mutedColor(context), height: 1.35),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aboutAuthor,
              style: TextStyle(color: mutedColor(context), fontSize: 12),
            ),
            const Text(
              'Rufat Asadov',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aboutContact,
              style: TextStyle(color: mutedColor(context), fontSize: 12),
            ),
            const SelectableText('rufatasadov24@gmail.com'),
          ]),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: Text(l10n.logout),
          ),
          TextButton(
            onPressed: () => _deleteAccount(context, ref),
            child: Text(
              l10n.settingsDeleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _pick(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
  IconData? icon,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Material(
    color: selected ? scheme.primary.withValues(alpha: 0.14) : scheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color:
            selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.6),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? scheme.primary : mutedColor(context),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _section(BuildContext context, String title, List<Widget> children) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _ScheduleView extends ConsumerWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(planViewModeProvider);
    final options = [
      (PlanViewMode.column, l10n.planViewColumn),
      (PlanViewMode.strip, l10n.planViewStrip),
      (PlanViewMode.fit, l10n.planViewFit),
    ];
    return _section(context, l10n.settingsScheduleView, [
      Text(
        l10n.settingsScheduleLocal,
        style: TextStyle(color: mutedColor(context), fontSize: 13),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final option in options) ...[
            if (option.$1 != PlanViewMode.column) const SizedBox(width: 6),
            Expanded(
              child: _choice(
                context,
                ref,
                option.$1,
                option.$2,
                option.$1 == mode,
              ),
            ),
          ],
        ],
      ),
    ]);
  }

  Widget _choice(
    BuildContext context,
    WidgetRef ref,
    PlanViewMode mode,
    String label,
    bool on,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Material(
        color: on ? scheme.primary.withValues(alpha: 0.16) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color:
                on
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: () => ref.read(planViewModeProvider.notifier).setMode(mode),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? scheme.primary : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preferences extends ConsumerStatefulWidget {
  const _Preferences();

  @override
  ConsumerState<_Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends ConsumerState<_Preferences> {
  WorkHours? _hours;
  Object? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHours());
  }

  Future<void> _loadHours() async {
    try {
      final hours = await ref.read(planRepositoryProvider).hours();
      if (mounted) {
        setState(() {
          _hours = hours;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _pick(bool start) async {
    final hours = _hours;
    if (hours == null) return;
    final current = start ? hours.startMin : hours.endMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = snapQuarter(picked.hour * 60 + picked.minute);
    setState(() {
      _hours =
          start
              ? hours.copyWith(startMin: minutes)
              : hours.copyWith(endMin: minutes);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final hours = _hours;
    if (hours == null || hours.startMin >= hours.endMin) return;
    setState(() => _busy = true);
    try {
      final saved = await ref.read(planRepositoryProvider).saveSettings(hours);
      await ref.read(planControllerProvider.notifier).reload();
      if (!mounted) return;
      setState(() => _hours = saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiErrorMessage(error, l10n.networkError, l10n.genericError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final nextId = next.valueOrNull?.user.id;
      if (previous?.valueOrNull?.user.id == nextId || nextId == null) return;
      _loadHours();
    });
    final l10n = AppLocalizations.of(context);
    final hours = _hours;
    if (_error != null && hours == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          apiErrorMessage(_error!, l10n.networkError, l10n.genericError),
        ),
      );
    }
    if (hours == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final valid = hours.endMin > hours.startMin;
    final length = hours.endMin - hours.startMin;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsWorkHours,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsWorkHoursHint,
              style: TextStyle(color: mutedColor(context)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _pick(true),
                    child: Text(fmtMin(hours.startMin)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => _pick(false),
                    child: Text(fmtMin(hours.endMin)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valid
                  ? l10n.settingsWorkDay(_span(l10n, length))
                  : l10n.settingsEndAfterStart,
              style: TextStyle(
                color: valid ? mutedColor(context) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.settingsNotifications,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _slider(
              context,
              l10n.settingsNotifyBefore,
              hours.notifyBeforeMin == 0
                  ? l10n.settingsOff
                  : l10n.planMinutes(hours.notifyBeforeMin),
              hours.notifyBeforeMin.toDouble(),
              0,
              60,
              60,
              (value) => setState(
                () => _hours = hours.copyWith(notifyBeforeMin: value.round()),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.settingsTracking,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsEfficiencyHint,
              style: TextStyle(color: mutedColor(context)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: hours.autoStop,
              title: Text(l10n.settingsAutoStop),
              subtitle: Text(l10n.settingsAutoStopHint),
              onChanged:
                  (value) =>
                      setState(() => _hours = hours.copyWith(autoStop: value)),
            ),
            _slider(
              context,
              l10n.settingsTarget,
              '${hours.targetEfficiencyPct}%',
              hours.targetEfficiencyPct.toDouble(),
              10,
              100,
              18,
              (value) => setState(
                () =>
                    _hours = hours.copyWith(targetEfficiencyPct: value.round()),
              ),
            ),
            _slider(
              context,
              l10n.settingsBreakReminder,
              hours.breakReminderMin == 0
                  ? l10n.settingsOff
                  : l10n.planMinutes(hours.breakReminderMin),
              hours.breakReminderMin.toDouble(),
              0,
              120,
              24,
              (value) => setState(
                () => _hours = hours.copyWith(breakReminderMin: value.round()),
              ),
            ),
            _slider(
              context,
              l10n.settingsIdlePause,
              hours.idlePauseMin == 0
                  ? l10n.settingsOff
                  : l10n.planMinutes(hours.idlePauseMin),
              hours.idlePauseMin.toDouble(),
              0,
              60,
              60,
              (value) => setState(
                () => _hours = hours.copyWith(idlePauseMin: value.round()),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsIdleHint,
              style: TextStyle(color: mutedColor(context), fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy || !valid ? null : _save,
                child: Text(l10n.planSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _span(AppLocalizations l10n, int minutes) {
    return l10n.planHours(minutes ~/ 60, minutes % 60);
  }

  Widget _slider(
    BuildContext context,
    String label,
    String value,
    double current,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
          value: current.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Subscription extends ConsumerWidget {
  const _Subscription({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final billing = user.billing;
    final locale = Localizations.localeOf(context).toString();
    final lines = _lines(l10n, billing, locale);
    final color = billing.isPro ? const Color(0xFF8B5CF6) : mutedColor(context);
    final initial = _initial(user);
    final store = billing.subscription?.provider;
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return _section(context, l10n.settingsSubscription, [
      Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Text(
              initial,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mutedColor(context), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              billing.isPro ? l10n.planPro : l10n.planFree,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      if (lines.isNotEmpty) ...[
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  Text(
                    lines[i],
                    style: TextStyle(
                      color: mutedColor(context),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      if (!billing.isPro || billing.source == 'trial') ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => showPaywall(context, reason: 'default'),
            child: Text(l10n.settingsUpgrade),
          ),
        ),
      ],
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 0,
        children: [
          TextButton(
            style: buttonStyle,
            onPressed: () => _restore(context, ref),
            child: Text(l10n.settingsRestore),
          ),
          if (store == 'app_store' || store == 'play_store')
            TextButton(
              style: buttonStyle,
              onPressed: () => _openStore(context, store!),
              child: Text(l10n.settingsOpenStore),
            ),
        ],
      ),
    ]);
  }

  String _initial(AppUser user) {
    final name = user.name.trim();
    final source = name.isEmpty ? user.email : name;
    if (source.isEmpty) return '?';
    return String.fromCharCode(source.runes.first).toUpperCase();
  }

  List<String> _lines(AppLocalizations l10n, Billing billing, String locale) {
    final end = billing.subscription?.periodEnd;
    final formatted =
        end == null ? '' : DateFormat.yMMMd(locale).format(end.toLocal());
    return switch (billing.source) {
      'admin' => [l10n.settingsSourceAdmin],
      'trial' => [
        l10n.settingsSourceTrial(
          billing.trialDaysLeft ?? 0,
          billing.trialEndsAt == null
              ? ''
              : DateFormat.yMMMd(locale).format(billing.trialEndsAt!.toLocal()),
        ),
      ],
      'promo' => [
        '${l10n.settingsSourcePromo} · ${formatted.isEmpty ? l10n.settingsPromoForever : l10n.settingsPromoUntil(formatted)}',
      ],
      'subscription' => [
        l10n.settingsSourceSubscription(
          _product(l10n, billing.subscription?.productId),
        ),
        if (formatted.isNotEmpty)
          billing.subscription?.willRenew == false
              ? l10n.settingsEndsOn(formatted)
              : l10n.settingsRenews(formatted),
        billing.subscription?.fromStore == true
            ? l10n.settingsManageStore
            : l10n.settingsManageWeb,
      ],
      _ => [
        if (billing.hasLimits &&
            billing.projectLimit != null &&
            billing.historyDays != null)
          l10n.settingsFreeText(billing.projectLimit!, billing.historyDays!),
      ],
    };
  }

  String _product(AppLocalizations l10n, String? id) {
    return switch (id) {
      'pro_yearly' => l10n.settingsProductYearly,
      'pro_promo' => l10n.settingsProductGift,
      _ => l10n.settingsProductMonthly,
    };
  }
}

Future<void> _restore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final store = ref.read(storeBillingProvider);
  if (!store.enabled) {
    _snack(context, l10n.paywallStoreUnavailable);
    return;
  }
  final result = await store.restore();
  if (!context.mounted) return;
  if (result != StorePurchaseResult.purchased) {
    _snack(context, l10n.paywallPurchaseFailed);
    return;
  }
  await ref.read(authControllerProvider.notifier).refresh();
  if (!context.mounted) return;
  _snack(context, l10n.paywallRestored);
}

Future<void> _openStore(BuildContext context, String provider) async {
  final uri = Uri.parse(
    provider == 'play_store'
        ? 'https://play.google.com/store/account/subscriptions?package=com.onelineplanner.app'
        : 'https://apps.apple.com/account/subscriptions',
  );
  final l10n = AppLocalizations.of(context);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _snack(context, l10n.genericError);
    }
  } catch (_) {
    if (context.mounted) _snack(context, l10n.genericError);
  }
}

Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
  final hasPassword =
      ref.read(authControllerProvider).valueOrNull?.user.hasPassword ?? true;
  final password = await showDialog<String>(
    context: context,
    builder: (context) => _DeleteAccountDialog(requirePassword: hasPassword),
  );
  if (password == null || !context.mounted) return;
  if (hasPassword && password.isEmpty) return;
  try {
    await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: password, confirm: !hasPassword);
  } catch (error) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _snack(
      context,
      apiErrorMessage(error, l10n.networkError, l10n.genericError),
    );
  }
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requirePassword});

  final bool requirePassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DismissKeyboard(
      child: AlertDialog(
        scrollable: true,
        title: Text(l10n.settingsDeleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsDeleteAccountText),
            if (widget.requirePassword) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autofocus: true,
                scrollPadding: fieldScrollPadding,
                decoration: InputDecoration(
                  labelText: l10n.settingsDeletePassword,
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed:
                () => Navigator.pop(
                  context,
                  widget.requirePassword ? _password.text : '',
                ),
            child: Text(l10n.settingsDeleteConfirm),
          ),
        ],
      ),
    );
  }
}
