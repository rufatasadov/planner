import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/note.dart';
import '../../models/plan.dart';

class TaskStatusResult {
  const TaskStatusResult({
    this.parentId,
    this.parentStatus,
    this.changed = false,
    this.parentTitle = '',
  });

  final int? parentId;
  final String? parentStatus;
  final bool changed;
  final String parentTitle;
}

class DayResult {
  const DayResult({required this.plans, required this.historyStart});

  final List<PlanBlock> plans;
  final String? historyStart;
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(dioProvider));
});

class PlanRepository {
  PlanRepository(this._dio);

  final Dio _dio;

  Future<DayResult> range(String from, String to) async {
    final response = await _dio.get<List<dynamic>>(
      '/plans',
      queryParameters: {'from': from, 'to': to},
    );
    final plans =
        (response.data ?? const [])
            .map((item) => PlanBlock.fromJson(item as Map<String, dynamic>))
            .toList();
    return DayResult(
      plans: plans,
      historyStart: response.headers.value('x-history-start'),
    );
  }

  Future<WorkHours> hours() async {
    final response = await _dio.get<Map<String, dynamic>>('/settings');
    return WorkHours.fromJson(response.data!);
  }

  Future<List<ProjectOption>> projects() async {
    final response = await _dio.get<List<dynamic>>('/projects');
    return (response.data ?? const [])
        .map((item) => ProjectOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectOption> createProject(
    String name, {
    String? color,
    String description = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/projects',
      data: {
        'name': name,
        'description': description,
        if (color != null) 'color': color,
      },
    );
    return ProjectOption.fromJson(response.data!);
  }

  Future<ProjectOption> updateProject(
    int id, {
    required String name,
    required String description,
    required String color,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/projects/$id',
      data: {'name': name, 'description': description, 'color': color},
    );
    return ProjectOption.fromJson(response.data!);
  }

  Future<ProjectOption> project(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/projects/$id');
    return ProjectOption.fromJson(response.data!);
  }

  Future<List<PlanTask>> projectTasks(int projectId) async {
    final response = await _dio.get<List<dynamic>>(
      '/tasks',
      queryParameters: {'project_id': projectId},
    );
    return (response.data ?? const [])
        .map((item) => PlanTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<({PlanTask task, TaskStatusResult parent})> createTask({
    int? projectId,
    int? parentId,
    required String title,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: {
        if (projectId != null) 'project_id': projectId,
        if (parentId != null) 'parent_id': parentId,
        'title': title,
      },
    );
    final data = response.data ?? const {};
    return (task: PlanTask.fromJson(data), parent: _readParent(data));
  }

  Future<PlanTask> renameTask(int id, String title) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/tasks/$id',
      data: {'title': title},
    );
    return PlanTask.fromJson(response.data!);
  }

  Future<({PlanTask task, TaskStatusResult parent, TaskStatusResult oldParent})>
  moveTask(int id, int? parentId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/tasks/$id',
      data: {'parent_id': parentId},
    );
    final data = response.data ?? const {};
    return (
      task: PlanTask.fromJson(data),
      parent: _readParent(data),
      oldParent: _readParent(data, 'old_parent'),
    );
  }

  Future<TaskStatusResult> deleteTask(int id) async {
    final response = await _dio.delete<Map<String, dynamic>>('/tasks/$id');
    return _readParent(response.data);
  }

  Future<void> reorderTasks(List<int> ids) async {
    await _dio.put('/tasks/reorder', data: {'ids': ids});
  }

  Future<PlanBlock> create({
    required String date,
    required int projectId,
    required int startMin,
    required int endMin,
    String note = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/plans',
      data: {
        'date': date,
        'project_id': projectId,
        'start_min': startMin,
        'end_min': endMin,
        if (note.isNotEmpty) 'note': note,
      },
    );
    return PlanBlock.fromJson(response.data!);
  }

  Future<void> move(int id, int startMin, int endMin) async {
    await _dio.put(
      '/plans/$id',
      data: {'start_min': startMin, 'end_min': endMin, 'shift_mode': 'none'},
    );
  }

  Future<void> update(
    int id, {
    required int projectId,
    required int startMin,
    required int endMin,
    required String note,
  }) async {
    await _dio.put(
      '/plans/$id',
      data: {
        'project_id': projectId,
        'start_min': startMin,
        'end_min': endMin,
        'note': note,
        'shift_mode': 'none',
      },
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/plans/$id');
  }

  Future<void> startTracking(int id) async {
    await _dio.post('/plans/$id/tracking/start');
  }

  Future<void> pauseTracking(int id) async {
    await _dio.post('/plans/$id/tracking/pause');
  }

  Future<void> syncTasks(int id) async {
    await _dio.post('/plans/$id/sync-tasks');
  }

  Future<void> postpone(int id, String date, int startMin, int endMin) async {
    await _dio.post(
      '/plans/$id/postpone',
      data: {'date': date, 'start_min': startMin, 'end_min': endMin},
    );
  }

  Future<({int created, int skipped})> generate({
    required String sourceDate,
    required List<String> targetDates,
    required String mode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/plans/generate',
      data: {
        'source_date': sourceDate,
        'target_dates': targetDates,
        'mode': mode,
      },
    );
    final days = response.data?['days'];
    var created = 0;
    var skipped = 0;
    if (days is List) {
      for (final day in days) {
        if (day is Map) {
          created += (day['created'] as num?)?.toInt() ?? 0;
          skipped += (day['skipped'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return (created: created, skipped: skipped);
  }

  Future<TaskStatusResult> setTaskStatus(int id, String status) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/tasks/$id/status',
      data: {'status': status},
    );
    return _readParent(response.data);
  }

  Future<WorkHours> saveSettings(WorkHours hours) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/settings',
      data: {
        'work_start_min': hours.startMin,
        'work_end_min': hours.endMin,
        'notify_before_min': hours.notifyBeforeMin,
        'auto_stop': hours.autoStop,
        'break_reminder_min': hours.breakReminderMin,
        'idle_pause_min': hours.idlePauseMin,
        'target_efficiency_pct': hours.targetEfficiencyPct,
      },
    );
    return WorkHours.fromJson(response.data!);
  }

  Future<void> deleteProject(int id) async {
    await _dio.delete('/projects/$id');
  }

  Future<List<WorkNote>> notes({
    String? from,
    String? to,
    String? query,
    int? taskId,
    int? projectId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/notes',
      queryParameters: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (query != null && query.isNotEmpty) 'q': query,
        if (taskId != null) 'task_id': taskId,
        if (projectId != null) 'project_id': projectId,
      },
    );
    return (response.data ?? const [])
        .map((item) => WorkNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkNote> addNote({
    required int taskId,
    required String body,
    int? planId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notes',
      data: {
        'task_id': taskId,
        'body': body,
        if (planId != null) 'plan_id': planId,
      },
    );
    return WorkNote.fromJson(response.data ?? const {});
  }

  Future<WorkNote> updateNote(int id, String body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/notes/$id',
      data: {'body': body},
    );
    return WorkNote.fromJson(response.data!);
  }

  Future<void> deleteNote(int id) async {
    await _dio.delete('/notes/$id');
  }
}

TaskStatusResult _readParent(
  Map<String, dynamic>? json, [
  String key = 'parent',
]) {
  final parent = json?[key];
  if (parent is! Map) return const TaskStatusResult();
  return TaskStatusResult(
    parentId: (parent['id'] as num?)?.toInt(),
    parentStatus: parent['status'] as String?,
    changed: parent['changed'] == true,
    parentTitle: parent['title'] as String? ?? '',
  );
}
