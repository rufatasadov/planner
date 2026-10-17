import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../../widgets/note_markdown.dart';
import '../plan/plan_repository.dart';
import '../plan/plan_time.dart';

const _compactButton = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 40)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final _search = TextEditingController();
  Timer? _searchTimer;
  var _range = 'week';
  var _query = '';
  var _projectId = 0;
  DateTime? _from;
  DateTime? _to;
  List<ProjectOption> _projects = const [];
  List<WorkNote>? _notes;
  Object? _error;
  var _refreshing = false;
  var _ticket = 0;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _from = today.subtract(Duration(days: today.weekday - 1));
    _to = today;
    _load();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ref.read(planRepositoryProvider).projects();
      if (mounted) setState(() => _projects = projects);
    } catch (_) {}
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    if (_notes != null && mounted) setState(() => _refreshing = true);
    try {
      final notes = await ref
          .read(planRepositoryProvider)
          .notes(
            from: _from == null ? null : ymd(_from!),
            to: _to == null ? null : ymd(_to!),
            query: _query,
            projectId: _projectId == 0 ? null : _projectId,
          );
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _notes = notes;
        _error = null;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _error = error;
        _refreshing = false;
      });
    }
  }

  void _setRange(String range) {
    final today = dateOnly(DateTime.now());
    setState(() {
      _range = range;
      switch (range) {
        case 'today':
          _from = today;
          _to = today;
        case 'month':
          _from = today.subtract(const Duration(days: 29));
          _to = today;
        case 'all':
          _from = null;
          _to = null;
        default:
          _from = today.subtract(Duration(days: today.weekday - 1));
          _to = today;
      }
    });
    _load();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _to) ?? now,
      firstDate: DateTime(2020),
      lastDate: start ? (_to ?? now) : now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _range = '';
      if (start) {
        _from = dateOnly(picked);
      } else {
        _to = dateOnly(picked);
      }
    });
    _load();
  }

  Future<void> _edit(WorkNote note) async {
    final l10n = AppLocalizations.of(context);
    final body = TextEditingController(text: note.body);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (context) => KeyboardSheet(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                note.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                scrollPadding: fieldScrollPadding,
                decoration: InputDecoration(hintText: l10n.notesPlaceholder),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: _compactButton,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.planSave),
                  ),
                ],
              ),
            ],
          ),
    );
    final text = body.text.trim();
    body.dispose();
    if (saved != true || text.isEmpty || text == note.body || !mounted) return;
    try {
      final updated = await ref
          .read(planRepositoryProvider)
          .updateNote(note.id, text);
      if (!mounted) return;
      setState(() {
        _notes = [
          for (final item in _notes ?? const <WorkNote>[])
            if (item.id == note.id) updated else item,
        ];
      });
    } catch (error) {
      if (mounted) _snack(error);
    }
  }

  Future<void> _delete(WorkNote note) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(l10n.notesConfirmDelete),
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
    final previous = _notes;
    setState(() {
      _notes = [
        for (final item in _notes ?? const <WorkNote>[])
          if (item.id != note.id) item,
      ];
    });
    try {
      await ref.read(planRepositoryProvider).deleteNote(note.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _notes = previous);
      _snack(error);
    }
  }

  void _snack(Object error) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          apiErrorMessage(error, l10n.networkError, l10n.genericError),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final nextId = next.valueOrNull?.user.id;
      if (previous?.valueOrNull?.user.id == nextId || nextId == null) return;
      _loadProjects();
      _load();
    });
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final notes = _notes;
    final groups = <String, List<WorkNote>>{};
    for (final note in notes ?? const <WorkNote>[]) {
      final key = ymd(note.createdAt.toLocal());
      groups.putIfAbsent(key, () => []).add(note);
    }
    final tasks =
        {for (final note in notes ?? const <WorkNote>[]) note.taskId}.length;
    return Scaffold(
      body: Column(
        children: [
          if (_refreshing)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  l10n.notesTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.notesSummary(notes?.length ?? 0, tasks),
                  style: TextStyle(color: mutedColor(context)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final range in [
                      ('today', l10n.notesToday),
                      ('week', l10n.notesWeek),
                      ('month', l10n.notesMonth),
                      ('all', l10n.notesAll),
                    ])
                      ChoiceChip(
                        label: Text(range.$2),
                        selected: _range == range.$1,
                        onSelected: (_) => _setRange(range.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.notesSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _searchTimer?.cancel();
                    _searchTimer = Timer(const Duration(milliseconds: 300), () {
                      _query = value.trim();
                      _load();
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _projectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(l10n.notesAllProjects),
                    ),
                    for (final project in _projects)
                      DropdownMenuItem(
                        value: project.id,
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _projectId = value);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label:
                            _from == null
                                ? '—'
                                : DateFormat.MMMd(locale).format(_from!),
                        onTap: () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateButton(
                        label:
                            _to == null
                                ? '—'
                                : DateFormat.MMMd(locale).format(_to!),
                        onTap: () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_error != null && notes == null)
                  Text(
                    apiErrorMessage(
                      _error!,
                      l10n.networkError,
                      l10n.genericError,
                    ),
                  )
                else if (notes == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (notes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 42,
                          color: mutedColor(context),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.notesEmptyFilter,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedColor(context)),
                        ),
                      ],
                    ),
                  )
                else
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 6),
                      child: Text.rich(
                        TextSpan(
                          text: DateFormat.yMMMEd(
                            locale,
                          ).format(DateTime.parse(entry.key)),
                          children: [
                            TextSpan(
                              text: '  ·  ${entry.value.length}',
                              style: TextStyle(
                                color: mutedColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final note in entry.value)
                      _NoteCard(
                        note: note,
                        onEdit: () => _edit(note),
                        onDelete: () => _delete(note),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      onPressed: onTap,
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 16,
        color: mutedColor(context),
      ),
      label: Text(label),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final created = note.createdAt.toLocal();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final plan = note.planStartMin != null && note.planEndMin != null;
    final sameDay =
        note.planDate.isEmpty || note.planDate.startsWith(ymd(created));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: dark ? const Color(0xFF19223F) : const Color(0xFFF8F9FC),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ColoredBox(
                  color: note.color,
                  child: const SizedBox(width: 3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat.Hm(locale).format(created),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (plan) ...[
                          const SizedBox(width: 8),
                          _Chip(
                            tooltip: l10n.notesPlan,
                            child: Text(
                              sameDay
                                  ? '${fmtMin(note.planStartMin!)}–${fmtMin(note.planEndMin!)}'
                                  : '${fmtMin(note.planStartMin!)}–${fmtMin(note.planEndMin!)} · ${note.planDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor(context),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.projectsEdit,
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: l10n.planDelete,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (note.projectId > 0)
                          GestureDetector(
                            onTap:
                                () =>
                                    context.push('/projects/${note.projectId}'),
                            child: _Chip(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: note.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    note.projectName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Text.rich(
                          TextSpan(
                            children: [
                              if (note.parentTaskTitle.isNotEmpty)
                                TextSpan(
                                  text: '${note.parentTaskTitle} › ',
                                  style: TextStyle(
                                    color: mutedColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              TextSpan(text: note.taskTitle),
                            ],
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (note.edited)
                          Text(
                            '· ${l10n.notesEdited}',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor(context),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NoteMarkdown(note.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, this.tooltip});

  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF121933) : Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: child,
    );
    final tip = tooltip;
    if (tip == null) return chip;
    return Tooltip(message: tip, child: chip);
  }
}
