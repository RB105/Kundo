import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/todo_cubit.dart';
import '../models/list_background.dart';
import '../models/task.dart';
import 'ios_ui.dart';
import 'quick_sheets.dart';

/// List actions offered both from the home screen and from inside a list.

Future<void> renameList(BuildContext context, TaskList list) async {
  final TodoCubit cubit = context.read<TodoCubit>();
  final String? name = await showTextPrompt(
    context,
    title: 'Rename List',
    initial: list.title,
    placeholder: 'List name',
    confirmLabel: 'Save',
  );
  if (name != null) cubit.updateList(list.copyWith(title: name));
}

Future<void> changeListTheme(BuildContext context, TaskList list) async {
  final TodoCubit cubit = context.read<TodoCubit>();
  final ThemeChoice? choice = await showThemeSheet(
    context,
    selectedTheme: list.themeIndex,
    selectedBackground: ListBackground.decode(list.background),
  );
  if (choice == null) return;
  if (choice.themeIndex != null) {
    cubit.updateList(list.copyWith(themeIndex: choice.themeIndex));
  }
  if (choice.background != null) {
    cubit.setListBackground(list, choice.background!);
  }
}

/// Deleting a list takes its tasks with it, so it is always confirmed.
/// Returns whether the list was deleted.
Future<bool> confirmAndDeleteList(BuildContext context, TaskList list) async {
  final TodoCubit cubit = context.read<TodoCubit>();
  final bool ok = await showConfirmDialog(
    context,
    title: 'Delete "${list.title}"?',
    message: 'This list and all of its tasks will be permanently deleted.',
    confirmLabel: 'Delete',
  );
  if (ok) cubit.deleteList(list);
  return ok;
}
