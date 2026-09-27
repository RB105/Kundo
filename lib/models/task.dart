import 'dart:math';

/// Id of the built-in "Tasks" list — tasks that were never filed anywhere else.
const String kDefaultListId = 'tasks';

String newId() {
  final int stamp = DateTime.now().microsecondsSinceEpoch;
  final int salt = Random().nextInt(0xFFFF);
  return '$stamp-$salt';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

enum RepeatRule { none, daily, weekdays, weekly, monthly, yearly }

extension RepeatRuleLabel on RepeatRule {
  String get label => switch (this) {
        RepeatRule.none => 'Repeat',
        RepeatRule.daily => 'Daily',
        RepeatRule.weekdays => 'Weekdays',
        RepeatRule.weekly => 'Weekly',
        RepeatRule.monthly => 'Monthly',
        RepeatRule.yearly => 'Yearly',
      };
}

/// A single step ("subtask") inside a task.
class TaskStep {
  const TaskStep({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  final bool isDone;

  TaskStep copyWith({String? title, bool? isDone}) => TaskStep(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'title': title, 'isDone': isDone};

  factory TaskStep.fromJson(Map<dynamic, dynamic> json) => TaskStep(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
      );
}

class Task {
  const Task({
    required this.id,
    required this.listId,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.isImportant = false,
    this.myDayDate,
    this.dueDate,
    this.reminder,
    this.repeat = RepeatRule.none,
    this.note = '',
    this.steps = const <TaskStep>[],
    this.completedAt,
  });

  factory Task.create({
    required String listId,
    required String title,
    bool isImportant = false,
    bool addToMyDay = false,
    DateTime? dueDate,
  }) {
    final DateTime now = DateTime.now();
    return Task(
      id: newId(),
      listId: listId,
      title: title,
      createdAt: now,
      isImportant: isImportant,
      myDayDate: addToMyDay ? DateTime(now.year, now.month, now.day) : null,
      dueDate: dueDate,
    );
  }

  final String id;
  final String listId;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;
  final bool isImportant;

  /// The day this task was added to My Day. My Day resets every night, so a
  /// task only counts as "in My Day" while this is today.
  final DateTime? myDayDate;
  final DateTime? dueDate;
  final DateTime? reminder;
  final RepeatRule repeat;
  final String note;
  final List<TaskStep> steps;
  final DateTime? completedAt;

  bool get isInMyDay =>
      myDayDate != null && isSameDay(myDayDate!, DateTime.now());

  bool get hasNote => note.trim().isNotEmpty;

  int get doneSteps => steps.where((TaskStep s) => s.isDone).length;

  Task copyWith({
    String? listId,
    String? title,
    bool? isCompleted,
    bool? isImportant,
    DateTime? myDayDate,
    DateTime? dueDate,
    DateTime? reminder,
    RepeatRule? repeat,
    String? note,
    List<TaskStep>? steps,
    DateTime? completedAt,
    bool clearMyDay = false,
    bool clearDueDate = false,
    bool clearReminder = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      myDayDate: clearMyDay ? null : (myDayDate ?? this.myDayDate),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      repeat: repeat ?? this.repeat,
      note: note ?? this.note,
      steps: steps ?? this.steps,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'listId': listId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
        'isImportant': isImportant,
        'myDayDate': myDayDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'reminder': reminder?.toIso8601String(),
        'repeat': repeat.name,
        'note': note,
        'steps': steps.map((TaskStep s) => s.toJson()).toList(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<dynamic, dynamic> json) => Task(
        id: json['id'] as String,
        listId: json['listId'] as String? ?? kDefaultListId,
        title: json['title'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
        isImportant: json['isImportant'] as bool? ?? false,
        myDayDate: _parseDate(json['myDayDate']),
        dueDate: _parseDate(json['dueDate']),
        reminder: _parseDate(json['reminder']),
        repeat: RepeatRule.values.firstWhere(
          (RepeatRule r) => r.name == json['repeat'],
          orElse: () => RepeatRule.none,
        ),
        note: json['note'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => TaskStep.fromJson(e as Map<dynamic, dynamic>))
            .toList(),
        completedAt: _parseDate(json['completedAt']),
      );
}

/// A user-created list. The built-in "Tasks" list is not stored here.
class TaskList {
  const TaskList({
    required this.id,
    required this.title,
    required this.themeIndex,
    required this.createdAt,
    this.background,
  });

  final String id;
  final String title;
  final int themeIndex;
  final DateTime createdAt;

  /// Encoded [ListBackground] — `builtin:<style>` or `file:<name>`, null for a
  /// plain list that just uses its theme color.
  final String? background;

  TaskList copyWith({
    String? title,
    int? themeIndex,
    String? background,
    bool clearBackground = false,
  }) =>
      TaskList(
        id: id,
        title: title ?? this.title,
        themeIndex: themeIndex ?? this.themeIndex,
        createdAt: createdAt,
        background: clearBackground ? null : (background ?? this.background),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'themeIndex': themeIndex,
        'createdAt': createdAt.toIso8601String(),
        'background': background,
      };

  factory TaskList.fromJson(Map<dynamic, dynamic> json) => TaskList(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled list',
        themeIndex: json['themeIndex'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        background: json['background'] as String?,
      );
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
