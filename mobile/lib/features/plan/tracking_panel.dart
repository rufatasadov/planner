import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import 'plan_controller.dart';
import 'plan_repository.dart';
import 'plan_time.dart';

class PlanTicker extends StatefulWidget {
  const PlanTicker({super.key, required this.builder, this.onTick});

  final Widget Function(BuildContext context, DateTime now) builder;
  final ValueChanged<DateTime>? onTick;

  @override
  State<PlanTicker> createState() => _PlanTickerState();
}

class _PlanTickerState extends State<PlanTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    final framing =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.transientCallbacks;
    if (framing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onTick?.call(DateTime.now());
        setState(() {});
      });
      return;
    }
    widget.onTick?.call(DateTime.now());
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

class TrackingPanel extends ConsumerStatefulWidget {
  const TrackingPanel({
    super.key,
    required this.plan,
    required this.loadedAt,
    required this.autoStop,
    required this.targetPct,
    this.compact = false,
  });

  final PlanBlock plan;
  final DateTime loadedAt;
  final bool autoStop;
  final int targetPct;
  final bool compact;

  @override
  ConsumerState<TrackingPanel> createState() => _TrackingPanelState();
}

class _TrackingPanelState extends ConsumerState<TrackingPanel> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      await ref.read(planControllerProvider.notifier).reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiErrorMessage(error, l10n.networkError, l10n.trackFailed),
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
    if (widget.plan.date.compareTo(ymd(DateTime.now())) > 0) {
      return const SizedBox.shrink();
    }
    return PlanTicker(
      builder: (context, now) {
        final l10n = AppLocalizations.of(context);
        final end = planInstant(widget.plan.date, widget.plan.endMin);
        final ended = widget.autoStop && !now.isBefore(end);
        final clock = ended && now.isAfter(end) ? end : now;
        final live = liveTracking(widget.plan.tracking, clock, widget.loadedAt);
        final running = live.state == 'running' && !ended;
        final pct = efficiencyPct(
          live.effectiveSec,
          elapsedPlanSec(
            widget.plan.date,
            widget.plan.startMin,
            widget.plan.endMin,
            now,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (running)
                  _TrackButton(
                    label: l10n.trackPause,
                    icon: Icons.pause_rounded,
                    background: const Color(0xFFF59E0B),
                    foreground: const Color(0xFF1F1300),
                    busy: _busy,
                    onPressed:
                        () => _run(
                          () => ref
                              .read(planRepositoryProvider)
                              .pauseTracking(widget.plan.id),
                        ),
                  )
                else if (!ended)
                  _TrackButton(
                    label:
                        live.state == 'not_started'
                            ? l10n.trackStart
                            : l10n.trackResume,
                    icon: Icons.play_arrow_rounded,
                    background: const Color(0xFF22C55E),
                    foreground: Colors.white,
                    busy: _busy,
                    onPressed:
                        () => _run(
                          () => ref
                              .read(planRepositoryProvider)
                              .startTracking(widget.plan.id),
                        ),
                  )
                else
                  Text(
                    l10n.trackEnded,
                    style: TextStyle(color: mutedColor(context)),
                  ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (running) ...[
                          const Icon(
                            Icons.fiber_manual_record,
                            size: 10,
                            color: Color(0xFFF43F5E),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          fmtClock(live.effectiveSec),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.trackEffective,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (live.state == 'paused') ...[
              const SizedBox(height: 8),
              Text(
                '☕ ${l10n.trackOnBreak(fmtClock(live.currentBreakSec))}',
                style: TextStyle(color: mutedColor(context)),
              ),
            ],
            if (!widget.compact) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _metric(context, l10n.trackBreaks, fmtClock(live.breakSec)),
                  _metric(
                    context,
                    l10n.trackSessions,
                    '${widget.plan.tracking.sessionCount}',
                  ),
                  _metric(
                    context,
                    l10n.trackEfficiency,
                    pct == null ? '—' : '$pct%',
                    valueColor: _effColor(pct, widget.targetPct),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _EfficiencyBar(
                pct: pct ?? 0,
                target: widget.targetPct,
                color: _effColor(pct, widget.targetPct),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: mutedColor(context)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: busy ? background.withValues(alpha: 0.55) : background,
      borderRadius: BorderRadius.circular(999),
      elevation: 0,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child:
                    busy
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                        : Icon(icon, size: 22, color: foreground),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _effColor(int? pct, int target) {
  if (pct == null) return const Color(0xFF8B94B8);
  if (pct >= target) return const Color(0xFF22C55E);
  if (pct >= target * 0.75) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

class _EfficiencyBar extends StatelessWidget {
  const _EfficiencyBar({
    required this.pct,
    required this.target,
    required this.color,
  });

  final int pct;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (pct.clamp(0, 100)) / 100,
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0x338B94B8),
            ),
          ),
          Align(
            alignment: Alignment((target.clamp(0, 100) / 50) - 1, 0),
            child: Container(
              width: 2,
              height: 8,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPostponeSheet(
  BuildContext context,
  WidgetRef ref,
  PlanBlock plan,
) async {
  final l10n = AppLocalizations.of(context);
  final days = await showModalBottomSheet<int>(
    context: context,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planPostpone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(context, l10n.planPostponeToday, 0),
                    _chip(context, l10n.planPostponeTomorrow, 1),
                    _chip(context, l10n.planPostponeIn2, 2),
                    _chip(context, l10n.planPostponeWeek, 7),
                  ],
                ),
              ],
            ),
          ),
        ),
  );
  if (days == null || !context.mounted) return;
  final target = dateOnly(planInstant(plan.date, 0)).add(Duration(days: days));
  try {
    await ref
        .read(planRepositoryProvider)
        .postpone(plan.id, ymd(target), plan.startMin, plan.endMin);
    await ref.read(planControllerProvider.notifier).reload();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.planPostponed)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(error, l10n.networkError, l10n.genericError),
          ),
        ),
      );
    }
  }
}

Widget _chip(BuildContext context, String label, int days) {
  return ActionChip(
    label: Text(label),
    onPressed: () => Navigator.of(context).pop(days),
  );
}
