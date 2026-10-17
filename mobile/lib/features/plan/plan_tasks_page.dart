import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../../widgets/note_markdown.dart';
import 'plan_controller.dart';
import 'plan_repository.dart';
import 'plan_time.dart';

class PlanTasksPage extends ConsumerWidget {
  const PlanTasksPage({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(planControllerProvider).valueOrNull;
    final plan = _plan(data);
    return Scaffold(
      appBar: AppBar(
        title: Text(plan == null ? l10n.planTasks : plan.projectName),
        actions: [
          if (plan != null)
            IconButton(
              tooltip: l10n.planSyncTasks,
              onPressed: () async {
                await ref.read(planRepositoryProvider).syncTasks(plan.id);
                await ref.read(planControllerProvider.notifier).reload();
              },
              icon: const Icon(Icons.sync),
            ),
        ],
      ),
      body:
          plan == null
              ? Center(
                child: Text(
                  l10n.planNoTasks,
                  style: TextStyle(color: mutedColor(context)),
                ),
              )
              : _TaskBody(plan: plan),
    );
  }

  PlanBlock? _plan(PlanScreenData? data) {
    if (data == null) return null;
    for (final plan in data.plans) {
      if (plan.id == planId) return plan;
    }
    return null;
  }
}

class _TaskBody extends StatefulWidget {
  const _TaskBody({required this.plan});

  final PlanBlock plan;

