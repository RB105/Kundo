import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

/// Local-only storage. One Hive box holds the tasks and the user lists as JSON,
/// so the model classes can change without a codegen step.
class TodoRepository {
  static const String _boxName = 'todo';
  static const String _tasksKey = 'tasks';
  static const String _listsKey = 'lists';
  static const String _seededKey = 'seeded';
  static const String _themeModeKey = 'themeMode';

  late final Box<dynamic> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    if (_box.get(_seededKey) != true) {
      await _seed();
      await _box.put(_seededKey, true);
    }
  }

  List<Task> loadTasks() => _decode(_tasksKey)
      .map((Map<dynamic, dynamic> e) => Task.fromJson(e))
      .toList();

  List<TaskList> loadLists() => _decode(_listsKey)
      .map((Map<dynamic, dynamic> e) => TaskList.fromJson(e))
      .toList();

  Future<void> saveTasks(List<Task> tasks) => _box.put(
        _tasksKey,
        jsonEncode(tasks.map((Task t) => t.toJson()).toList()),
      );

  Future<void> saveLists(List<TaskList> lists) => _box.put(
        _listsKey,
        jsonEncode(lists.map((TaskList l) => l.toJson()).toList()),
      );

  /// Light, dark or following the system. Unknown values fall back to system.
  ThemeMode loadThemeMode() {
    final Object? raw = _box.get(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _box.put(_themeModeKey, mode.name);

  List<Map<dynamic, dynamic>> _decode(String key) {
    final Object? raw = _box.get(key);
    if (raw is! String || raw.isEmpty) return <Map<dynamic, dynamic>>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<dynamic, dynamic>>[];
    return decoded.cast<Map<dynamic, dynamic>>();
  }

  /// First launch gets a small sample set, the way a fresh To Do account shows
  /// a few starter items. Deleting them leaves the app empty for good.
  Future<void> _seed() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final TaskList groceries = TaskList(
      id: newId(),
      title: 'Groceries',
      themeIndex: 1,
      createdAt: now,
    );
    final TaskList work = TaskList(
      id: newId(),
      title: 'Work',
      themeIndex: 5,
      createdAt: now,
    );

    final List<Task> tasks = <Task>[
      Task.create(
        listId: kDefaultListId,
        title: 'Pick up parcel',
        addToMyDay: true,
        dueDate: today,
      ),
      Task.create(
        listId: kDefaultListId,
        title: 'Call the bank about the card limit',
        isImportant: true,
      ),
      Task.create(
        listId: work.id,
        title: 'Review release notes',
        addToMyDay: true,
        dueDate: today.add(const Duration(days: 1)),
      ),
      Task.create(
        listId: work.id,
        title: 'Prepare sprint demo',
        isImportant: true,
        dueDate: today.add(const Duration(days: 3)),
      ),
      Task.create(listId: groceries.id, title: 'Milk'),
      Task.create(listId: groceries.id, title: 'Coffee beans'),
    ];

    // A few months of finished history, so the stats screen opens on a real
    // trend instead of a single bar.
    const List<List<int>> monthlyPattern = <List<int>>[
      <int>[6, 5],
      <int>[8, 5],
      <int>[5, 4],
      <int>[9, 7],
      <int>[7, 3],
    ];
    const List<String> historyTitles = <String>[
      'Pay the internet bill',
      'Send the weekly report',
      'Order drinking water',
      'Team 1:1',
      'Renew the insurance',
      'Update dependencies',
      'Buy a birthday gift',
      'Book the dentist',
      'Tidy up the backlog',
      'Plan the next sprint',
    ];
    final List<String> listIds = <String>[kDefaultListId, work.id, groceries.id];

    int index = 0;
    for (int back = 1; back <= monthlyPattern.length; back++) {
      final List<int> pattern = monthlyPattern[back - 1];
      for (int i = 0; i < pattern[0]; i++) {
        final DateTime createdAt =
            DateTime(now.year, now.month - back, 2 + i * 3, 10);
        final bool done = i < pattern[1];
        tasks.add(Task(
          id: newId(),
          listId: listIds[index % listIds.length],
          title: historyTitles[index % historyTitles.length],
          createdAt: createdAt,
          isCompleted: done,
          completedAt: done ? createdAt.add(const Duration(days: 2)) : null,
        ));
        index++;
      }
    }

    await saveLists(<TaskList>[groceries, work]);
    await saveTasks(tasks);
  }
}
