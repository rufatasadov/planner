import '../../models/plan.dart';

class FreeSlot {
  const FreeSlot({required this.startMin, required this.endMin});

  final int startMin;
  final int endMin;
}

String ymd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime mondayOf(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

List<String> weekDates(DateTime date) {
  final monday = mondayOf(date);
  return [for (var i = 0; i < 7; i++) ymd(monday.add(Duration(days: i)))];
}

/// Monday is 0, Sunday is 6.
int weekdayIndex(String date) {
  final parts = date.split('-');
  final day = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  return day.weekday - 1;
}

String fmtMin(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool historyLocked(String date, String? historyStart) =>
    historyStart != null && date.compareTo(historyStart) < 0;

DateTime planInstant(String date, int minutes) {
  final parts = date.split('-');
  final day = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  return day.add(Duration(minutes: minutes));
}

class LiveTracking {
  const LiveTracking({
    required this.state,
    required this.effectiveSec,
    required this.breakSec,
    required this.currentBreakSec,
  });

  final String state;
  final int effectiveSec;
  final int breakSec;
  final int currentBreakSec;
}

/// Server numbers are a snapshot from [loadedAt]. A running session and an open break grow until the next reload.
LiveTracking liveTracking(
  PlanTracking tracking,
  DateTime now,
  DateTime loadedAt,
) {
  final elapsed = now.difference(loadedAt).inSeconds;
  final grown = elapsed < 0 ? 0 : elapsed;
  final currentBreak =
      tracking.state == 'paused' ? tracking.currentBreakSec + grown : 0;
  return LiveTracking(
    state: tracking.state,
    effectiveSec:
        tracking.effectiveSec + (tracking.state == 'running' ? grown : 0),
    currentBreakSec: currentBreak,
    breakSec: tracking.breakSec + currentBreak,
  );
}

int elapsedPlanSec(String date, int startMin, int endMin, DateTime now) {
  final start = planInstant(date, startMin);
  final end = planInstant(date, endMin);
  final until = now.isBefore(end) ? now : end;
  final seconds = until.difference(start).inSeconds;
  return seconds < 0 ? 0 : seconds;
}

int? efficiencyPct(int effectiveSec, int baseSec) =>
    baseSec > 0 ? ((effectiveSec / baseSec) * 100).round() : null;

String fmtClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
  final secs = (safe % 60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$secs';
  return '$minutes:$secs';
}

int snapQuarter(int minutes) => (minutes / 15).round() * 15;

/// The next free hour inside working hours, snapped to 15 minutes.
/// Returns null when the day has no room left.
FreeSlot? nextFreeSlot({
  required int workStart,
  required int workEnd,
  required List<({int startMin, int endMin})> blocks,
  required int preferredStart,
}) {
  var start = snapQuarter(preferredStart).clamp(workStart, workEnd).toInt();
  final ordered = [...blocks]..sort((a, b) => a.startMin.compareTo(b.startMin));
  for (final block in ordered) {
    if (block.startMin <= start && start < block.endMin) start = block.endMin;
  }
  if (start >= workEnd) return null;
  final nextStart = ordered
      .where((block) => block.startMin > start)
      .map((block) => block.startMin)
      .fold<int?>(
        null,
        (soonest, value) =>
            soonest == null || value < soonest ? value : soonest,
      );
  final end = [
    start + 60,
    nextStart ?? workEnd,
    workEnd,
  ].reduce((a, b) => a < b ? a : b);
  if (end <= start) return null;
  return FreeSlot(startMin: start, endMin: end);
}

({int startMin, int endMin}) shiftBlock({
  required int startMin,
  required int endMin,
  required int deltaMin,
  required int workStart,
  required int workEnd,
}) {
  final duration = endMin - startMin;
  final latest = workEnd - duration;
  final start =
      (startMin + snapQuarter(deltaMin))
          .clamp(workStart, latest < workStart ? workStart : latest)
          .toInt();
  return (startMin: start, endMin: start + duration);
}
