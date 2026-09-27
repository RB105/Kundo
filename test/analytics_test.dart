import 'package:flutter_test/flutter_test.dart';
import 'package:kundo/models/analytics.dart';
import 'package:kundo/models/task.dart';

Task _task({
  required String listId,
  required DateTime createdAt,
  DateTime? completedAt,
}) {
  return Task(
    id: newId(),
    listId: listId,
    title: 'task',
    createdAt: createdAt,
    isCompleted: completedAt != null,
    completedAt: completedAt,
  );
}

void main() {
  final DateTime now = DateTime(2026, 9, 12);
  final List<TaskList> lists = <TaskList>[
    TaskList(
      id: 'work',
      title: 'Work',
      themeIndex: 5,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  test('counts creations and completions inside the selected month', () {
    final List<Task> tasks = <Task>[
      _task(listId: kDefaultListId, createdAt: DateTime(2026, 9, 1)),
      _task(
        listId: kDefaultListId,
        createdAt: DateTime(2026, 9, 2),
        completedAt: DateTime(2026, 9, 5),
      ),
      _task(listId: 'work', createdAt: DateTime(2026, 8, 30)),
    ];

    final Analytics data = buildAnalytics(
      tasks: tasks,
      lists: lists,
      month: DateTime(2026, 9),
      now: now,
    );

    expect(data.selected.created, 2);
    expect(data.selected.completed, 1);
    expect(data.selected.rate, 0.5);
  });

  test('a task finished later counts in the month it was completed', () {
    final List<Task> tasks = <Task>[
      _task(
        listId: kDefaultListId,
        createdAt: DateTime(2026, 7, 20),
        completedAt: DateTime(2026, 9, 3),
      ),
    ];

    final Analytics data = buildAnalytics(
      tasks: tasks,
      lists: lists,
      month: DateTime(2026, 9),
      now: now,
    );

    expect(data.selected.created, 0);
    expect(data.selected.completed, 1);

    final MonthStats july = data.months.firstWhere(
      (MonthStats s) => s.month == DateTime(2026, 7),
    );
    expect(july.created, 1);
    expect(july.completed, 0);
  });

  test('the trend window ends with the current month', () {
    final Analytics data = buildAnalytics(
      tasks: <Task>[],
      lists: lists,
      month: DateTime(2026, 9),
      now: now,
    );

    expect(data.months.length, 6);
    expect(data.months.first.month, DateTime(2026, 4));
    expect(data.months.last.month, DateTime(2026, 9));
    expect(data.peak, 1);
  });

  test('per-list rows are sorted by activity and keep their list name', () {
    final List<Task> tasks = <Task>[
      _task(listId: 'work', createdAt: DateTime(2026, 9, 1)),
      _task(
        listId: 'work',
        createdAt: DateTime(2026, 9, 2),
        completedAt: DateTime(2026, 9, 4),
      ),
      _task(listId: kDefaultListId, createdAt: DateTime(2026, 9, 3)),
    ];

    final Analytics data = buildAnalytics(
      tasks: tasks,
      lists: lists,
      month: DateTime(2026, 9),
      now: now,
    );

    expect(data.lists.length, 2);
    expect(data.lists.first.title, 'Work');
    expect(data.lists.first.created, 2);
    expect(data.lists.first.completed, 1);
    expect(data.lists.last.title, 'Tasks');
  });

  test('history of a deleted list is still reported', () {
    final List<Task> tasks = <Task>[
      _task(listId: 'gone', createdAt: DateTime(2026, 9, 1)),
    ];

    final Analytics data = buildAnalytics(
      tasks: tasks,
      lists: lists,
      month: DateTime(2026, 9),
      now: now,
    );

    expect(data.lists.single.title, 'Deleted list');
  });
}
