import '../features/plan/plan_time.dart';
import '../models/plan.dart';

class PlanAlert {
  const PlanAlert({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// One alert before a plan starts and one before it ends, inside the next 24 hours.
/// [notifyBeforeMin] of 0 schedules nothing.
List<PlanAlert> planAlerts({
  required List<PlanBlock> plans,
  required int notifyBeforeMin,
  required DateTime now,
  required String Function(String name, int minutes) startTitle,
  required String Function(String name, int minutes) endTitle,
  required String Function(String range) body,
  required String Function(String name, String time) nextLine,
}) {
  if (notifyBeforeMin <= 0 || plans.isEmpty) return const [];
  final horizon = now.add(const Duration(hours: 24));
  final sorted = [...plans]..sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.startMin.compareTo(b.startMin);
  });
  final alerts = <PlanAlert>[];
  for (final plan in sorted) {
    final start = planInstant(plan.date, plan.startMin);
    final end = planInstant(plan.date, plan.endMin);
    final range = '${fmtMin(plan.startMin)}–${fmtMin(plan.endMin)}';
    final next = _next(sorted, plan);
    final follow =
        next == null
            ? ''
            : ' ${nextLine(next.projectName, fmtMin(next.startMin))}';
    _add(
      alerts,
      id: plan.id * 2,
      when: start.subtract(Duration(minutes: notifyBeforeMin)),
      title: startTitle(plan.projectName, notifyBeforeMin),
      body: body(range),
      now: now,
      horizon: horizon,
    );
    _add(
      alerts,
      id: plan.id * 2 + 1,
      when: end.subtract(Duration(minutes: notifyBeforeMin)),
      title: endTitle(plan.projectName, notifyBeforeMin),
      body: body(range) + follow,
      now: now,
      horizon: horizon,
    );
  }
  return alerts;
}

PlanBlock? _next(List<PlanBlock> sorted, PlanBlock plan) {
  PlanBlock? next;
  for (final other in sorted) {
    if (other.date != plan.date || other.id == plan.id) continue;
    if (other.startMin < plan.endMin) continue;
    if (next == null || other.startMin < next.startMin) next = other;
  }
  return next;
}

void _add(
  List<PlanAlert> alerts, {
  required int id,
  required DateTime when,
  required String title,
  required String body,
  required DateTime now,
  required DateTime horizon,
}) {
  if (!when.isAfter(now) || when.isAfter(horizon)) return;
  alerts.add(
    PlanAlert(id: id & 0x7fffffff, when: when, title: title, body: body),
  );
}
