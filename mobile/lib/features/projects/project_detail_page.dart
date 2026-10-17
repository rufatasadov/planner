import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../plan/plan_repository.dart';
import '../plan/plan_tasks_page.dart';

const _compactButton = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 40)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _title = TextEditingController();
  ProjectOption? _project;
  List<PlanTask> _tasks = const [];
  Object? _error;
  var _filter = 'open';
  var _addingFor = 0;
  final _collapsed = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(planRepositoryProvider);
      final project = await repo.project(widget.projectId);
      final tasks = await repo.projectTasks(widget.projectId);
      if (!mounted) return;
      setState(() {
        _project = project;
        _tasks = tasks;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<PlanTask> _withStatus(List<PlanTask> tasks, int id, String status) {
    final project = _project;
    return plansWithTaskStatus(
      [
        PlanBlock(
          id: 0,
          projectId: widget.projectId,
          projectName: project?.name ?? '',
          color: project?.color ?? const Color(0xFF6366F1),
          date: '',
          startMin: 0,
          endMin: 1,
          note: '',
          tasks: tasks,
        ),
      ],
      id,
      status,
    ).first.tasks;
  }

  void _applyParent(TaskStatusResult parent) {
    final id = parent.parentId;
    final status = parent.parentStatus;
    if (id == null || status == null) return;
    setState(() => _tasks = _withStatus(_tasks, id, status));
    if (!parent.changed || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final text =
        status == 'done'
            ? l10n.tasksParentDone(parent.parentTitle)
            : l10n.tasksParentReopened(parent.parentTitle);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setStatus(PlanTask task, String status) async {
    if (task.status == status) return;
    final previous = _tasks;
    setState(() => _tasks = _withStatus(_tasks, task.id, status));
    try {
      final result = await ref
          .read(planRepositoryProvider)
          .setTaskStatus(task.id, status);
      if (!mounted) return;
      _applyParent(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _tasks = previous);
      _snack(error, AppLocalizations.of(context).tasksStatusFailed);
    }
  }

  Future<void> _add({int? parentId, String? title}) async {
    final text = (title ?? _title.text).trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    try {
      final created = await ref
          .read(planRepositoryProvider)
          .createTask(
            projectId: parentId == null ? widget.projectId : null,
            parentId: parentId,
            title: text,
          );
      if (!mounted) return;
      setState(() {
        _tasks = [..._tasks, created.task];
        if (title == null) _title.clear();
        _addingFor = 0;
        if (_filter != 'open' && _filter != 'all') _filter = 'open';
        if (parentId != null) _collapsed.remove(parentId);
      });
      _applyParent(created.parent);
    } catch (error) {
      if (mounted) _snack(error, l10n.tasksAddFailed);
    }
  }

  Future<void> _rename(PlanTask task) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: task.title);
    final title = await showDialog<String>(
      context: context,
      builder:
          (context) => DismissKeyboard(
            child: AlertDialog(
              scrollable: true,
              title: Text(l10n.tasksRename),
              content: TextField(
                controller: controller,
                autofocus: true,
                scrollPadding: fieldScrollPadding,
                decoration: InputDecoration(hintText: l10n.tasksAddPlaceholder),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: _compactButton,
                  onPressed:
                      () => Navigator.pop(context, controller.text.trim()),
                  child: Text(l10n.planSave),
                ),
              ],
            ),
          ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || title == task.title || !mounted) {
      return;
    }
    try {
      final updated = await ref
          .read(planRepositoryProvider)
          .renameTask(task.id, title);
      if (!mounted) return;
      setState(() {
        _tasks = [
          for (final item in _tasks)
            if (item.id == task.id)
              item.copyWith(title: updated.title)
            else
              item,
        ];
      });
    } catch (error) {
      if (mounted) _snack(error, l10n.genericError);
    }
  }

  Future<void> _delete(PlanTask task) async {
    final l10n = AppLocalizations.of(context);
    final subs = _tasks.where((item) => item.parentId == task.id).length;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(
              subs > 0
                  ? l10n.tasksConfirmDeleteSubs(task.title, subs)
                  : l10n.tasksConfirmDelete(task.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: _compactButton,
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.planDelete),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    try {
      final parent = await ref.read(planRepositoryProvider).deleteTask(task.id);
      if (!mounted) return;
      setState(() {
        _tasks =
            _tasks
                .where((item) => item.id != task.id && item.parentId != task.id)
                .toList();
      });
      _applyParent(parent);
    } catch (error) {
      if (mounted) _snack(error, l10n.genericError);
    }
  }

  Future<void> _move(PlanTask task) async {
    final l10n = AppLocalizations.of(context);
    final hasChildren = _tasks.any((item) => item.parentId == task.id);
    final roots =
        taskTree(
          _tasks,
        ).map((node) => node.task).where((item) => item.id != task.id).toList();
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.tasksMoveTitle(task.title),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasChildren)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.tasksCannotNest,
                      style: TextStyle(color: mutedColor(context)),
                    ),
                  ),
                ListTile(
                  title: Text(l10n.tasksIndependent),
                  enabled: task.parentId != null,
                  onTap: () => Navigator.pop(context, 0),
                ),
                for (final parent in roots)
                  ListTile(
                    title: Text(parent.title),
                    enabled: !hasChildren && task.parentId != parent.id,
                    onTap: () => Navigator.pop(context, parent.id),
                  ),
              ],
            ),
          ),
    );
    if (picked == null || !mounted) return;
    final parentId = picked == 0 ? null : picked;
    if (parentId == task.parentId) return;
    try {
      final moved = await ref
          .read(planRepositoryProvider)
          .moveTask(task.id, parentId);
      final tasks = await ref
          .read(planRepositoryProvider)
          .projectTasks(widget.projectId);
      if (!mounted) return;
      setState(() => _tasks = tasks);
      final message =
          parentId == null
              ? l10n.tasksMadeIndependent
              : l10n.tasksMovedUnder(moved.task.parentTitle);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _applyParent(moved.oldParent);
      _applyParent(moved.parent);
    } catch (error) {
      if (mounted) _snack(error, l10n.genericError);
    }
  }

  Future<void> _moveVisible(
    int? parentId,
    List<PlanTask> visible,
    int from,
    int to,
  ) async {
    final siblings =
        _tasks.where((item) => item.parentId == parentId).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final ids = moveVisibleSibling(
      siblings: siblings,
      visible: visible,
      from: from,
      to: to,
    );
    final current = [for (final item in siblings) item.id];
    if (_sameOrder(ids, current)) return;
    final previous = _tasks;
    setState(() {
      _tasks = [
        for (final item in _tasks)
          if (ids.contains(item.id))
            item.copyWith(position: ids.indexOf(item.id))
          else
            item,
      ];
    });
    try {
      await ref.read(planRepositoryProvider).reorderTasks(ids);
    } catch (error) {
      if (!mounted) return;
      setState(() => _tasks = previous);
      _snack(error, AppLocalizations.of(context).genericError);
    }
  }

  bool _sameOrder(List<int> next, List<int> current) {
    if (next.length != current.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != current[i]) return false;
    }
    return true;
  }

  Future<void> _notes(PlanTask task) async {
    await showTaskNotes(context, task: task);
    if (!mounted) return;
    try {
      final tasks = await ref
          .read(planRepositoryProvider)
          .projectTasks(widget.projectId);
      if (mounted) setState(() => _tasks = tasks);
    } catch (_) {}
  }

  void _snack(Object error, String fallback) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(apiErrorMessage(error, l10n.networkError, fallback)),
      ),
    );
  }

  bool _matches(PlanTask task) {
    return switch (_filter) {
      'done' => task.status == 'done',
      'cancelled' => task.status == 'cancelled',
      'all' => true,
      _ => task.status == 'todo' || task.status == 'in_progress',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.projectsTitle)),
        body: Center(
          child:
              _error == null
                  ? const CircularProgressIndicator()
                  : Text(
                    apiErrorMessage(
                      _error!,
                      l10n.networkError,
                      l10n.genericError,
                    ),
                  ),
        ),
      );
    }
    final counts = <String, int>{
      for (final status in ['todo', 'in_progress', 'done', 'cancelled'])
        status: _tasks.where((task) => task.status == status).length,
    };
    final nodes = taskTree(_tasks);
    final visible = [
      for (final node in nodes)
        if (_matches(node.task) ||
            node.children.any(_matches) ||
            _addingFor == node.task.id)
          node,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: project.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(project.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (project.description.isNotEmpty)
            Text(
              project.description,
              style: TextStyle(color: mutedColor(context)),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(l10n.taskTodo, counts['todo']!, mutedColor(context)),
              _pill(
                l10n.taskDoing,
                counts['in_progress']!,
                const Color(0xFF6366F1),
              ),
              _pill(l10n.taskDone, counts['done']!, const Color(0xFF22C55E)),
              _pill(
                l10n.taskCancelled,
                counts['cancelled']!,
                mutedColor(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _title,
                  textInputAction: TextInputAction.done,
                  scrollPadding: fieldScrollPadding,
                  decoration: InputDecoration(
                    hintText: l10n.tasksAddPlaceholder,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: _compactButton,
                onPressed: () => _add(),
                child: Text(l10n.tasksAdd),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final filter in [
                ('open', l10n.tasksFilterOpen),
                ('done', l10n.tasksFilterDone),
                ('cancelled', l10n.tasksFilterCancelled),
                ('all', l10n.tasksFilterAll),
              ])
                ChoiceChip(
                  label: Text(filter.$2),
                  selected: _filter == filter.$1,
                  onSelected: (_) => setState(() => _filter = filter.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                l10n.tasksEmptyFilter,
                style: TextStyle(color: mutedColor(context)),
              ),
            )
          else
            for (final node in visible) ...[
              _ReorderRow(
                parentId: null,
                index: [
                  for (final item in visible)
                    if (item.task.parentId == null) item.task,
                ].indexWhere((task) => task.id == node.task.id),
                enabled:
                    node.task.parentId == null &&
                    visible.where((item) => item.task.parentId == null).length >
                        1,
                title: node.task.title,
                onMove:
                    (from, to) => _moveVisible(
                      null,
                      [
                        for (final item in visible)
                          if (item.task.parentId == null) item.task,
                      ],
                      from,
                      to,
                    ),
                child: _TaskTile(
                  task: node.task,
                  nested: false,
                  muted: !_matches(node.task),
                  childCount: node.children.length,
                  expanded: !_collapsed.contains(node.task.id),
                  onToggle:
                      node.children.isEmpty
                          ? null
                          : () => setState(() {
                            if (!_collapsed.add(node.task.id)) {
                              _collapsed.remove(node.task.id);
                            }
                          }),
                  onStatus: (status) => _setStatus(node.task, status),
                  onNotes: () => _notes(node.task),
                  onMenu: (action) => _menu(node.task, action),
                ),
              ),
              if (!_collapsed.contains(node.task.id))
                _SiblingList(
                  tasks: node.children.where(_matches).toList(),
                  parentId: node.task.id,
                  onMove:
                      (from, to) => _moveVisible(
                        node.task.id,
                        node.children.where(_matches).toList(),
                        from,
                        to,
                      ),
                  tile:
                      (child) => _TaskTile(
                        task: child,
                        nested: true,
                        onStatus: (status) => _setStatus(child, status),
                        onNotes: () => _notes(child),
                        onMenu: (action) => _menu(child, action),
                      ),
                ),
              if (_addingFor == node.task.id)
                _SubtaskField(
                  hint: l10n.tasksSubtaskPlaceholder,
                  addLabel: l10n.tasksAdd,
                  cancelLabel: l10n.cancel,
                  onSubmit:
                      (value) => _add(parentId: node.task.id, title: value),
                  onCancel: () => setState(() => _addingFor = 0),
                ),
            ],
        ],
      ),
    );
  }

  void _menu(PlanTask task, String action) {
    switch (action) {
      case 'sub':
        setState(() {
          _addingFor = task.id;
          _collapsed.remove(task.id);
        });
      case 'rename':
        _rename(task);
      case 'move':
        _move(task);
      case 'delete':
        _delete(task);
    }
  }

  Widget _pill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SubtaskField extends StatefulWidget {
  const _SubtaskField({
    required this.hint,
    required this.addLabel,
    required this.cancelLabel,
    required this.onSubmit,
    required this.onCancel,
  });

  final String hint;
  final String addLabel;
  final String cancelLabel;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<_SubtaskField> createState() => _SubtaskFieldState();
}

class _SubtaskFieldState extends State<_SubtaskField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              scrollPadding: fieldScrollPadding,
              decoration: InputDecoration(hintText: widget.hint),
              onSubmitted: widget.onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: _compactButton,
            onPressed: () => widget.onSubmit(_text.text),
            child: Text(widget.addLabel),
          ),
          IconButton(
            tooltip: widget.cancelLabel,
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.nested,
    required this.onStatus,
    required this.onNotes,
    required this.onMenu,
    this.muted = false,
    this.childCount = 0,
    this.expanded = true,
    this.onToggle,
  });

  final PlanTask task;
  final bool nested;
  final bool muted;
  final int childCount;
  final bool expanded;
  final VoidCallback? onToggle;
  final ValueChanged<String> onStatus;
  final VoidCallback onNotes;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final struck = task.done || task.status == 'cancelled';
    final statusColor = switch (task.status) {
      'in_progress' => const Color(0xFF6366F1),
      'done' => const Color(0xFF22C55E),
      _ => mutedColor(context),
    };
    final labels = {
      'todo': l10n.taskTodo,
      'in_progress': l10n.taskDoing,
      'done': l10n.taskDone,
      'cancelled': l10n.taskCancelled,
    };
    return Padding(
      padding: EdgeInsets.only(left: nested ? 28 : 0),
      child: Row(
        children: [
          if (!nested)
            SizedBox(
              width: 28,
              child:
                  onToggle == null
                      ? null
                      : IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: onToggle,
                        icon: Icon(
                          expanded
                              ? Icons.expand_more_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                        ),
                      ),
            ),
          Checkbox(
            value: task.done,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: const Color(0xFF22C55E),
            side: BorderSide(color: mutedColor(context), width: 1.6),
            onChanged: (_) => onStatus(task.done ? 'todo' : 'done'),
          ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: childCount > 0 ? FontWeight.w600 : null,
                decoration: struck ? TextDecoration.lineThrough : null,
                color: muted || struck ? mutedColor(context) : null,
              ),
            ),
          ),
          if (task.subtaskCount > 0)
            Text(
              '${task.subtaskDone}/${task.subtaskCount}',
              style: TextStyle(fontSize: 11, color: mutedColor(context)),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n.notesAdd,
            onPressed: onNotes,
            icon: Badge(
              isLabelVisible: task.noteCount > 0,
              label: Text('${task.noteCount}'),
              child: Icon(
                Icons.note_add_outlined,
                size: 18,
                color: mutedColor(context),
              ),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: task.status,
            padding: EdgeInsets.zero,
            onSelected: onStatus,
            itemBuilder:
                (context) => [
                  for (final entry in labels.entries)
                    PopupMenuItem(value: entry.key, child: Text(entry.value)),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: onMenu,
            itemBuilder:
                (context) => [
                  if (!nested)
                    PopupMenuItem(
                      value: 'sub',
                      child: Text(l10n.tasksAddSubtask),
                    ),
                  PopupMenuItem(value: 'rename', child: Text(l10n.tasksRename)),
                  PopupMenuItem(value: 'move', child: Text(l10n.tasksMove)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.planDelete)),
                ],
            icon: Icon(Icons.more_horiz, color: mutedColor(context)),
          ),
        ],
      ),
    );
  }
}

