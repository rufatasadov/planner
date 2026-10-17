import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../billing/store_billing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../theme.dart';

Future<void> showPaywall(
  BuildContext context, {
  required String reason,
  int? projectLimit,
  int? historyDays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder:
        (context) => _Paywall(
          reason: reason,
          projects: projectLimit ?? 3,
          days: historyDays ?? 14,
        ),
  );
}

class _Paywall extends ConsumerStatefulWidget {
  const _Paywall({
    required this.reason,
    required this.projects,
    required this.days,
  });

  final String reason;
  final int projects;
  final int days;

  @override
  ConsumerState<_Paywall> createState() => _PaywallState();
}

class _PaywallState extends ConsumerState<_Paywall> {
  List<StoreOffer> _offers = [];
  String? _selected;
  var _loading = true;
  var _busy = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = ref.read(storeBillingProvider);
    if (!store.enabled) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final user = ref.read(authControllerProvider).valueOrNull?.user;
      if (user != null) await store.identify(user.id.toString());
      final offers = await store.offers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _selected =
            offers.any((offer) => offer.productId == 'pro_yearly')
                ? 'pro_yearly'
                : offers.firstOrNull?.productId;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy() async {
    StoreOffer? offer;
    for (final item in _offers) {
      if (item.productId == _selected) offer = item;
    }
    final l10n = AppLocalizations.of(context);
    if (offer == null) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    final result = await ref.read(storeBillingProvider).buy(offer);
    if (!mounted) return;
    if (result == StorePurchaseResult.cancelled) {
      setState(() => _busy = false);
      return;
    }
    if (result != StorePurchaseResult.purchased) {
      setState(() {
        _busy = false;
        _note = l10n.paywallPurchaseFailed;
      });
      return;
    }
    await _waitForPro();
    if (!mounted) return;
    final subscription =
        ref
            .read(authControllerProvider)
            .valueOrNull
            ?.user
            .billing
            .subscription;
    if (subscription?.fromStore == true) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _note = l10n.paywallPurchased;
    });
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _note = null;
    });
    final result = await ref.read(storeBillingProvider).restore();
    if (!mounted) return;
    if (result != StorePurchaseResult.purchased) {
      setState(() {
        _busy = false;
        _note = l10n.paywallPurchaseFailed;
      });
      return;
    }
    await _waitForPro();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = l10n.paywallRestored;
    });
  }

  Future<void> _waitForPro() async {
    final auth = ref.read(authControllerProvider.notifier);
    for (var i = 0; i < 5; i++) {
      await auth.refresh();
      final billing =
          ref.read(authControllerProvider).valueOrNull?.user.billing;
      if (billing?.subscription?.fromStore == true) return;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final billing = ref.watch(authControllerProvider).valueOrNull?.user.billing;
    final canBuy =
        billing == null || !billing.isPro || billing.source == 'trial';
    final store = ref.watch(storeBillingProvider);
    final title =
        widget.reason == 'projects'
            ? l10n.paywallProjectsTitle
            : widget.reason == 'history'
            ? l10n.paywallHistoryTitle
            : l10n.paywallDefaultTitle;
    final text =
        widget.reason == 'projects'
            ? l10n.paywallProjectsText(widget.projects)
            : widget.reason == 'history'
            ? l10n.paywallHistoryText(widget.days)
            : l10n.paywallDefaultText;
    final rows = [
      (
        l10n.paywallFeatureProjects,
        '${widget.projects}',
        l10n.paywallUnlimited,
      ),
      (
        l10n.paywallFeatureHistory,
        l10n.paywallDays(widget.days),
        l10n.paywallUnlimited,
      ),
      (l10n.paywallFeatureTimeline, '✓', '✓'),
      (l10n.paywallFeatureTracking, '✓', '✓'),
      (l10n.paywallFeatureNotes, '✓', '✓'),
      (l10n.paywallFeatureCalendar, '—', l10n.paywallSoon),
      (l10n.paywallFeatureExport, '—', l10n.paywallSoon),
      (l10n.paywallFeatureTemplates, '—', l10n.paywallSoon),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: mutedColor(context), height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  child: Text(
                    l10n.planFree,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.planPro,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(row.$1)),
                    Expanded(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedColor(context)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ..._purchase(context, l10n, billing, canBuy, store.enabled),
            FilledButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(l10n.paywallClose),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _purchase(
    BuildContext context,
    AppLocalizations l10n,
    Billing? billing,
    bool canBuy,
    bool storeEnabled,
  ) {
    if (!canBuy) {
      final provider = billing?.subscription?.provider;
      final note = provider == 'paddle' ? l10n.settingsManageWeb : null;
      if (note == null && !storeEnabled) return const [];
      return [
        if (note != null)
          Text(
            note,
            style: TextStyle(color: mutedColor(context), height: 1.35),
          ),
        if (storeEnabled)
          TextButton(
            onPressed: _busy ? null : _restore,
            child: Text(l10n.paywallRestore),
          ),
        const SizedBox(height: 8),
      ];
    }
    if (!storeEnabled) {
      return [
        Text(
          l10n.paywallStoreUnavailable,
          style: TextStyle(color: mutedColor(context), height: 1.35),
        ),
        const SizedBox(height: 12),
      ];
    }
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_offers.isEmpty) {
      return [
        Text(
          l10n.paywallPriceUnavailable,
          style: TextStyle(color: mutedColor(context), height: 1.35),
        ),
        TextButton(
          onPressed: _busy ? null : _restore,
          child: Text(l10n.paywallRestore),
        ),
        const SizedBox(height: 8),
      ];
    }
    return [
      Row(
        children: [
          for (final offer in _offers) ...[
            if (offer != _offers.first) const SizedBox(width: 8),
            Expanded(child: _offerCard(context, l10n, offer)),
          ],
        ],
      ),
      if (_note != null) ...[
        const SizedBox(height: 8),
        Text(_note!, style: TextStyle(color: mutedColor(context))),
      ],
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _busy ? null : _buy,
        child:
            _busy
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
                : Text(l10n.paywallBuy),
      ),
      TextButton(
        onPressed: _busy ? null : _restore,
        child: Text(l10n.paywallRestore),
      ),
      const SizedBox(height: 4),
    ];
  }

  Widget _offerCard(
    BuildContext context,
    AppLocalizations l10n,
    StoreOffer offer,
  ) {
    final selected = offer.productId == _selected;
    final scheme = Theme.of(context).colorScheme;
    final title =
        offer.productId == 'pro_yearly'
            ? l10n.paywallYearly
            : l10n.paywallMonthly;
    return Material(
      color:
          selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy ? null : () => setState(() => _selected = offer.productId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(offer.price, style: TextStyle(color: mutedColor(context))),
            ],
          ),
        ),
      ),
    );
  }
}
