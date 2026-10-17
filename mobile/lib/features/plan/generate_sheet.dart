import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'plan_controller.dart';
import 'plan_repository.dart';
import 'plan_time.dart';

Future<void> showGenerateSheet(
  BuildContext context,
  WidgetRef ref,
  PlanScreenData day,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _GenerateSheet(day: day),
  );
}

class _GenerateSheet extends ConsumerStatefulWidget {
  const _GenerateSheet({required this.day});

  final PlanScreenData day;

  @override
  ConsumerState<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends ConsumerState<_GenerateSheet> {
  final _selected = <String>{};
  var _mode = 'skip';
  var _busy = false;

  List<String> get _thisWeek => weekDates(widget.day.date);

  List<String> get _nextWeek {
    final monday = mondayOf(widget.day.date).add(const Duration(days: 7));
    return weekDates(monday);
  }

  void _pick(bool Function(String date) include) {
    final source = ymd(widget.day.date);
    setState(() {
      _selected
        ..clear()
        ..addAll(
          _thisWeek.where(
            (date) => date.compareTo(source) > 0 && include(date),
          ),
        );
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(planRepositoryProvider)
          .generate(
            sourceDate: ymd(widget.day.date),
            targetDates: _selected.toList()..sort(),
            mode: _mode,
          );
      await ref.read(planControllerProvider.notifier).reload();
      if (!mounted) return;
      Navigator.pop(context);
      final skipped =
          result.skipped == 0 ? '' : ' ${l10n.generateSkipped(result.skipped)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.generateCreated(result.created)}$skipped'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(error, l10n.networkError, l10n.generateFailed),
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
    final locale = Localizations.localeOf(context).toString();
    final source = ymd(widget.day.date);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final label = DateFormat.yMMMEd(locale).format(widget.day.date);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.generateTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.generateIntro(label, widget.day.plans.length),
              style: TextStyle(color: mutedColor(context), height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text(l10n.generateRestWorkdays),
                  onPressed: () => _pick((date) => weekdayIndex(date) < 5),
                ),
                ActionChip(
                  label: Text(l10n.generateRestDays),
                  onPressed: () => _pick((date) => true),
                ),
                ActionChip(
                  label: Text(l10n.generateClear),
                  onPressed: () => setState(_selected.clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Week(
              label: l10n.generateThisWeek,
              days: _thisWeek,
              source: source,
              selected: _selected,
              locale: locale,
              onToggle: _toggle,
            ),
            const SizedBox(height: 12),
            _Week(
              label: l10n.generateNextWeek,
              days: _nextWeek,
              source: source,
              selected: _selected,
              locale: locale,
              onToggle: _toggle,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'skip',
              groupValue: _mode,
              title: Text(l10n.generateModeSkip),
              onChanged: (value) => setState(() => _mode = value ?? 'skip'),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'replace',
              groupValue: _mode,
              title: Text(l10n.generateModeReplace),
              onChanged: (value) => setState(() => _mode = value ?? 'replace'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy || _selected.isEmpty ? null : _submit,
              child: Text(l10n.generateSubmit(_selected.length)),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String date) {
    setState(() {
      if (!_selected.add(date)) _selected.remove(date);
    });
  }
}

class _Week extends StatelessWidget {
  const _Week({
    required this.label,
    required this.days,
    required this.source,
    required this.selected,
    required this.locale,
    required this.onToggle,
  });

  final String label;
  final List<String> days;
  final String source;
  final Set<String> selected;
  final String locale;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: mutedColor(context), fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final date in days) ...[
              if (date != days.first) const SizedBox(width: 4),
              Expanded(
                child: _Day(
                  date: date,
                  locale: locale,
                  source: date == source,
                  on: selected.contains(date),
                  color: scheme.primary,
                  onTap: () => onToggle(date),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.locale,
    required this.source,
    required this.on,
    required this.color,
    required this.onTap,
  });

  final String date;
  final String locale;
  final bool source;
  final bool on;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = date.split('-');
    final day = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return Material(
      color:
          on
              ? color.withValues(alpha: 0.16)
              : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color:
              on
                  ? color
                  : Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: source ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                DateFormat.E(locale).format(day),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: source ? mutedColor(context) : null,
                ),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: source ? mutedColor(context) : (on ? color : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
