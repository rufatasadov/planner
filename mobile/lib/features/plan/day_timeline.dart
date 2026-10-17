import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../theme.dart';
import 'plan_time.dart';

class DayTimeline extends StatefulWidget {
  const DayTimeline({
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
    this.fitWidth = false,
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

  /// When true the whole working day fits the screen. Otherwise the day scrolls sideways.
  final bool fitWidth;

  @override
  State<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<DayTimeline> {
  final _scroll = ScrollController();
  int? _dragId;
  int _dragStart = 0;
  int _dragEnd = 0;
  bool _aligned = false;
  bool _alignQueued = false;
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
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final span = (widget.endMin - widget.startMin).clamp(1, 1440).toInt();
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxWidth;
        final width =
            widget.fitWidth
                ? viewport
                : (span * 1.8).clamp(viewport, 2400.0).toDouble();
        if (!widget.fitWidth && !_aligned && !_alignQueued) {
          _alignQueued = true;
          final trackWidth = width;
          final viewportWidth = viewport;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _alignQueued = false;
            if (!mounted || _aligned) return;
            _aligned = true;
            _jumpToFocus(trackWidth, span, viewportWidth);
          });
        }
        final track = GestureDetector(
          onTapUp: (details) {
            final minute =
                widget.startMin +
                (details.localPosition.dx / width * span).round();
            widget.onCreate(snapQuarter(minute));
          },
          child: SizedBox(
            width: width,
            height: 112,
            child: Stack(
              children: [
                for (
                  var minute = (widget.startMin / 60).ceil() * 60;
                  minute <= widget.endMin;
                  minute += 60
                )
                  Positioned(
                    left: (minute - widget.startMin) / span * width,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 1,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fmtMin(minute),
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.nowMin != null &&
                    widget.nowMin! >= widget.startMin &&
                    widget.nowMin! <= widget.endMin)
                  Positioned(
                    left: (widget.nowMin! - widget.startMin) / span * width,
                    top: 18,
                    bottom: 0,
                    child: Container(width: 2, color: const Color(0xFFF43F5E)),
                  ),
                for (final plan in widget.plans)
                  _block(context, plan, width, span),
              ],
            ),
          ),
        );
        if (widget.fitWidth) return track;
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: track,
        );
      },
    );
  }

  void _jumpToFocus(double trackWidth, int span, double viewport) {
    if (!_scroll.hasClients) return;
    final focus = _focusMinute();
    final x = (focus - widget.startMin) / span * trackWidth;
    final maxOffset = trackWidth <= viewport ? 0.0 : trackWidth - viewport;
    final offset = (x - viewport * 0.35).clamp(0.0, maxOffset);
    _scroll.jumpTo(offset);
  }

  int _focusMinute() {
    final now = widget.nowMin;
    if (now != null && now >= widget.startMin && now <= widget.endMin) {
      return now;
    }
    if (widget.plans.isEmpty) return widget.startMin;
    final first = [...widget.plans]
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    return first.first.startMin;
  }

  Widget _block(BuildContext context, PlanBlock plan, double width, int span) {
    final dragging = _dragId == plan.id;
    final start = dragging ? _dragStart : plan.startMin;
    final end = dragging ? _dragEnd : plan.endMin;
    final left = (start - widget.startMin) / span * width;
    final blockWidth =
        ((end - start) / span * width)
            .clamp(widget.fitWidth ? 2.0 : 28.0, width)
            .toDouble();
    final past = widget.nowMin != null && end <= widget.nowMin!;
    final current =
        widget.nowMin != null &&
        start <= widget.nowMin! &&
        widget.nowMin! < end;
    final selected = widget.selectedId == plan.id;
    return Positioned(
      left: left,
      width: blockWidth,
      top: 22,
      bottom: 4,
      child: GestureDetector(
        onTap: () => widget.onSelect(plan),
        onLongPressMoveUpdate: (details) {
          final delta = (details.offsetFromOrigin.dx / width * span).round();
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
          child:
              blockWidth < 36
                  ? const SizedBox.expand()
                  : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
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
                        Text(
                          '${fmtMin(start)}–${fmtMin(end)}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
