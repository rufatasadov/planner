import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plan.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../billing/paywall_sheet.dart';
import '../plan/plan_repository.dart';

const projectColors = [
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFF59E0B),
  Color(0xFF22C55E),
  Color(0xFF14B8A6),
  Color(0xFF06B6D4),
  Color(0xFF3B82F6),
];

const _compactButton = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 40)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

String colorHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  List<ProjectOption>? _projects;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await ref.read(planRepositoryProvider).projects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _edit(ProjectOption? project) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: project?.name ?? '');
    final description = TextEditingController(text: project?.description ?? '');
    var color =
        project?.color ??
        projectColors[(_projects?.length ?? 0) % projectColors.length];
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheet) => KeyboardSheet(
                  children: [
                    Text(
                      project == null ? l10n.projectsNew : l10n.projectsEdit,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      scrollPadding: fieldScrollPadding,
                      decoration: InputDecoration(labelText: l10n.projectsName),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      minLines: 2,
                      maxLines: 4,
                      scrollPadding: fieldScrollPadding,
                      decoration: InputDecoration(
                        labelText: l10n.projectsDescription,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.projectsColor,
                      style: TextStyle(color: mutedColor(context)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final swatch in projectColors)
                          GestureDetector(
                            onTap: () => setSheet(() => color = swatch),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color:
                                      color.toARGB32() == swatch.toARGB32()
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                          : Colors.transparent,
                                ),
                              ),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: swatch,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          name.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(context, true),
                      child: Text(
                        project == null ? l10n.projectsCreate : l10n.planSave,
                      ),
                    ),
                  ],
                ),
          ),
    );
    final nextName = name.text.trim();
    final nextDescription = description.text.trim();
    name.dispose();
    description.dispose();
    if (saved != true || nextName.isEmpty || !mounted) return;
    try {
      final repo = ref.read(planRepositoryProvider);
      if (project == null) {
        await repo.createProject(
          nextName,
          color: colorHex(color),
          description: nextDescription,
        );
      } else {
        await repo.updateProject(
          project.id,
          name: nextName,
          description: nextDescription,
          color: colorHex(color),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            project == null ? l10n.projectsCreated : l10n.projectsUpdated,
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (error is ApiException && error.isProjectLimit && mounted) {
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
      if (mounted) _snack(error);
    }
  }

  Future<void> _delete(ProjectOption project) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(l10n.projectsConfirmDelete(project.name)),
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
      await ref.read(planRepositoryProvider).deleteProject(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.projectsDeleted)));
      await _load();
    } catch (error) {
      if (mounted) _snack(error);
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
      _load();
    });
    final l10n = AppLocalizations.of(context);
    final projects = _projects;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.projectsTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                style: _compactButton,
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.projectsNew),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(apiErrorMessage(_error!, l10n.networkError, l10n.genericError))
          else if (projects == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (projects.isEmpty)
            _Empty(onCreate: () => _edit(null))
          else
            for (final project in projects)
              _ProjectCard(
                project: project,
                onOpen: () async {
                  await context.push('/projects/${project.id}');
                  await _load();
                },
                onEdit: () => _edit(project),
                onDelete: () => _delete(project),
              ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: mutedColor(context)),
          const SizedBox(height: 12),
          Text(
            l10n.projectsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor(context)),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onCreate, child: Text(l10n.projectsCreate)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectOption project;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct =
        project.taskCount == 0
            ? 0
            : ((project.doneCount / project.taskCount) * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: project.color, child: const SizedBox(height: 3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.projectsEdit,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.planDelete,
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                  Text(
                    project.description.isEmpty
                        ? l10n.projectsNoDescription
                        : project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor(context)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _stat('${project.openCount}', l10n.projectsOpen),
                      const SizedBox(width: 14),
                      _stat('${project.doneCount}', l10n.projectsDone),
                      const SizedBox(width: 14),
                      _stat('${project.taskCount}', l10n.projectsTotal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      color: project.color,
                      backgroundColor: project.color.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.projectsCompleted(pct),
                    style: TextStyle(fontSize: 12, color: mutedColor(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
