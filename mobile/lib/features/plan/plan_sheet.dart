import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan.dart';
import '../../widgets/keyboard_sheet.dart';
import '../billing/paywall_sheet.dart';
import 'plan_controller.dart';
import 'plan_repository.dart';
import 'plan_time.dart';

Future<void> showPlanSheet(
  BuildContext context,
  WidgetRef ref,
  PlanScreenData day, {
  PlanBlock? editing,
  int? preferredStart,
}) async {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final preferred =
      preferredStart ??
      (dateOnly(day.date) == dateOnly(now)
          ? now.hour * 60 + now.minute
          : day.hours.startMin);
  final slot =
      editing == null
          ? nextFreeSlot(
            workStart: day.hours.startMin,
            workEnd: day.hours.endMin,
            blocks: [
              for (final plan in day.plans)
                (startMin: plan.startMin, endMin: plan.endMin),
            ],
            preferredStart: preferred,
          )
          : FreeSlot(startMin: editing.startMin, endMin: editing.endMin);
  if (slot == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.planNoFreeTime)));
    return;
  }
  List<ProjectOption> projects;
  try {
    projects = await ref.read(planRepositoryProvider).projects();
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
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (context) => _PlanSheet(
          day: day,
          slot: slot,
          projects: projects,
          editing: editing,
        ),
  );
}

class _PlanSheet extends ConsumerStatefulWidget {
  const _PlanSheet({
    required this.day,
    required this.slot,
    required this.projects,
    this.editing,
  });

  final PlanScreenData day;
  final FreeSlot slot;
  final List<ProjectOption> projects;
  final PlanBlock? editing;

  @override
  ConsumerState<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<_PlanSheet> {
  late final List<ProjectOption> _projects = _withCurrent(widget.projects);
  late int? _projectId =
      widget.editing?.projectId ??
      (_projects.isEmpty ? null : _projects.first.id);
  late int _start = widget.slot.startMin;
  late int _end = widget.slot.endMin;
  final _name = TextEditingController();
  late final _note = TextEditingController(text: widget.editing?.note ?? '');

  List<ProjectOption> _withCurrent(List<ProjectOption> projects) {
    final plan = widget.editing;
    if (plan == null ||
        projects.any((project) => project.id == plan.projectId)) {
      return projects;
    }
    return [
      ProjectOption(
        id: plan.projectId,
        name: plan.projectName,
        color: plan.color,
      ),
      ...projects,
    ];
  }

  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final initial = TimeOfDay(
      hour: (start ? _start : _end) ~/ 60,
      minute: (start ? _start : _end) % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      final minutes = snapQuarter(picked.hour * 60 + picked.minute);
      if (start) {
        _start = minutes;
      } else {
        _end = minutes;
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_start >= _end) return;
    setState(() => _busy = true);
    try {
      final note = _note.text.trim();
      final editing = widget.editing;
      if (editing != null) {
        final projectId = _projectId;
        if (projectId == null) return;
        await ref
            .read(planRepositoryProvider)
            .update(
              editing.id,
              projectId: projectId,
              startMin: _start,
              endMin: _end,
              note: note,
            );
      } else {
        var projectId = _projectId;
        if (projectId == null) {
          final name = _name.text.trim();
          if (name.isEmpty) return;
          final created = await ref
              .read(planRepositoryProvider)
              .createProject(name);
          projectId = created.id;
        }
        await ref
            .read(planRepositoryProvider)
            .create(
              date: ymd(widget.day.date),
              projectId: projectId,
              startMin: _start,
              endMin: _end,
              note: note,
            );
      }
      await ref.read(planControllerProvider.notifier).reload();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException && error.isProjectLimit) {
        final billing =
            ref.read(authControllerProvider).valueOrNull?.user.billing;
        await showPaywall(
          context,
          reason: 'projects',
          projectLimit: billing?.projectLimit,
          historyDays: billing?.historyDays,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(error, l10n.networkError, l10n.genericError),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyboardSheet(
      children: [
        Text(
          widget.editing == null ? l10n.planAdd : l10n.planEditTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (_projects.isEmpty && widget.editing == null)
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            scrollPadding: fieldScrollPadding,
            decoration: InputDecoration(labelText: l10n.planProjectName),
          )
        else
          DropdownButtonFormField<int>(
            value: _projectId,
            decoration: InputDecoration(labelText: l10n.planProject),
            items: [
              for (final project in _projects)
                DropdownMenuItem(value: project.id, child: Text(project.name)),
            ],
            onChanged: (value) => setState(() => _projectId = value),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(true),
                child: Text('${l10n.planStart}  ${fmtMin(_start)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(false),
                child: Text('${l10n.planEnd}  ${fmtMin(_end)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: fieldScrollPadding,
          decoration: InputDecoration(labelText: l10n.planNote),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.planSave),
        ),
      ],
    );
  }
}
