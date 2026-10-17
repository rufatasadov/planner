import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onelineplanner/features/plan/plan_time.dart';
import 'package:onelineplanner/features/plan/plan_view.dart';
import 'package:onelineplanner/models/plan.dart';
import 'package:onelineplanner/notifications/plan_alerts.dart';

void main() {
  test('history lock keeps the boundary day open', () {
    expect(historyLocked('2026-10-01', '2026-10-02'), isTrue);
    expect(historyLocked('2026-10-02', '2026-10-02'), isFalse);
    expect(historyLocked('2026-10-03', null), isFalse);
  });

  test('next free slot skips an occupied hour and stops at the next block', () {
    final slot = nextFreeSlot(
      workStart: 9 * 60,
      workEnd: 18 * 60,
      blocks: [
        (startMin: 9 * 60, endMin: 10 * 60),
        (startMin: 11 * 60, endMin: 12 * 60),
      ],
      preferredStart: 9 * 60,
    );
    expect(slot?.startMin, 10 * 60);
    expect(slot?.endMin, 11 * 60);
  });

  test('unknown schedule view falls back to the day column', () {
    expect(planViewFromName(null), PlanViewMode.column);
    expect(planViewFromName('strip'), PlanViewMode.strip);
    expect(planViewFromName('column'), PlanViewMode.column);
    expect(planViewFromName('fit'), PlanViewMode.fit);
    expect(planViewFromName('agenda'), PlanViewMode.column);
  });

  test(
    'a running timer grows from the snapshot and a pause grows the break',
    () {
      const tracking = PlanTracking(
        state: 'running',
        effectiveSec: 100,
        breakSec: 10,
        currentBreakSec: 0,
        sessionCount: 1,
      );
      final loaded = DateTime(2026, 10, 16, 10);
      final running = liveTracking(
        tracking,
        loaded.add(const Duration(seconds: 30)),
        loaded,
      );
      expect(running.effectiveSec, 130);
      expect(running.breakSec, 10);

      const paused = PlanTracking(
        state: 'paused',
        effectiveSec: 100,
        breakSec: 10,
        currentBreakSec: 5,
        sessionCount: 1,
      );
      final onBreak = liveTracking(
        paused,
        loaded.add(const Duration(seconds: 15)),
        loaded,
      );
      expect(onBreak.effectiveSec, 100);
      expect(onBreak.currentBreakSec, 20);
      expect(onBreak.breakSec, 30);
      expect(efficiencyPct(50, 100), 50);
      expect(efficiencyPct(0, 0), isNull);
    },
  );

  test('dragging a block keeps its length inside working hours', () {
    final moved = shiftBlock(
      startMin: 10 * 60,
      endMin: 11 * 60,
      deltaMin: 20,
      workStart: 9 * 60,
      workEnd: 18 * 60,
    );
    expect(moved.startMin, 10 * 60 + 15);
    expect(moved.endMin, 11 * 60 + 15);
    final clamped = shiftBlock(
      startMin: 9 * 60,
      endMin: 10 * 60,
      deltaMin: -60,
      workStart: 9 * 60,
      workEnd: 18 * 60,
    );
    expect(clamped.startMin, 9 * 60);
  });

  test('task tree nests children under their parent', () {
    PlanTask task(int id, int position, {int? parentId}) => PlanTask(
      id: id,
      title: '$id',
      status: 'todo',
      parentId: parentId,
      position: position,
    );
    final tree = taskTree([
      task(2, 0, parentId: 1),
      task(1, 1),
      task(3, 0, parentId: 99),
      task(4, 2, parentId: 1),
    ]);
    expect(tree.map((node) => node.task.id), [3, 1]);
    expect(tree[1].children.map((child) => child.id), [2, 4]);
  });

  test('marking a subtask done updates it and its parent count', () {
    PlanBlock block(List<PlanTask> tasks) => PlanBlock(
      id: 1,
      projectId: 1,
      projectName: 'Plan',
      color: const Color(0xFF6366F1),
      date: '2026-10-16',
      startMin: 9 * 60,
      endMin: 10 * 60,
      note: '',
      tasks: tasks,
    );
    final updated = plansWithTaskStatus(
      [
        block([
          const PlanTask(
            id: 1,
            title: 'parent',
            status: 'todo',
            subtaskCount: 2,
            subtaskDone: 0,
          ),
          const PlanTask(id: 2, title: 'child', status: 'todo', parentId: 1),
        ]),
      ],
      2,
      'done',
    );
    expect(updated.first.tasks[1].status, 'done');
    expect(updated.first.tasks[0].subtaskDone, 1);
    final reverted = plansWithTaskStatus(updated, 2, 'todo');
    expect(reverted.first.tasks[1].status, 'todo');
    expect(reverted.first.tasks[0].subtaskDone, 0);
  });

  test('a week starts on Monday', () {
    final days = weekDates(DateTime(2026, 10, 16));
    expect(days.first, '2026-10-12');
    expect(days.last, '2026-10-18');
    expect(weekdayIndex('2026-10-12'), 0);
    expect(weekdayIndex('2026-10-16'), 4);
    expect(weekdayIndex('2026-10-18'), 6);
  });

  test('dragging a task onto another reorders only that sibling group', () {
    final siblings = [
      const PlanTask(id: 1, title: 'a', status: 'todo', position: 0),
      const PlanTask(id: 2, title: 'b', status: 'todo', position: 1),
      const PlanTask(id: 3, title: 'c', status: 'todo', position: 2),
    ];
    expect(
      moveVisibleSibling(siblings: siblings, visible: siblings, from: 0, to: 2),
      [2, 3, 1],
    );
    expect(
      moveVisibleSibling(siblings: siblings, visible: siblings, from: 2, to: 0),
      [3, 1, 2],
    );
    final hidden = [
      ...siblings,
      const PlanTask(id: 4, title: 'hidden', status: 'done', position: 3),
    ];
    expect(
      moveVisibleSibling(siblings: hidden, visible: siblings, from: 0, to: 1),
      [2, 1, 3, 4],
    );
  });

  test('alerts fire before start and end, and skip the past', () {
    final now = DateTime(2026, 10, 16, 9, 0);
    final alerts = planAlerts(
      plans: [
        _block(
          id: 7,
          date: '2026-10-16',
          start: 10 * 60,
          end: 11 * 60,
          name: 'Design',
        ),
        _block(
          id: 8,
          date: '2026-10-16',
          start: 11 * 60,
          end: 12 * 60,
          name: 'Review',
        ),
        _block(
          id: 9,
          date: '2026-10-18',
          start: 10 * 60,
          end: 11 * 60,
          name: 'Later',
        ),
      ],
      notifyBeforeMin: 10,
      now: now,
      startTitle: (name, minutes) => '$name in $minutes',
      endTitle: (name, minutes) => '$name left $minutes',
      body: (range) => range,
      nextLine: (name, time) => 'next $name $time',
    );
    expect(alerts.map((alert) => alert.title).toList(), [
      'Design in 10',
      'Design left 10',
      'Review in 10',
      'Review left 10',
    ]);
    expect(alerts[1].body, '10:00–11:00 next Review 11:00');
    expect(alerts[0].when, DateTime(2026, 10, 16, 9, 50));
    expect(
      planAlerts(
        plans: [
          _block(
            id: 7,
            date: '2026-10-16',
            start: 10 * 60,
            end: 11 * 60,
            name: 'Design',
          ),
        ],
        notifyBeforeMin: 0,
        now: now,
        startTitle: (name, minutes) => name,
        endTitle: (name, minutes) => name,
        body: (range) => range,
        nextLine: (name, time) => time,
      ),
      isEmpty,
    );
  });
}

PlanBlock _block({
  required int id,
  required String date,
  required int start,
  required int end,
  required String name,
}) {
  return PlanBlock(
    id: id,
    projectId: 1,
    projectName: name,
    color: const Color(0xFF6366F1),
    date: date,
    startMin: start,
    endMin: end,
    note: '',
    tasks: const [],
  );
}
