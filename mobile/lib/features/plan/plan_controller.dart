import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan.dart';
import '../../notifications/plan_alert_service.dart';
import '../../prefs.dart';
import 'plan_repository.dart';
import 'plan_time.dart';

class PlanScreenData {
  const PlanScreenData({
    required this.date,
    required this.weekPlans,
    required this.historyStart,
    required this.hours,
    required this.loadedAt,
    this.selectedId,
    this.refreshing = false,
  });

  final DateTime date;
  final List<PlanBlock> weekPlans;
  final String? historyStart;
  final WorkHours hours;
  final DateTime loadedAt;
  final int? selectedId;
  final bool refreshing;

  List<PlanBlock> get plans =>
      weekPlans.where((plan) => plan.date == ymd(date)).toList();

  bool get locked => historyLocked(ymd(date), historyStart);

  bool get isToday => ymd(date) == ymd(DateTime.now());

  PlanBlock? get selected {
    for (final plan in plans) {
      if (plan.id == selectedId) return plan;
    }
    return null;
  }

  PlanScreenData copy({
    DateTime? date,
    List<PlanBlock>? weekPlans,
    int? selectedId,
    bool clearSelection = false,
    bool? refreshing,
  }) {
    return PlanScreenData(
      date: date ?? this.date,
      weekPlans: weekPlans ?? this.weekPlans,
      historyStart: historyStart,
      hours: hours,
      loadedAt: loadedAt,
      refreshing: refreshing ?? this.refreshing,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    );
  }
}

final planControllerProvider =
    AsyncNotifierProvider<PlanController, PlanScreenData>(PlanController.new);

class PlanController extends AsyncNotifier<PlanScreenData> {
  DateTime date = dateOnly(DateTime.now());
  int? selectedId;
  int _ticket = 0;
  final _statusTicket = <int, int>{};

  /// Shows [status] immediately, then saves it. A newer change wins; a failed
  /// save puts this task back only when nothing newer replaced it.
  Future<void> updateTaskStatus(int taskId, String status) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final previous = _statusOf(current.weekPlans, taskId);
    if (previous == null || previous == status) return;
    final ticket = (_statusTicket[taskId] ?? 0) + 1;
    _statusTicket[taskId] = ticket;
    state = AsyncData(
      current.copy(
        weekPlans: plansWithTaskStatus(current.weekPlans, taskId, status),
      ),
    );
    try {
      final result = await ref
          .read(planRepositoryProvider)
          .setTaskStatus(taskId, status);
      if (_statusTicket[taskId] != ticket) return;
      final latest = state.valueOrNull;
      final parentId = result.parentId;
      final parentStatus = result.parentStatus;
      if (latest == null || parentId == null || parentStatus == null) return;
      state = AsyncData(
        latest.copy(
          weekPlans: plansWithTaskStatus(
            latest.weekPlans,
            parentId,
            parentStatus,
          ),
        ),
      );
    } catch (error) {
      if (_statusTicket[taskId] == ticket) {
        final latest = state.valueOrNull;
        if (latest != null) {
          state = AsyncData(
            latest.copy(
              weekPlans: plansWithTaskStatus(
                latest.weekPlans,
                taskId,
                previous,
              ),
            ),
          );
        }
      }
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  @override
  Future<PlanScreenData> build() async {
    final data = await _load();
    _scheduleAlerts();
    return data;
  }

  void _scheduleAlerts() {
    unawaited(
      ref
          .read(planAlertServiceProvider)
          .sync(
            ref.read(planRepositoryProvider),
            ref.read(prefsProvider).locale,
          ),
    );
  }

  Future<void> selectDate(DateTime next) async {
    date = dateOnly(next);
    selectedId = null;
    final current = state.valueOrNull;
    if (current == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(
        current.copy(date: date, clearSelection: true, refreshing: true),
      );
    }
    await _refresh();
  }

  void clearSelection() {
    final current = state.valueOrNull;
    if (current == null || current.selectedId == null) return;
    selectedId = null;
    state = AsyncData(current.copy(clearSelection: true));
  }

  void selectPlan(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    selectedId = id;
    state = AsyncData(current.copy(selectedId: id));
  }

  Future<void> reload() async {
    final current = state.valueOrNull;
    if (current == null) {
      state = const AsyncLoading();
    } else if (!current.refreshing) {
      state = AsyncData(current.copy(refreshing: true));
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    final ticket = ++_ticket;
    final result = await AsyncValue.guard(_load);
    if (ticket != _ticket) return;
    final current = state.valueOrNull;
    if (result.hasError && current != null) {
      if (current.refreshing) {
        state = AsyncData(current.copy(refreshing: false));
      }
      return;
    }
    state = result;
    if (result.hasValue) _scheduleAlerts();
  }

  Future<PlanScreenData> _load() async {
    final repo = ref.read(planRepositoryProvider);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final results = await Future.wait([
      repo.range(ymd(monday), ymd(sunday)),
      repo.hours(),
    ]);
    final week = results[0] as DayResult;
    return PlanScreenData(
      date: date,
      weekPlans: week.plans,
      historyStart: week.historyStart,
      hours: results[1] as WorkHours,
      loadedAt: DateTime.now(),
      selectedId: selectedId,
    );
  }
}

String? _statusOf(List<PlanBlock> plans, int taskId) {
  for (final plan in plans) {
    for (final task in plan.tasks) {
      if (task.id == taskId) return task.status;
    }
  }
  return null;
}