class _DragToken {
  const _DragToken(this.parentId, this.index);

  final int? parentId;
  final int index;
}

class _ReorderRow extends StatelessWidget {
  const _ReorderRow({
    required this.parentId,
    required this.index,
    required this.enabled,
    required this.title,
    required this.onMove,
    required this.child,
  });

  final int? parentId;
  final int index;
  final bool enabled;
  final String title;
  final void Function(int from, int to) onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || index < 0) return child;
    final token = _DragToken(parentId, index);
    return DragTarget<_DragToken>(
      onWillAcceptWithDetails:
          (details) =>
              details.data.parentId == parentId && details.data.index != index,
      onAcceptWithDetails: (details) => onMove(details.data.index, index),
      builder: (context, candidate, rejected) {
        return ColoredBox(
          color:
              candidate.isEmpty
                  ? const Color(0x00000000)
                  : Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
          child: Row(
            children: [
              _DragHandle(token: token, title: title),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.token, required this.title});

  final _DragToken token;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LongPressDraggable<_DragToken>(
      data: token,
      feedback: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Tooltip(
        message: l10n.tasksDrag,
        child: Icon(Icons.drag_handle, color: mutedColor(context)),
      ),
    );
  }
}

class _SiblingList extends StatelessWidget {
  const _SiblingList({
    required this.tasks,
    required this.parentId,
    required this.onMove,
    required this.tile,
  });

  final List<PlanTask> tasks;
  final int? parentId;
  final void Function(int from, int to) onMove;
  final Widget Function(PlanTask task) tile;

  @override
  Widget build(BuildContext context) {
    final enabled = tasks.length > 1;
    return Column(
      children: [
        for (var index = 0; index < tasks.length; index++)
          _ReorderRow(
            parentId: parentId,
            index: index,
            enabled: enabled,
            title: tasks[index].title,
            onMove: onMove,
            child: tile(tasks[index]),
          ),
      ],
    );
  }
}
