import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../theme.dart';
import 'plan_time.dart';

/// One working day drawn down the page: hours on the left, every block full width.
class DayColumn extends StatefulWidget {
  const DayColumn({
    super.key,
    required this.plans,
    required this.startMin,
    required this.endMin,
    required this.nowMin,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    required this.onMoved,
    required this.onEdit,
  });

  final List<PlanBlock> plans;
  final int startMin;
  final int endMin;
  final int? nowMin;
  final int? selectedId;
  final ValueChanged<PlanBlock> onSelect;
  final ValueChanged<int> onCreate;
  final void Function(PlanBlock plan, int startMin, int endMin) onMoved;
  final ValueChanged<PlanBlock> onEdit;

  @override
  State<DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends State<DayColumn> {
  static const _hourHeight = 56.0;
  static const _gutter = 48.0;

  int? _dragId;
  int _dragStart = 0;
  int _dragEnd = 0;
  bool _posted = false;

  void _postFrame() {
    if (_posted) return;
    _posted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _posted = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final span = (widget.endMin - widget.startMin).clamp(1, 1440).toInt();
    final height = span / 60 * _hourHeight;
    return GestureDetector(
      onTapUp: (details) {
        final minute =
            widget.startMin +
            (details.localPosition.dy / height * span).round();
        widget.onCreate(snapQuarter(minute));
      },
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (
              var minute = ((widget.startMin + 59) ~/ 60) * 60;
              minute < widget.endMin;
              minute += 60
            )
              Positioned(
                top: (minute - widget.startMin) / span * height,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    SizedBox(
                      width: _gutter,
                      child: Text(
                        fmtMin(minute),
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.nowMin != null &&
                widget.nowMin! >= widget.startMin &&
                widget.nowMin! <= widget.endMin)
              Positioned(
                top: (widget.nowMin! - widget.startMin) / span * height,
                left: _gutter,
                right: 0,
                child: Container(height: 2, color: const Color(0xFFF43F5E)),
              ),
            for (final plan in widget.plans)
              _block(context, plan, height, span),
          ],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, PlanBlock plan, double height, int span) {
    final dragging = _dragId == plan.id;
    final start = dragging ? _dragStart : plan.startMin;
    final end = dragging ? _dragEnd : plan.endMin;
    final top = (start - widget.startMin) / span * height;
    final blockHeight =
        ((end - start) / span * height).clamp(32.0, height).toDouble();
    final past = widget.nowMin != null && end <= widget.nowMin!;
    final current =
        widget.nowMin != null &&
        start <= widget.nowMin! &&
        widget.nowMin! < end;
    final selected = widget.selectedId == plan.id;
    return Positioned(
      top: top,
      height: blockHeight,
      left: _gutter,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(plan),
        onLongPressMoveUpdate: (details) {
          final delta = (details.offsetFromOrigin.dy / height * span).round();
          final moved = shiftBlock(
            startMin: plan.startMin,
            endMin: plan.endMin,
            deltaMin: delta,
            workStart: widget.startMin,
            workEnd: widget.endMin,
          );
          _dragId = plan.id;
          _dragStart = moved.startMin;
          _dragEnd = moved.endMin;
          _postFrame();
        },
        onLongPressEnd: (_) {
          final dragging = _dragId == plan.id;
          final start = _dragStart;
          final end = _dragEnd;
          final moved =
              dragging && (start != plan.startMin || end != plan.endMin);
          _dragId = null;
          _postFrame();
          if (moved) {
            widget.onMoved(plan, start, end);
          } else {
            widget.onEdit(plan);
          }
        },
        onLongPressCancel: () {
          if (_dragId == null) return;
          _dragId = null;
          _postFrame();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: plan.color.withValues(alpha: past ? 0.18 : 0.28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected || current
                      ? plan.color
                      : plan.color.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (blockHeight >= 48)
                  Text(
                    '${fmtMin(start)}–${fmtMin(end)}',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, color: mutedColor(context)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
