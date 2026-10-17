import 'package:flutter/material.dart';

import 'plan.dart';

class WorkNote {
  const WorkNote({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.taskTitle,
    required this.projectName,
    required this.color,
    this.taskId = 0,
    this.projectId = 0,
    this.parentTaskTitle = '',
    this.planId,
    this.planDate = '',
    this.planStartMin,
    this.planEndMin,
    this.updatedAt,
  });

  final int id;
  final String body;
  final DateTime createdAt;
  final String taskTitle;
  final String projectName;
  final Color color;
  final int taskId;
  final int projectId;
  final String parentTaskTitle;
  final int? planId;
  final String planDate;
  final int? planStartMin;
  final int? planEndMin;
  final DateTime? updatedAt;

  bool get edited {
    final updated = updatedAt;
    if (updated == null) return false;
    return updated.difference(createdAt).inSeconds > 1;
  }

  factory WorkNote.fromJson(Map<String, dynamic> json) {
    return WorkNote(
      id: (json['id'] as num).toInt(),
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      taskId: (json['task_id'] as num?)?.toInt() ?? 0,
      taskTitle: json['task_title'] as String? ?? '',
      parentTaskTitle: json['parent_task_title'] as String? ?? '',
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String? ?? '',
      color: colorFromHex(json['project_color'] as String?),
      planId: (json['plan_id'] as num?)?.toInt(),
      planDate: json['plan_date']?.toString() ?? '',
      planStartMin: (json['plan_start_min'] as num?)?.toInt(),
      planEndMin: (json['plan_end_min'] as num?)?.toInt(),
    );
  }
}
