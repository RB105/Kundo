import 'package:flutter/cupertino.dart';

import '../theme.dart';
import 'task.dart';

/// The built-in smart lists of Microsoft To Do.
enum SmartList { myDay, important, planned, assigned, tasks }

extension SmartListInfo on SmartList {
  String get title => switch (this) {
        SmartList.myDay => 'My Day',
        SmartList.important => 'Important',
        SmartList.planned => 'Planned',
        SmartList.assigned => 'Assigned to me',
        SmartList.tasks => 'Tasks',
      };

  IconData get icon => switch (this) {
        SmartList.myDay => CupertinoIcons.sun_max_fill,
        SmartList.important => CupertinoIcons.star_fill,
        SmartList.planned => CupertinoIcons.calendar,
        SmartList.assigned => CupertinoIcons.person_fill,
        SmartList.tasks => CupertinoIcons.house_fill,
      };

  Color get color => switch (this) {
        SmartList.myDay => const Color(0xFF3B3A56),
        SmartList.important => const Color(0xFFD13438),
        SmartList.planned => const Color(0xFF0F7B0F),
        SmartList.assigned => const Color(0xFF038387),
        SmartList.tasks => kBlue,
      };
}

/// Anything the task screen can show: a smart list or a user list.
class TodoView {
  const TodoView.smart(SmartList this.smart) : list = null;
  const TodoView.list(TaskList this.list) : smart = null;

  final SmartList? smart;
  final TaskList? list;

  bool get isSmart => smart != null;

  String get id => smart != null ? 'smart:${smart!.name}' : list!.id;

  String get title => smart?.title ?? list!.title;

  IconData get icon => smart?.icon ?? CupertinoIcons.list_bullet;

  Color get color =>
      smart?.color ?? kListThemes[list!.themeIndex % kListThemes.length];

  List<Color> get gradient => gradientOf(color);

  /// "Assigned to me" needs shared accounts, which a local-only app does not
  /// have, so it stays read-only here.
  bool get canAddTasks => smart != SmartList.assigned;

  /// Planned groups its tasks under date headers.
  bool get isPlanned => smart == SmartList.planned;

  bool get isMyDay => smart == SmartList.myDay;

  /// Which list a task typed into this view belongs to.
  String get targetListId => list?.id ?? kDefaultListId;
}
