import 'package:flutter_test/flutter_test.dart';
import 'package:kundo/models/task.dart';

void main() {
  group('Task', () {
    test('a task added to My Day today counts as in My Day', () {
      final Task task = Task.create(
        listId: kDefaultListId,
        title: 'Pick up parcel',
        addToMyDay: true,
      );

      expect(task.isInMyDay, isTrue);
    });

    test('My Day resets overnight — yesterday no longer counts', () {
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final Task task = Task.create(
        listId: kDefaultListId,
        title: 'Old task',
      ).copyWith(
        myDayDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
      );

      expect(task.isInMyDay, isFalse);
    });

    test('copyWith clears the due date when asked', () {
      final Task task = Task.create(
        listId: kDefaultListId,
        title: 'Call the bank',
        dueDate: DateTime(2026, 9, 15),
      );

      expect(task.copyWith(clearDueDate: true).dueDate, isNull);
      expect(task.copyWith().dueDate, DateTime(2026, 9, 15));
    });

    test('survives a JSON round trip', () {
      final Task task = Task.create(
        listId: 'list-1',
        title: 'Prepare sprint demo',
        isImportant: true,
        dueDate: DateTime(2026, 9, 15),
      ).copyWith(
        note: 'Slides + demo build',
        repeat: RepeatRule.weekly,
        steps: <TaskStep>[
          const TaskStep(id: 's1', title: 'Write slides', isDone: true),
          const TaskStep(id: 's2', title: 'Record video'),
        ],
      );

      final Task restored = Task.fromJson(task.toJson());

      expect(restored.title, task.title);
      expect(restored.listId, 'list-1');
      expect(restored.isImportant, isTrue);
      expect(restored.dueDate, DateTime(2026, 9, 15));
      expect(restored.note, 'Slides + demo build');
      expect(restored.repeat, RepeatRule.weekly);
      expect(restored.steps.length, 2);
      expect(restored.doneSteps, 1);
    });
  });

  group('TaskList', () {
    test('survives a JSON round trip', () {
      final TaskList list = TaskList(
        id: 'l1',
        title: 'Groceries',
        themeIndex: 3,
        createdAt: DateTime(2026, 9, 12),
      );

      final TaskList restored = TaskList.fromJson(list.toJson());

      expect(restored.id, 'l1');
      expect(restored.title, 'Groceries');
      expect(restored.themeIndex, 3);
    });
  });
}
