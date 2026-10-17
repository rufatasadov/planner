import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../notifications/plan_alert_service.dart';
import '../../prefs.dart';
import '../plan/plan_repository.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/logo.dart';

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    return Scaffold(
      body: Column(
        children: [
          const _AlertRefresh(),
          const _AppBar(),
          if (user != null && !user.emailVerified)
            _VerifyBanner(email: user.email),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _TabBar(
        index: navigationShell.currentIndex,
        onSelect:
            (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
        items: [
          _TabItem(
            icon: Icons.calendar_view_day_outlined,
            activeIcon: Icons.calendar_view_day_rounded,
            label: l10n.tabPlan,
          ),
          _TabItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: l10n.tabProjects,
          ),
          _TabItem(
            icon: Icons.sticky_note_2_outlined,
            activeIcon: Icons.sticky_note_2_rounded,
            label: l10n.tabNotes,
          ),
          _TabItem(
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune_rounded,
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

class _AlertRefresh extends ConsumerStatefulWidget {
  const _AlertRefresh();

  @override
  ConsumerState<_AlertRefresh> createState() => _AlertRefreshState();
}

class _AlertRefreshState extends ConsumerState<_AlertRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authControllerProvider).valueOrNull != null) {
      unawaited(
        ref
            .read(planAlertServiceProvider)
            .sync(
              ref.read(planRepositoryProvider),
              ref.read(prefsProvider).locale,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull == null) {
        unawaited(ref.read(planAlertServiceProvider).clear());
      }
    });
    return const SizedBox.shrink();
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.onSelect,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<_TabItem> items;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF121933) : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 6, 8, bottom + 6),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(
                  item: items[i],
                  selected: i == index,
                  onTap: () {
                    if (i != index) HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF6366F1) : mutedColor(context);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color:
                  selected
                      ? const Color(0xFF6366F1).withValues(alpha: 0.16)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends ConsumerWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              const AppLogo(size: 30),
              const Spacer(),
              if (user != null)
                Flexible(
                  child: Text(
                    user.billing.badge(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color:
                          user.billing.isPro ? const Color(0xFF8B5CF6) : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                onPressed:
                    () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyBanner extends ConsumerStatefulWidget {
  const _VerifyBanner({required this.email});

  final String email;

  @override
  ConsumerState<_VerifyBanner> createState() => _VerifyBannerState();
}

class _VerifyBannerState extends ConsumerState<_VerifyBanner> {
  var _busy = false;

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resent)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiErrorMessage(e, l10n.networkError, l10n.genericError),
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
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.verifyBanner(widget.email),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: Text(l10n.resend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
