import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/todo_cubit.dart';
import '../models/task.dart';
import '../theme.dart';
import '../widgets/ios_ui.dart';
import '../widgets/quick_sheets.dart';
import '../widgets/task_tile.dart';

/// The task detail page: title, steps, My Day, reminder, due date, repeat, note.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.accent,
    this.previousPageTitle,
  });

  final String taskId;
  final Color accent;

  /// Label of the back button: the list the task was opened from.
  final String? previousPageTitle;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _step = TextEditingController();
  final FocusNode _stepFocus = FocusNode();
  bool _primed = false;

  /// Kept so the page still has something to show while it slides away after
  /// the task was deleted.
  Task? _lastSeen;

  // Rows line their text up with the title, and separators start there too.
  static const double _gutter = 48;
  static const double _textStart = _gutter + 8;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _step.dispose();
    _stepFocus.dispose();
    super.dispose();
  }

  void _addStep(TodoCubit cubit, Task task) {
    if (_step.text.trim().isEmpty) {
      _stepFocus.unfocus();
      return;
    }
    cubit.addStep(task, _step.text);
    _step.clear();
  }

  Future<void> _delete(TodoCubit cubit, Task task) async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'Delete "${task.title}"?',
      message: 'This task will be permanently deleted.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    cubit.deleteTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return BlocBuilder<TodoCubit, TodoState>(
      builder: (BuildContext context, TodoState state) {
        final TodoCubit cubit = context.read<TodoCubit>();
        final Task? task = cubit.taskById(widget.taskId) ?? _lastSeen;
        if (task == null) return const CupertinoPageScaffold(child: SizedBox());
        _lastSeen = task;

        if (!_primed) {
          _title.text = task.title;
          _note.text = task.note;
          _primed = true;
        }

        final Color tint = tintFor(widget.accent, colors.brightness);

        return CupertinoPageScaffold(
          backgroundColor: colors.background,
          navigationBar: CupertinoNavigationBar(
            previousPageTitle: widget.previousPageTitle,
            backgroundColor: colors.bar,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: <Widget>[
                    SliverSafeArea(
                      bottom: false,
                      sliver: SliverList.list(
                        children: <Widget>[
                          const SizedBox(height: 12),
                          _titleCard(cubit, task, colors, tint),
                          _section(colors, <Widget>[
                            _myDayRow(cubit, task, colors, tint),
                          ]),
                          _section(colors, <Widget>[
                            _reminderRow(cubit, task, colors, tint),
                            _dueRow(cubit, task, colors, tint),
                            _repeatRow(cubit, task, colors, tint),
                          ]),
                          _section(colors, <Widget>[
                            _row(
                              colors: colors,
                              tint: tint,
                              icon: CupertinoIcons.paperclip,
                              label: 'Add File',
                              onTap: () => showInfoDialog(
                                context,
                                title: 'Not Available',
                                message: 'Kundo keeps everything on this '
                                    'device and does not store files yet.',
                              ),
                            ),
                          ]),
                          _noteCard(cubit, task, colors),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _bottomBar(cubit, task, colors, tint),
            ],
          ),
        );
      },
    );
  }

  Widget _titleCard(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    return _card(
      colors,
      <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: _gutter,
              child: Center(
                child: CheckCircle(
                  checked: task.isCompleted,
                  color: tint,
                  borderColor: colors.tertiaryLabel,
                  size: 26,
                  onTap: () => cubit.toggleCompleted(task),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField.borderless(
                controller: _title,
                maxLines: null,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                padding: const EdgeInsets.symmetric(vertical: 14),
                cursorColor: tint,
                style: IosText.title3.copyWith(
                  color: task.isCompleted ? colors.secondaryLabel : colors.label,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
                onChanged: (String value) =>
                    cubit.updateTask(task.copyWith(title: value)),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 48),
              onPressed: () => cubit.toggleImportant(task),
              child: Icon(
                task.isImportant ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: task.isImportant ? tint : colors.secondaryLabel,
              ),
            ),
          ],
        ),
        for (final TaskStep step in task.steps)
          Row(
            children: <Widget>[
              SizedBox(
                width: _gutter,
                child: Center(
                  child: CheckCircle(
                    checked: step.isDone,
                    color: tint,
                    borderColor: colors.tertiaryLabel,
                    size: 20,
                    onTap: () => cubit.toggleStep(task, step),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: IosText.body.copyWith(
                    color: step.isDone ? colors.secondaryLabel : colors.label,
                    decoration: step.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                // Row height matches the standard rows (kRowPadding).
                minimumSize: const Size(44, 52),
                onPressed: () => cubit.deleteStep(task, step),
                child: Icon(CupertinoIcons.xmark,
                    size: 16, color: colors.secondaryLabel),
              ),
            ],
          ),
        Row(
          children: <Widget>[
            SizedBox(
              width: _gutter,
              child: Icon(CupertinoIcons.add, size: 20, color: tint),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField.borderless(
                controller: _step,
                focusNode: _stepFocus,
                placeholder: task.steps.isEmpty ? 'Add Step' : 'Next Step',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                cursorColor: tint,
                padding: const EdgeInsets.fromLTRB(0, 15, 12, 15),
                style: IosText.body.copyWith(color: colors.label),
                // Keeps the keyboard up so steps can be typed one after another.
                onEditingComplete: () => _addStep(cubit, task),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _myDayRow(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    return _row(
      colors: colors,
      tint: tint,
      icon: CupertinoIcons.sun_max,
      label: task.isInMyDay ? 'Added to My Day' : 'Add to My Day',
      active: task.isInMyDay,
      onTap: () => cubit.toggleMyDay(task),
      onClear: task.isInMyDay ? () => cubit.toggleMyDay(task) : null,
    );
  }

  Widget _reminderRow(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    final DateTime? reminder = task.reminder;
    return _row(
      colors: colors,
      tint: tint,
      icon: CupertinoIcons.bell,
      label: reminder == null
          ? 'Remind Me'
          : 'Remind me at ${DateFormat('h:mm a').format(reminder)}',
      detail: reminder == null ? null : formatTaskDate(reminder),
      active: reminder != null,
      onTap: () async {
        final DateTime? picked = await showReminderSheet(context);
        if (picked != null) cubit.updateTask(task.copyWith(reminder: picked));
      },
      onClear: reminder == null
          ? null
          : () => cubit.updateTask(task.copyWith(clearReminder: true)),
    );
  }

  Widget _dueRow(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    return _row(
      colors: colors,
      tint: tint,
      icon: CupertinoIcons.calendar,
      label: task.dueDate == null
          ? 'Add Due Date'
          : 'Due ${formatTaskDate(task.dueDate!)}',
      active: task.dueDate != null,
      danger: task.dueDate != null &&
          isOverdue(task.dueDate!) &&
          !task.isCompleted,
      onTap: () async {
        final DateTime? picked = await showDueDateSheet(context);
        if (picked != null) cubit.updateTask(task.copyWith(dueDate: picked));
      },
      onClear: task.dueDate == null
          ? null
          : () => cubit.updateTask(task.copyWith(clearDueDate: true)),
    );
  }

  Widget _repeatRow(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    return _row(
      colors: colors,
      tint: tint,
      icon: CupertinoIcons.repeat,
      label: task.repeat.label,
      active: task.repeat != RepeatRule.none,
      onTap: () async {
        final RepeatRule? picked = await showRepeatSheet(context);
        if (picked != null) cubit.updateTask(task.copyWith(repeat: picked));
      },
      onClear: task.repeat == RepeatRule.none
          ? null
          : () => cubit.updateTask(task.copyWith(repeat: RepeatRule.none)),
    );
  }

  Widget _noteCard(TodoCubit cubit, Task task, AppColors colors) {
    return _card(colors, <Widget>[
      CupertinoTextField.borderless(
        controller: _note,
        maxLines: null,
        minLines: 4,
        placeholder: 'Add Note',
        textCapitalization: TextCapitalization.sentences,
        padding: const EdgeInsets.all(16),
        style: IosText.body.copyWith(color: colors.label),
        onChanged: (String value) =>
            cubit.updateTask(task.copyWith(note: value)),
      ),
    ]);
  }

  Widget _bottomBar(TodoCubit cubit, Task task, AppColors colors, Color tint) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(top: BorderSide(color: colors.separator, width: 0)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: <Widget>[
              // Balances the delete button so the date sits in the middle.
              const SizedBox(width: 52),
              Expanded(
                child: Text(
                  'Created ${DateFormat('EEE, MMM d').format(task.createdAt)}',
                  textAlign: TextAlign.center,
                  style: IosText.footnote.copyWith(color: colors.secondaryLabel),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(52, 44),
                onPressed: () => _delete(cubit, task),
                child: Icon(CupertinoIcons.trash, color: colors.danger),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// An inset grouped section of standard rows.
  Widget _section(AppColors colors, List<Widget> rows) {
    return CupertinoListSection.insetGrouped(
      backgroundColor: colors.background,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: rows,
    );
  }

  /// An inset card with free-form content, separated like a section.
  Widget _card(AppColors colors, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                margin: const EdgeInsets.only(left: _textStart),
                height: 0.5,
                color: colors.separator,
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _row({
    required AppColors colors,
    required Color tint,
    required IconData icon,
    required String label,
    String? detail,
    VoidCallback? onTap,
    VoidCallback? onClear,
    bool active = false,
    bool danger = false,
  }) {
    final Color color = danger
        ? colors.danger
        : active
            ? tint
            : colors.secondaryLabel;

    return CupertinoListTile(
      padding: kRowPadding,
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: TextStyle(color: active || danger ? color : colors.label),
      ),
      subtitle: detail == null ? null : Text(detail),
      trailing: onClear == null
          ? null
          : CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: onClear,
              child: Icon(CupertinoIcons.xmark_circle_fill,
                  size: 20, color: colors.tertiaryLabel),
            ),
      onTap: onTap,
    );
  }
}
