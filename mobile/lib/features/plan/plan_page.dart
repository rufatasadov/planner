import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../billing/paywall_sheet.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import 'day_column.dart';
import 'day_timeline.dart';
import 'generate_sheet.dart';
import 'plan_controller.dart';
import 'plan_repository.dart';
import 'plan_sheet.dart';
import 'plan_time.dart';
import 'plan_view.dart';
import 'tracking_panel.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = ref.watch(planControllerProvider);
    return Scaffold(
      floatingActionButton: day.maybeWhen(
        data:
            (value) =>
                value.locked
                    ? null
                    : _AddButton(
                      data: value,
                      onPressed: () => showPlanSheet(context, ref, value),
                    ),
        orElse: () => null,
      ),
      body: day.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => _ErrorPane(
              message: apiErrorMessage(
                error,
                l10n.networkError,
                l10n.genericError,
              ),
              onRetry: () => ref.read(planControllerProvider.notifier).reload(),
            ),
        data: (value) {
          final mode = ref.watch(planViewModeProvider);
          return Column(
            children: [
              SizedBox(
                height: 2,
                child:
                    value.refreshing
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh:
                      () => ref.read(planControllerProvider.notifier).reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      value.locked ? 24 : 88,
                    ),
                    children: [
                      _Head(
                        data: value,
                        onShift:
                            (days) => ref
                                .read(planControllerProvider.notifier)
                                .selectDate(
                                  value.date.add(Duration(days: days)),
                                ),
                      ),
                      const SizedBox(height: 8),
                      _WeekStrip(
                        data: value,
                        onSelect:
                            (date) => ref
                                .read(planControllerProvider.notifier)
                                .selectDate(date),
                      ),
                      const SizedBox(height: 14),
                      if (value.locked)
                        _LockCard(
                          message: l10n.planHistoryLocked,
                          action: l10n.paywallMore,
                          onAction: () => _paywall(context, ref, 'history'),
                        )
                      else ...[
                        _Schedule(
                          data: value,
                          mode: mode,
                          onSelect:
                              (plan) => ref
                                  .read(planControllerProvider.notifier)
                                  .selectPlan(plan.id),
                          selectedId: value.selectedId ?? _focusPlan(value)?.id,
                          onCreate:
                              (minute) => showPlanSheet(
                                context,
                                ref,
                                value,
                                preferredStart: minute,
                              ),
                          onMoved:
                              (plan, start, end) =>
                                  _move(context, ref, plan, start, end),
                          onEdit:
                              (plan) => _editPlan(context, ref, value, plan),
                        ),
                        const SizedBox(height: 12),
                        _Detail(data: value),
                        const SizedBox(height: 12),
                        PlanTicker(
                          builder:
                              (context, now) => _Stats(data: value, now: now),
                        ),
                        if (value.plans.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _Distribution(data: value),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                () => showGenerateSheet(context, ref, value),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(l10n.planCopyToWeek),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    PlanBlock plan,
    int start,
    int end,
  ) async {
    if (start == plan.startMin && end == plan.endMin) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(planRepositoryProvider).move(plan.id, start, end);
      await ref.read(planControllerProvider.notifier).reload();
    } catch (error) {
      await ref.read(planControllerProvider.notifier).reload();
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
}

int _nowMin() => DateTime.now().hour * 60 + DateTime.now().minute;

PlanBlock? _focusPlan(PlanScreenData data, [DateTime? clock]) {
  if (data.selected != null) return data.selected;
  if (!data.isToday) return null;
  final now = clock ?? DateTime.now();
  final minute = now.hour * 60 + now.minute;
  PlanBlock? next;
  for (final plan in data.plans) {
    if (plan.startMin <= minute && minute < plan.endMin) return plan;
    if (plan.startMin > minute &&
        (next == null || plan.startMin < next.startMin)) {
      next = plan;
    }
  }
  return next;
}

bool _dayIsFull(PlanScreenData data) {
  return nextFreeSlot(
        workStart: data.hours.startMin,
        workEnd: data.hours.endMin,
        blocks: [
          for (final plan in data.plans)
            (startMin: plan.startMin, endMin: plan.endMin),
        ],
        preferredStart: data.hours.startMin,
      ) ==
      null;
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.data, required this.onPressed});

  final PlanScreenData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _dayIsFull(data) ? 0.1 : 1,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: AppLocalizations.of(context).planAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

String formatPlanDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.planMinutes(rest);
  return l10n.planHours(hours, rest);
}

class _Schedule extends StatelessWidget {
  const _Schedule({
    required this.data,
    required this.mode,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    required this.onMoved,
    required this.onEdit,
  });

  final PlanScreenData data;
  final PlanViewMode mode;
  final int? selectedId;
  final ValueChanged<PlanBlock> onSelect;
  final ValueChanged<int> onCreate;
  final void Function(PlanBlock plan, int start, int end) onMoved;
  final ValueChanged<PlanBlock> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hint = switch (mode) {
      PlanViewMode.strip => l10n.planViewStripHint,
      PlanViewMode.column => l10n.planViewColumnHint,
      PlanViewMode.fit => l10n.planViewFitHint,
    };
    final plans = [...data.plans]
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final now = data.isToday ? _nowMin() : null;
    return _SectionCard(
      title: l10n.planSchedule,
      subtitle: hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == PlanViewMode.column)
            DayColumn(
              plans: plans,
              startMin: data.hours.startMin,
              endMin: data.hours.endMin,
              nowMin: now,
              selectedId: selectedId,
              onSelect: onSelect,
              onCreate: onCreate,
              onMoved: onMoved,
              onEdit: onEdit,
            )
          else
            DayTimeline(
              key: ValueKey('${ymd(data.date)}-$mode'),
              plans: plans,
              startMin: data.hours.startMin,
              endMin: data.hours.endMin,
              nowMin: now,
              selectedId: selectedId,
              fitWidth: mode == PlanViewMode.fit,
              onSelect: onSelect,
              onCreate: onCreate,
              onMoved: onMoved,
              onEdit: onEdit,
            ),
          if (mode != PlanViewMode.column && plans.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _AgendaRow(
                plan: plans[i],
                selected: plans[i].id == selectedId,
                duration: formatPlanDuration(l10n, plans[i].durationMin),
                onTap: () => onSelect(plans[i]),
                onLongPress: () => onEdit(plans[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.plan,
    required this.selected,
    required this.duration,
    required this.onTap,
    required this.onLongPress,
  });

  final PlanBlock plan;
  final bool selected;
  final String duration;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? plan.color.withValues(alpha: 0.12) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color:
              selected
                  ? plan.color
                  : Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: plan.color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${fmtMin(plan.startMin)} – ${fmtMin(plan.endMin)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                duration,
                style: TextStyle(fontSize: 12, color: mutedColor(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.data, required this.onShift});

  final PlanScreenData data;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final span = (data.hours.endMin - data.hours.startMin).clamp(1, 1440);
    final progress =
        !data.isToday
            ? (ymd(data.date).compareTo(ymd(DateTime.now())) < 0 ? 1.0 : 0.0)
            : ((_nowMin() - data.hours.startMin) / span).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            _arrow(Icons.chevron_left_rounded, () => onShift(-1)),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat.MMMEd(locale).format(data.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: mutedColor(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!data.isToday)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed:
                    () => onShift(
                      dateOnly(
                        DateTime.now(),
                      ).difference(dateOnly(data.date)).inDays,
                    ),
                child: Text(l10n.planToday),
              ),
            _arrow(Icons.chevron_right_rounded, () => onShift(1)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: const Color(0x338B94B8),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: data.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final days = dateOnly(picked).difference(dateOnly(data.date)).inDays;
    if (days != 0) onShift(days);
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.data, required this.onSelect});

  final PlanScreenData data;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final monday = data.date.subtract(Duration(days: data.date.weekday - 1));
    final locale = Localizations.localeOf(context).toString();
    final names = DateFormat.E(locale);
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(child: _day(context, monday.add(Duration(days: i)), names)),
      ],
    );
  }

  Widget _day(BuildContext context, DateTime date, DateFormat names) {
    final key = ymd(date);
    final selected = key == ymd(data.date);
    final today = key == ymd(DateTime.now());
    final locked = historyLocked(key, data.historyStart);
    final items = data.weekPlans.where((plan) => plan.date == key).toList();
    final minutes = items.fold<int>(0, (sum, plan) => sum + plan.durationMin);
    final work = (data.hours.endMin - data.hours.startMin).clamp(1, 1440);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color:
            selected ? scheme.primary.withValues(alpha: 0.16) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color:
                selected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: InkWell(
          onTap: () => onSelect(date),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              children: [
                Text(
                  names.format(date),
                  style: TextStyle(fontSize: 11, color: mutedColor(context)),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: today ? scheme.primary : null,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 4,
                    child: Row(
                      children: [
                        for (final plan in items)
                          if (plan.durationMin > 0)
                            Expanded(
                              flex: plan.durationMin,
                              child: ColoredBox(color: plan.color),
                            ),
                        if (work > minutes)
                          Expanded(
                            flex: work - minutes,
                            child: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (locked)
                  Icon(Icons.lock, size: 12, color: mutedColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.data});

  final PlanScreenData data;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  int? _minute;
  var _caughtUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _catchUp());
  }

  void _catchUp() {
    if (!mounted ||
        _caughtUp ||
        !widget.data.isToday ||
        !widget.data.hours.autoStop) {
      return;
    }
    _caughtUp = true;
    final minute = DateTime.now().hour * 60 + DateTime.now().minute;
    final stale = widget.data.plans.any(
      (plan) => plan.endMin <= minute && plan.tracking.state == 'running',
    );
    if (stale) ref.read(planControllerProvider.notifier).reload();
  }

  void _onMinute(DateTime now) {
    if (!widget.data.isToday) return;
    final minute = now.hour * 60 + now.minute;
    final previous = _minute;
    _minute = minute;
    if (previous == null || previous == minute) return;
    final crossed = widget.data.plans.where(
      (plan) => plan.endMin > previous && plan.endMin <= minute,
    );
    if (crossed.isEmpty) return;
    final selected = widget.data.selected;
    if (selected != null && crossed.any((plan) => plan.id == selected.id)) {
      ref.read(planControllerProvider.notifier).clearSelection();
    }
    if (widget.data.hours.autoStop) {
      ref.read(planControllerProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return PlanTicker(
      onTick: _onMinute,
      builder: (context, now) {
        final l10n = AppLocalizations.of(context);
        final plan = _focusPlan(data, now);
        if (plan == null) {
          if (data.isToday && data.plans.isNotEmpty) {
            return _NoActive(message: l10n.planNoActive);
          }
          return _SectionCard(
            title: data.plans.isEmpty ? l10n.planEmpty : l10n.planSelectBlock,
            child: const SizedBox.shrink(),
          );
        }
        return _detailCard(context, data, plan, now);
      },
    );
  }

  Widget _detailCard(
    BuildContext context,
    PlanScreenData data,
    PlanBlock plan,
    DateTime now,
  ) {
    final l10n = AppLocalizations.of(context);
    final minute = now.hour * 60 + now.minute;
    final second = minute * 60 + now.second;
    final current = plan.startMin <= minute && minute < plan.endMin;
    final upcoming = minute < plan.startMin;
    PlanBlock? after;
    if (current) {
      for (final other in data.plans) {
        if (other.startMin > minute &&
            (after == null || other.startMin < after.startMin)) {
          after = other;
        }
      }
    }
    final remaining =
        current ? plan.endMin * 60 - second : plan.startMin * 60 - second;
    final total = current ? plan.durationMin * 60 : _untilStart(plan, minute);
    final safeTotal = total <= 0 ? 1 : total;
    final left = remaining.clamp(0, safeTotal);
    final warning = current && left <= data.hours.notifyBeforeMin * 60;
    final color = warning ? const Color(0xFFF43F5E) : plan.color;
    final done = plan.tasks.where((task) => task.done).length;
    return GestureDetector(
      onLongPress: () => _editPlan(context, ref, data, plan),
      child: _SectionCard(
        title: plan.projectName,
        subtitle:
            '${fmtMin(plan.startMin)} – ${fmtMin(plan.endMin)} · ${formatPlanDuration(l10n, plan.durationMin)}',
        trailing: _PlanActions(data: data, plan: plan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current || upcoming) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: (safeTotal - left) / safeTotal,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                backgroundColor: color.withValues(alpha: 0.15),
                                color: color,
                              ),
                            ),
                            Text(
                              fmtClock(left),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        current ? l10n.planLeft : l10n.planUntilStart,
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current ? l10n.planNow : l10n.planNext,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (current && after != null)
                          Text(
                            '${l10n.planThen}: ${after.projectName} · ${fmtMin(after.startMin)}',
                            style: TextStyle(color: mutedColor(context)),
                          ),
                        if (warning)
                          Text(
                            l10n.planAlmostOver,
                            style: const TextStyle(
                              color: Color(0xFFF43F5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (plan.note.isNotEmpty) ...[
              Text(plan.note),
              const SizedBox(height: 8),
            ],
            TrackingPanel(
              plan: plan,
              loadedAt: data.loadedAt,
              autoStop: data.hours.autoStop,
              targetPct: data.hours.targetEfficiencyPct,
            ),
            const SizedBox(height: 14),
            _TasksLink(plan: plan, done: done),
          ],
        ),
      ),
    );
  }

  int _untilStart(PlanBlock plan, int minute) {
    final data = widget.data;
    var prevEnd = data.hours.startMin;
    for (final other in data.plans) {
      if (other.endMin <= plan.startMin && other.endMin > prevEnd) {
        prevEnd = other.endMin;
      }
    }
    final from = prevEnd < minute ? prevEnd : minute;
    final gap = (plan.startMin - from) * 60;
    return gap < 1 ? 1 : gap;
  }
}

void _editPlan(
  BuildContext context,
  WidgetRef ref,
  PlanScreenData data,
  PlanBlock plan,
) {
  HapticFeedback.mediumImpact();
  showPlanSheet(context, ref, data, editing: plan);
}

class _PlanActions extends ConsumerWidget {
  const _PlanActions({required this.data, required this.plan});

  final PlanScreenData data;
  final PlanBlock plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _action(
          l10n.planEdit,
          Icons.edit_outlined,
          () => showPlanSheet(context, ref, data, editing: plan),
        ),
        _action(
          l10n.planPostpone,
          Icons.skip_next_outlined,
          () => showPostponeSheet(context, ref, plan),
        ),
        _action(l10n.planDelete, Icons.delete_outline, () async {
          await ref.read(planRepositoryProvider).delete(plan.id);
          await ref.read(planControllerProvider.notifier).reload();
        }),
      ],
    );
  }

  Widget _action(String tooltip, IconData icon, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

class _TasksLink extends StatelessWidget {
  const _TasksLink({required this.plan, required this.done});

  final PlanBlock plan;
  final int done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = plan.tasks.length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/plans/${plan.id}/tasks'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Icon(Icons.checklist_rounded, size: 20, color: plan.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.planTasks,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 4,
                          color: plan.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$done/$total',
                  style: TextStyle(fontSize: 12, color: mutedColor(context)),
                ),
                Icon(Icons.chevron_right_rounded, color: mutedColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.data, required this.now});

  final PlanScreenData data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final planned = data.plans.fold<int>(
      0,
      (sum, plan) => sum + plan.durationMin,
    );
    final work = (data.hours.endMin - data.hours.startMin).clamp(1, 1440);
    final tasks = {
      for (final plan in data.plans)
        for (final task in plan.tasks) task.id: task,
    };
    final done = tasks.values.where((task) => task.done).length;
    var effective = 0;
    var breaks = 0;
    var base = 0;
    for (final plan in data.plans) {
      final live = liveTracking(plan.tracking, now, data.loadedAt);
      effective += live.effectiveSec;
      breaks += live.breakSec;
      base += elapsedPlanSec(plan.date, plan.startMin, plan.endMin, now);
    }
    final efficiency = efficiencyPct(effective, base);
    final tiles = [
      _stat(
        context,
        l10n.planPlanned,
        formatPlanDuration(l10n, planned),
        planned / work,
      ),
      _stat(
        context,
        l10n.planFreeTime,
        formatPlanDuration(l10n, (work - planned).clamp(0, work).toInt()),
        (work - planned).clamp(0, work) / work,
      ),
      _stat(
        context,
        l10n.planTasks,
        '$done/${tasks.length}',
        tasks.isEmpty ? 0 : done / tasks.length,
      ),
      _stat(
        context,
        l10n.trackEffective,
        fmtClock(effective),
        planned == 0 ? 0 : (effective / 60) / planned,
      ),
      _stat(
        context,
        l10n.trackBreaks,
        fmtClock(breaks),
        planned == 0 ? 0 : (breaks / 60) / planned,
      ),
      _stat(
        context,
        l10n.trackEfficiency,
        efficiency == null ? '—' : '$efficiency%',
        (efficiency ?? 0) / 100,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value,
    double fraction,
  ) {
    return _SectionCard(
      title: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: fraction.clamp(0, 1), minHeight: 6),
        ],
      ),
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.data});

  final PlanScreenData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grouped = <int, ({String name, Color color, int minutes})>{};
    for (final plan in data.plans) {
      final current = grouped[plan.projectId];
      grouped[plan.projectId] = (
        name: plan.projectName,
        color: plan.color,
        minutes: (current?.minutes ?? 0) + plan.durationMin,
      );
    }
    final slices =
        grouped.values.toList()..sort((a, b) => b.minutes.compareTo(a.minutes));
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.minutes);
    final work = (data.hours.endMin - data.hours.startMin).clamp(1, 1440);
    return _SectionCard(
      title: l10n.planDistribution,
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: CustomPaint(
              painter: _DonutPainter(
                slices
                    .map((slice) => (slice.color, slice.minutes / total))
                    .toList(),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatPlanDuration(l10n, total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      l10n.planFilled(((total / work) * 100).round()),
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                for (final slice in slices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slice.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatPlanDuration(l10n, slice.minutes),
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor(context),
                          ),
                        ),
                      ],
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

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.slices);

  final List<(Color, double)> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.$2 * math.pi * 2;
      paint.color = slice.$1;
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _NoActive extends StatelessWidget {
  const _NoActive({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            const Text('☕', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor(context), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: mutedColor(context),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (child is! SizedBox) const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

void _paywall(BuildContext context, WidgetRef ref, String reason) {
  final billing = ref.read(authControllerProvider).valueOrNull?.user.billing;
  showPaywall(
    context,
    reason: reason,
    projectLimit: billing?.projectLimit,
    historyDays: billing?.historyDays,
  );
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.message,
    required this.action,
    required this.onAction,
  });

  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 36, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor(context), height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).planRetry),
            ),
          ],
        ),
      ),
    );
  }
}