  @override
  State<_TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends State<_TaskBody> {
  final _collapsed = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = widget.plan;
    final done = plan.tasks.where((task) => task.done).length;
    final nodes = taskTree(plan.tasks);
    final reserveExpand = nodes.any((node) => node.children.isNotEmpty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${fmtMin(plan.startMin)} – ${fmtMin(plan.endMin)}',
          style: TextStyle(color: mutedColor(context)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              l10n.planTasks,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$done/${plan.tasks.length}',
              style: TextStyle(color: mutedColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: plan.tasks.isEmpty ? 0 : done / plan.tasks.length,
            minHeight: 4,
            color: plan.color,
          ),
        ),
        const SizedBox(height: 8),
        if (plan.tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.planNoTasks,
              style: TextStyle(color: mutedColor(context)),
            ),
          )
        else
          for (final node in nodes) ...[
            _TaskRow(
              planId: plan.id,
              task: node.task,
              childCount: node.children.length,
              expanded: !_collapsed.contains(node.task.id),
              reserveExpand: reserveExpand,
              onToggle:
                  node.children.isEmpty ? null : () => _toggle(node.task.id),
            ),
            if (node.children.isNotEmpty && !_collapsed.contains(node.task.id))
              for (final child in node.children)
                _TaskRow(
                  planId: plan.id,
                  task: child,
                  nested: true,
                  reserveExpand: reserveExpand,
                ),
          ],
      ],
    );
  }

  void _toggle(int id) {
    setState(() {
      if (_collapsed.contains(id)) {
        _collapsed.remove(id);
      } else {
        _collapsed.add(id);
      }
    });
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.planId,
    required this.task,
    this.nested = false,
    this.childCount = 0,
    this.expanded = true,
    this.reserveExpand = false,
    this.onToggle,
  });

  final int planId;
  final PlanTask task;
  final bool nested;
  final int childCount;
  final bool expanded;
  final bool reserveExpand;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      'todo': l10n.taskTodo,
      'in_progress': l10n.taskDoing,
      'done': l10n.taskDone,
      'cancelled': l10n.taskCancelled,
    };
    final struck = task.done || task.status == 'cancelled';
    final statusColor = switch (task.status) {
      'in_progress' => const Color(0xFF6366F1),
      'done' => const Color(0xFF22C55E),
      _ => mutedColor(context),
    };
    final orphan =
        !nested && task.parentId != null && task.parentTitle.isNotEmpty;
    final created = task.createdAt?.toLocal();
    Future<void> toggleDone() {
      return _changeStatus(context, ref, task.id, task.done ? 'todo' : 'done');
    }

    return Padding(
      padding: EdgeInsets.only(left: nested ? 18 : 0, top: nested ? 2 : 10),
      child: Row(
        children: [
          if (reserveExpand)
            SizedBox(
              width: 32,
              child:
                  onToggle == null
                      ? null
                      : IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: onToggle,
                        icon: Icon(
                          expanded
                              ? Icons.expand_more_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                          color: mutedColor(context),
                        ),
                      ),
            ),
          Checkbox(
            value: task.done,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: const Color(0xFF22C55E),
            side: BorderSide(color: mutedColor(context), width: 1.6),
            onChanged: (_) => toggleDone(),
          ),
          Expanded(
            child: InkWell(
              onTap: toggleDone,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (orphan)
                            Text(
                              task.parentTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedColor(context),
                              ),
                            ),
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              height: 1.25,
                              fontWeight:
                                  childCount > 0 ? FontWeight.w600 : null,
                              decoration:
                                  struck ? TextDecoration.lineThrough : null,
                              color: struck ? mutedColor(context) : null,
                            ),
                          ),
                          if (created != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _taskDate(context, created),
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (task.subtaskCount > 0) ...[
                      Text(
                        '${task.subtaskDone}/${task.subtaskCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              task.subtaskDone == task.subtaskCount
                                  ? const Color(0xFF22C55E)
                                  : mutedColor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      tooltip: l10n.notesAdd,
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          () => showTaskNotes(
                            context,
                            task: task,
                            planId: planId,
                          ),
                      icon: Badge(
                        isLabelVisible: task.noteCount > 0,
                        label: Text('${task.noteCount}'),
                        child: Icon(
                          Icons.note_add_outlined,
                          size: 20,
                          color: mutedColor(context),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: task.status,
                      tooltip: labels[task.status] ?? task.status,
                      padding: EdgeInsets.zero,
                      onSelected:
                          (status) =>
                              _changeStatus(context, ref, task.id, status),
                      itemBuilder:
                          (context) => [
                            for (final entry in labels.entries)
                              PopupMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          labels[task.status] ?? task.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _changeStatus(
  BuildContext context,
  WidgetRef ref,
  int taskId,
  String status,
) async {
  try {
    await ref
        .read(planControllerProvider.notifier)
        .updateTaskStatus(taskId, status);
  } catch (error) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          apiErrorMessage(error, l10n.networkError, l10n.genericError),
        ),
      ),
    );
  }
}

String _taskDate(BuildContext context, DateTime created) {
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final format =
      created.year == now.year
          ? DateFormat.MMMd(locale)
          : DateFormat.yMMMd(locale);
  return format.format(created);
}

Future<void> showTaskNotes(
  BuildContext context, {
  required PlanTask task,
  int? planId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TaskNotesSheet(task: task, planId: planId),
  );
}

class _TaskNotesSheet extends ConsumerStatefulWidget {
  const _TaskNotesSheet({required this.task, this.planId});

  final PlanTask task;
  final int? planId;

  @override
  ConsumerState<_TaskNotesSheet> createState() => _TaskNotesSheetState();
}

class _TaskNotesSheetState extends ConsumerState<_TaskNotesSheet> {
  final _body = TextEditingController();
  List<WorkNote>? _notes;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _body.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final notes = await ref
          .read(planRepositoryProvider)
          .notes(taskId: widget.task.id);
      if (mounted) {
        setState(() {
          _notes = notes;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error));
      }
    }
  }

  Future<void> _save() async {
    final text = _body.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final note = await ref
          .read(planRepositoryProvider)
          .addNote(taskId: widget.task.id, planId: widget.planId, body: text);
      await ref.read(planControllerProvider.notifier).reload();
      if (!mounted) return;
      setState(() {
        _body.clear();
        _notes = [note, ...?_notes];
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).notesSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  String _message(Object error) {
    final l10n = AppLocalizations.of(context);
    return apiErrorMessage(error, l10n.networkError, l10n.genericError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final screen = MediaQuery.sizeOf(context).height;
    final available = screen - inset - MediaQuery.paddingOf(context).top - 32;
    final height = available.clamp(240.0, screen * 0.72);
    final notes = _notes;
    return DismissKeyboard(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + inset),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                scrollPadding: fieldScrollPadding,
                decoration: InputDecoration(hintText: l10n.notesPlaceholder),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _busy || _body.text.trim().isEmpty ? null : _save,
                  child: Text(l10n.notesAdd),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    notes == null
                        ? const Center(child: CircularProgressIndicator())
                        : notes.isEmpty
                        ? Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            _error ?? l10n.notesTaskEmpty,
                            style: TextStyle(color: mutedColor(context)),
                          ),
                        )
                        : ListView.separated(
                          itemCount: notes.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _taskDate(context, note.createdAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                NoteMarkdown(note.body),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
