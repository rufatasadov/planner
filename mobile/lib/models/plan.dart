import 'package:flutter/material.dart';

class PlanTask {
  const PlanTask({
    required this.id,
    required this.title,
    required this.status,
    this.parentId,
    this.parentTitle = '',
    this.noteCount = 0,
    this.position = 0,
    this.subtaskCount = 0,
    this.subtaskDone = 0,
    this.createdAt,
  });

  final int id;
  final String title;
  final String status;
  final int? parentId;
  final String parentTitle;
  final int noteCount;
  final int position;
  final int subtaskCount;
  final int subtaskDone;
  final DateTime? createdAt;

  bool get done => status == 'done';

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      parentId: (json['parent_id'] as num?)?.toInt(),
      parentTitle: json['parent_title'] as String? ?? '',
      noteCount: (json['note_count'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
      subtaskCount: (json['subtask_count'] as num?)?.toInt() ?? 0,
      subtaskDone: (json['subtask_done'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  PlanTask copyWith({
    String? title,
    String? status,
    int? subtaskDone,
    int? position,
    int? noteCount,
    String? parentTitle,
  }) {
    return PlanTask(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      parentId: parentId,
      parentTitle: parentTitle ?? this.parentTitle,
      noteCount: noteCount ?? this.noteCount,
      position: position ?? this.position,
      subtaskCount: subtaskCount,
      subtaskDone: subtaskDone ?? this.subtaskDone,
      createdAt: createdAt,
    );
  }
}

class TaskNode {
  const TaskNode(this.task, this.children);

  final PlanTask task;
  final List<PlanTask> children;
}

/// Top-level tasks with their children. A subtask whose parent is not in the
/// list stays at the top level and keeps [PlanTask.parentTitle].
List<TaskNode> taskTree(List<PlanTask> tasks) {
  final ids = {for (final task in tasks) task.id};
  final children = <int, List<PlanTask>>{};
  final roots = <PlanTask>[];
  for (final task in tasks) {
    final parentId = task.parentId;
    if (parentId != null && ids.contains(parentId)) {
      (children[parentId] ??= []).add(task);
    } else {
      roots.add(task);
    }
  }
  int byPosition(PlanTask a, PlanTask b) => a.position.compareTo(b.position);
  roots.sort(byPosition);
  for (final list in children.values) {
    list.sort(byPosition);
  }
  return [
    for (final task in roots) TaskNode(task, children[task.id] ?? const []),
  ];
}

/// Moves [visible] item [from] onto [to], keeping hidden siblings in place.
/// [to] greater than [from] lands after that row. A smaller [to] lands before it.
List<int> moveVisibleSibling({
  required List<PlanTask> siblings,
  required List<PlanTask> visible,
  required int from,
  required int to,
}) {
  final unchanged = [for (final task in siblings) task.id];
  if (from == to ||
      from < 0 ||
      to < 0 ||
      from >= visible.length ||
      to >= visible.length) {
    return unchanged;
  }
  final moving = visible[from];
  final restVisible = [...visible]..removeAt(from);
  final slot = to > restVisible.length ? restVisible.length : to;
  final without = [
    for (final task in siblings)
      if (task.id != moving.id) task,
  ];
  final fullIndex =
      slot >= restVisible.length
          ? without.length
          : without.indexWhere((task) => task.id == restVisible[slot].id);
  final index = fullIndex < 0 ? without.length : fullIndex;
  return [
    for (final task in ([...without]..insert(index, moving))) task.id,
  ];
}

/// Replaces one task's status in every plan. A done/not-done change also moves
/// the parent's finished-subtask count by one.
List<PlanBlock> plansWithTaskStatus(
  List<PlanBlock> plans,
  int taskId,
  String status,
) {
  String? previous;
  int? parentId;
  for (final plan in plans) {
    for (final task in plan.tasks) {
      if (task.id == taskId) {
        previous = task.status;
        parentId = task.parentId;
        break;
      }
    }
    if (previous != null) break;
  }
  if (previous == null || previous == status) return plans;
  final doneDelta = (status == 'done' ? 1 : 0) - (previous == 'done' ? 1 : 0);
  return [
    for (final plan in plans)
      PlanBlock(
        id: plan.id,
        projectId: plan.projectId,
        projectName: plan.projectName,
        color: plan.color,
        date: plan.date,
        startMin: plan.startMin,
        endMin: plan.endMin,
        note: plan.note,
        tracking: plan.tracking,
        tasks: [
          for (final task in plan.tasks)
            if (task.id == taskId)
              task.copyWith(status: status)
            else if (parentId != null &&
                task.id == parentId &&
                doneDelta != 0 &&
                task.subtaskCount > 0)
              task.copyWith(subtaskDone: _clampDone(task, doneDelta))
            else
              task,
        ],
      ),
  ];
}

int _clampDone(PlanTask task, int delta) {
  final next = task.subtaskDone + delta;
  if (next < 0) return 0;
  if (next > task.subtaskCount) return task.subtaskCount;
  return next;
}

class PlanTracking {
  const PlanTracking({
    required this.state,
    required this.effectiveSec,
    required this.breakSec,
    required this.currentBreakSec,
    required this.sessionCount,
  });

  static const empty = PlanTracking(
    state: 'not_started',
    effectiveSec: 0,
    breakSec: 0,
    currentBreakSec: 0,
    sessionCount: 0,
  );

  final String state;
  final int effectiveSec;
  final int breakSec;
  final int currentBreakSec;
  final int sessionCount;

  factory PlanTracking.fromJson(Object? value) {
    if (value is! Map) return empty;
    final json = value.cast<String, dynamic>();
    final sessions = json['sessions'];
    return PlanTracking(
      state: json['state'] as String? ?? 'not_started',
      effectiveSec: (json['effective_sec'] as num?)?.round() ?? 0,
      breakSec: (json['break_sec'] as num?)?.round() ?? 0,
      currentBreakSec: (json['current_break_sec'] as num?)?.round() ?? 0,
      sessionCount: sessions is List ? sessions.length : 0,
    );
  }
}

class PlanBlock {
  const PlanBlock({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.color,
    required this.date,
    required this.startMin,
    required this.endMin,
    required this.note,
    required this.tasks,
    this.tracking = PlanTracking.empty,
  });

  final int id;
  final int projectId;
  final String projectName;
  final Color color;
  final String date;
  final int startMin;
  final int endMin;
  final String note;
  final List<PlanTask> tasks;
  final PlanTracking tracking;

  int get durationMin => endMin - startMin;
  int get taskCount => tasks.length;

  factory PlanBlock.fromJson(Map<String, dynamic> json) {
    final tasks = json['tasks'];
    return PlanBlock(
      id: (json['id'] as num).toInt(),
      projectId: (json['project_id'] as num).toInt(),
      projectName: json['project_name'] as String? ?? '',
      color: colorFromHex(json['project_color'] as String?),
      date: _date(json['plan_date']),
      startMin: (json['start_min'] as num).toInt(),
      endMin: (json['end_min'] as num).toInt(),
      note: json['note'] as String? ?? '',
      tasks:
          tasks is List
              ? [
                for (final item in tasks)
                  PlanTask.fromJson(item as Map<String, dynamic>),
              ]
              : const [],
      tracking: PlanTracking.fromJson(json['tracking']),
    );
  }
}

class ProjectOption {
  const ProjectOption({
    required this.id,
    required this.name,
    required this.color,
    this.description = '',
    this.openCount = 0,
    this.doneCount = 0,
    this.taskCount = 0,
  });

  final int id;
  final String name;
  final Color color;
  final String description;
  final int openCount;
  final int doneCount;
  final int taskCount;

  factory ProjectOption.fromJson(Map<String, dynamic> json) {
    return ProjectOption(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      color: colorFromHex(json['color'] as String?),
      description: json['description'] as String? ?? '',
      openCount: (json['open_task_count'] as num?)?.toInt() ?? 0,
      doneCount: (json['done_task_count'] as num?)?.toInt() ?? 0,
      taskCount: (json['task_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkHours {
  const WorkHours({
    required this.startMin,
    required this.endMin,
    this.autoStop = true,
    this.targetEfficiencyPct = 80,
    this.notifyBeforeMin = 10,
    this.breakReminderMin = 15,
    this.idlePauseMin = 10,
  });

  final int startMin;
  final int endMin;
  final bool autoStop;
  final int targetEfficiencyPct;
  final int notifyBeforeMin;
  final int breakReminderMin;
  final int idlePauseMin;

  WorkHours copyWith({
    int? startMin,
    int? endMin,
    bool? autoStop,
    int? targetEfficiencyPct,
    int? notifyBeforeMin,
    int? breakReminderMin,
    int? idlePauseMin,
  }) {
    return WorkHours(
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
      autoStop: autoStop ?? this.autoStop,
      targetEfficiencyPct: targetEfficiencyPct ?? this.targetEfficiencyPct,
      notifyBeforeMin: notifyBeforeMin ?? this.notifyBeforeMin,
      breakReminderMin: breakReminderMin ?? this.breakReminderMin,
      idlePauseMin: idlePauseMin ?? this.idlePauseMin,
    );
  }

  factory WorkHours.fromJson(Map<String, dynamic> json) {
    return WorkHours(
      startMin: (json['work_start_min'] as num?)?.toInt() ?? 540,
      endMin: (json['work_end_min'] as num?)?.toInt() ?? 1080,
      autoStop: json['auto_stop'] as bool? ?? true,
      targetEfficiencyPct:
          (json['target_efficiency_pct'] as num?)?.toInt() ?? 80,
      notifyBeforeMin: (json['notify_before_min'] as num?)?.toInt() ?? 10,
      breakReminderMin: (json['break_reminder_min'] as num?)?.toInt() ?? 15,
      idlePauseMin: (json['idle_pause_min'] as num?)?.toInt() ?? 10,
    );
  }
}

Color colorFromHex(String? hex) {
  final raw = (hex ?? '').replaceAll('#', '');
  if (raw.length != 6) return const Color(0xFF6366F1);
  return Color(int.parse('FF$raw', radix: 16));
}

String _date(Object? value) {
  final text = value?.toString() ?? '';
  return text.length >= 10 ? text.substring(0, 10) : text;
}
