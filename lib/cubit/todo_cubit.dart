import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/background_store.dart';
import '../data/todo_repository.dart';
import '../models/list_background.dart';
import '../models/task.dart';
import '../models/todo_view.dart';

class TodoState {
  const TodoState({
    required this.tasks,
    required this.lists,
    required this.loaded,
  });

  const TodoState.initial()
      : tasks = const <Task>[],
        lists = const <TaskList>[],
        loaded = false;

  final List<Task> tasks;
  final List<TaskList> lists;
  final bool loaded;

  TodoState copyWith({
    List<Task>? tasks,
    List<TaskList>? lists,
    bool? loaded,
  }) =>
      TodoState(
        tasks: tasks ?? this.tasks,
        lists: lists ?? this.lists,
        loaded: loaded ?? this.loaded,
      );
}

class TodoCubit extends Cubit<TodoState> {
  TodoCubit(this._repository) : super(const TodoState.initial());

  final TodoRepository _repository;

  void load() {
    emit(TodoState(
      tasks: _repository.loadTasks(),
      lists: _repository.loadLists(),
      loaded: true,
    ));
  }

  // ---------------------------------------------------------------- queries

  /// Tasks that belong to [view], open ones first (newest on top) and the
  /// completed ones after them, most recently completed first.
  List<Task> tasksFor(TodoView view) {
    final List<Task> matching = state.tasks.where((Task t) {
      if (view.list != null) return t.listId == view.list!.id;
      return switch (view.smart!) {
        SmartList.myDay => t.isInMyDay,
        SmartList.important => t.isImportant,
        SmartList.planned => t.dueDate != null,
        SmartList.assigned => false,
        SmartList.tasks => t.listId == kDefaultListId,
      };
    }).toList();

    matching.sort((Task a, Task b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.isCompleted) {
        final DateTime aDone = a.completedAt ?? a.createdAt;
        final DateTime bDone = b.completedAt ?? b.createdAt;
        return bDone.compareTo(aDone);
      }
      if (view.isPlanned) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return matching;
  }

  int openCount(TodoView view) =>
      tasksFor(view).where((Task t) => !t.isCompleted).length;

  Task? taskById(String id) {
    for (final Task t in state.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  TaskList? listById(String id) {
    for (final TaskList l in state.lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// What My Day offers under "Suggestions": open tasks that are not in My Day
  /// yet, due ones first.
  List<Task> suggestions() {
    final List<Task> items = state.tasks
        .where((Task t) => !t.isCompleted && !t.isInMyDay)
        .toList();
    items.sort((Task a, Task b) {
      if ((a.dueDate == null) != (b.dueDate == null)) {
        return a.dueDate == null ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  // ----------------------------------------------------------------- tasks

  void addTask(TodoView view, String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final DateTime now = DateTime.now();
    final Task task = Task.create(
      listId: view.targetListId,
      title: trimmed,
      addToMyDay: view.isMyDay,
      isImportant: view.smart == SmartList.important,
      dueDate: view.isPlanned ? DateTime(now.year, now.month, now.day) : null,
    );
    _emitTasks(<Task>[...state.tasks, task]);
  }

  void updateTask(Task task) {
    _emitTasks(state.tasks
        .map((Task t) => t.id == task.id ? task : t)
        .toList());
  }

  void toggleCompleted(Task task) {
    updateTask(task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompletedAt: task.isCompleted,
    ));
  }

  void toggleImportant(Task task) =>
      updateTask(task.copyWith(isImportant: !task.isImportant));

  void toggleMyDay(Task task) {
    final DateTime now = DateTime.now();
    updateTask(task.copyWith(
      myDayDate: task.isInMyDay ? null : DateTime(now.year, now.month, now.day),
      clearMyDay: task.isInMyDay,
    ));
  }

  void deleteTask(Task task) =>
      _emitTasks(state.tasks.where((Task t) => t.id != task.id).toList());

  // ----------------------------------------------------------------- steps

  void addStep(Task task, String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) return;
    updateTask(task.copyWith(steps: <TaskStep>[
      ...task.steps,
      TaskStep(id: newId(), title: trimmed),
    ]));
  }

  void toggleStep(Task task, TaskStep step) {
    updateTask(task.copyWith(
      steps: task.steps
          .map((TaskStep s) =>
              s.id == step.id ? s.copyWith(isDone: !s.isDone) : s)
          .toList(),
    ));
  }

  void deleteStep(Task task, TaskStep step) {
    updateTask(task.copyWith(
      steps: task.steps.where((TaskStep s) => s.id != step.id).toList(),
    ));
  }

  // ----------------------------------------------------------------- lists

  TaskList addList(String title, {int themeIndex = 0}) {
    final String trimmed = title.trim();
    final TaskList list = TaskList(
      id: newId(),
      title: trimmed.isEmpty ? 'Untitled list' : trimmed,
      themeIndex: themeIndex,
      createdAt: DateTime.now(),
    );
    _emitLists(<TaskList>[...state.lists, list]);
    return list;
  }

  void updateList(TaskList list) {
    _emitLists(state.lists
        .map((TaskList l) => l.id == list.id ? list : l)
        .toList());
  }

  /// Swaps a list's background, deleting the photo file it replaces so picked
  /// images cannot pile up in app storage.
  void setListBackground(TaskList list, ListBackground background) {
    final ListBackground current = ListBackground.decode(list.background);
    if (current.isPhoto && current.fileName != background.fileName) {
      BackgroundStore.instance.remove(current.fileName!);
    }
    final String? encoded = background.encode();
    updateList(encoded == null
        ? list.copyWith(clearBackground: true)
        : list.copyWith(background: encoded));
  }

  /// Deleting a list deletes its tasks too, as To Do does.
  void deleteList(TaskList list) {
    final ListBackground background = ListBackground.decode(list.background);
    if (background.isPhoto) {
      BackgroundStore.instance.remove(background.fileName!);
    }
    final List<TaskList> lists =
        state.lists.where((TaskList l) => l.id != list.id).toList();
    final List<Task> tasks =
        state.tasks.where((Task t) => t.listId != list.id).toList();
    _repository.saveLists(lists);
    _repository.saveTasks(tasks);
    emit(state.copyWith(lists: lists, tasks: tasks));
  }

  // --------------------------------------------------------------- private

  void _emitTasks(List<Task> tasks) {
    _repository.saveTasks(tasks);
    emit(state.copyWith(tasks: tasks));
  }

  void _emitLists(List<TaskList> lists) {
    _repository.saveLists(lists);
    emit(state.copyWith(lists: lists));
  }
}
