import 'package:flutter/material.dart';

import '../theme.dart';
import 'task.dart';

/// How many tasks were created and finished in one calendar month.
class MonthStats {
  const MonthStats({
    required this.month,
    required this.created,
    required this.completed,
  });

  /// First day of the month the numbers belong to.
  final DateTime month;

  /// Tasks whose `createdAt` falls in this month.
  final int created;

  /// Tasks whose `completedAt` falls in this month, whenever they were created.
  final int completed;

  /// Finished versus started in the same month. 1.0 means the month closed as
  /// many tasks as it opened.
  double get rate => created == 0 ? 0 : completed / created;
}

/// The same two numbers, split per list.
class ListStats {
  const ListStats({
    required this.listId,
    required this.title,
    required this.color,
    required this.created,
    required this.completed,
  });

  final String listId;
  final String title;
  final Color color;
  final int created;
  final int completed;

  int get activity => created + completed;

  double get rate => created == 0 ? 0 : (completed / created).clamp(0.0, 1.0);
}

class Analytics {
  const Analytics({
    required this.months,
    required this.selected,
    required this.lists,
  });

  /// Trailing window of months, oldest first.
  final List<MonthStats> months;

  /// Stats of the month the screen is showing.
  final MonthStats selected;

  /// Per-list breakdown of the selected month, busiest list first.
  final List<ListStats> lists;

  /// Tallest bar in the trend chart, never below 1 so heights stay finite.
  int get peak => months.fold<int>(
        1,
        (int max, MonthStats s) =>
            <int>[max, s.created, s.completed].reduce((int a, int b) => a > b ? a : b),
      );
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

MonthStats _statsOf(List<Task> tasks, DateTime month) {
  int created = 0;
  int completed = 0;
  for (final Task task in tasks) {
    if (_sameMonth(task.createdAt, month)) created++;
    if (task.isCompleted &&
        task.completedAt != null &&
        _sameMonth(task.completedAt!, month)) {
      completed++;
    }
  }
  return MonthStats(month: month, created: created, completed: completed);
}

/// Builds everything the stats screen shows: a [monthsBack]-month trend ending
/// with the current month, plus a per-list breakdown of [month].
Analytics buildAnalytics({
  required List<Task> tasks,
  required List<TaskList> lists,
  required DateTime month,
  int monthsBack = 6,
  DateTime? now,
}) {
  final DateTime today = now ?? DateTime.now();
  final DateTime current = DateTime(today.year, today.month);
  final DateTime selectedMonth = DateTime(month.year, month.month);

  final List<MonthStats> months = <MonthStats>[
    for (int back = monthsBack - 1; back >= 0; back--)
      _statsOf(tasks, DateTime(current.year, current.month - back)),
  ];

  final Map<String, String> titles = <String, String>{
    kDefaultListId: 'Tasks',
    for (final TaskList list in lists) list.id: list.title,
  };
  final Map<String, Color> colors = <String, Color>{
    kDefaultListId: kBlue,
    for (final TaskList list in lists)
      list.id: kListThemes[list.themeIndex % kListThemes.length],
  };

  final Map<String, int> created = <String, int>{};
  final Map<String, int> completed = <String, int>{};
  for (final Task task in tasks) {
    if (_sameMonth(task.createdAt, selectedMonth)) {
      created[task.listId] = (created[task.listId] ?? 0) + 1;
    }
    if (task.isCompleted &&
        task.completedAt != null &&
        _sameMonth(task.completedAt!, selectedMonth)) {
      completed[task.listId] = (completed[task.listId] ?? 0) + 1;
    }
  }

  final List<ListStats> perList = <ListStats>[
    for (final String id in <String>{...created.keys, ...completed.keys})
      ListStats(
        listId: id,
        // A deleted list can still own history, so fall back to a label.
        title: titles[id] ?? 'Deleted list',
        color: colors[id] ?? const Color(0xFF8A8886),
        created: created[id] ?? 0,
        completed: completed[id] ?? 0,
      ),
  ]..sort((ListStats a, ListStats b) {
      final int byActivity = b.activity.compareTo(a.activity);
      return byActivity != 0 ? byActivity : a.title.compareTo(b.title);
    });

  return Analytics(
    months: months,
    selected: _statsOf(tasks, selectedMonth),
    lists: perList,
  );
}
